const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// RevenueCat webhook skeleton. IMPORTANT: validate webhook signatures in production.
exports.revenuecatWebhook = functions.https.onRequest(async (req, res) => {
    try {
        const event = req.body;

        // Verify signature if configured
        try {
            const cfg = functions.config();
            const secret = cfg && cfg.revenuecat && cfg.revenuecat.webhook_secret;
            const signature = req.get('x-revenuecat-signature');
            if (secret && signature) {
                const crypto = require('crypto');
                const hmac = crypto.createHmac('sha256', secret);
                hmac.update(JSON.stringify(event));
                const expected = hmac.digest('hex');
                if (signature !== expected) {
                    console.warn('Invalid RevenueCat signature');
                    return res.status(401).send('invalid signature');
                }
            } else {
                console.warn('No webhook secret configured; skipping signature check');
            }
        } catch (sigErr) {
            console.error('Signature verification error', sigErr);
        }

        // Basic sanity checks
        if (!event || !event.type) {
            return res.status(400).send('missing event');
        }

        const appUserId = event.app_user_id; // should be Firebase UID if you use that as appUserId
        if (!appUserId) {
            console.warn('RevenueCat webhook without app_user_id', event);
            return res.status(400).send('missing app_user_id');
        }

        const userRef = admin.firestore().doc(`users/${appUserId}`);

        // Example handling for common event types
        switch (event.type) {
            case 'INITIAL_PURCHASE':
            case 'RENEWAL':
            case 'RESTORE':
                await userRef.set({
                    entitlements: {
                        premium: {
                            isActive: true,
                            productId: event.product_id || null,
                            expirationDate: event.expiration_date || null,
                            isTrial: false,
                        }
                    }
                }, { merge: true });
                break;

            case 'CANCELLATION':
            case 'EXPIRATION':
                await userRef.set({
                    entitlements: { premium: { isActive: false } }
                }, { merge: true });
                break;

            default:
                console.log('Unhandled RevenueCat event type:', event.type);
        }

        return res.status(200).send('ok');
    } catch (err) {
        console.error('Error handling revenuecat webhook', err);
        return res.status(500).send('error');
    }
});
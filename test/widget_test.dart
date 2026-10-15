import 'package:flutter_test/flutter_test.dart';
import 'package:ui_quiz/models/user_model.dart';

void main() {
  test('user serialization never contains a password field', () {
    final user = UserModel(uid: 'firebase-uid', email: 'user@example.com');

    expect(user.toMap(), {'uid': 'firebase-uid', 'email': 'user@example.com'});
    expect(user.toMap().containsKey('password'), isFalse);
  });
}

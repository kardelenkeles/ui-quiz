import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static DeviceService? _instance;
  static DeviceService get instance => _instance ??= DeviceService._();

  DeviceService._();

  String? _cachedDeviceId;

  /// Kalıcı cihaz kimliğini al (app silinse bile aynı kalır)
  Future<String> getDeviceId() async {
    // Cache'den dön eğer varsa
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;

        // Android için birden fazla bilgiyi birleştirerek kalıcı ID oluştur
        final fingerprint = [
          androidInfo.brand,
          androidInfo.model,
          androidInfo.manufacturer,
          androidInfo.product,
          androidInfo.hardware,
          androidInfo.bootloader,
          androidInfo.board,
          androidInfo.host,
          // androidInfo.id app silinince değişebilir, kullanmıyoruz
        ].where((s) => s.isNotEmpty).join('|');

        // Hash oluştur (güvenlik için)
        _cachedDeviceId = _generateHash(fingerprint);
        return _cachedDeviceId!;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;

        // iOS için birden fazla bilgiyi birleştirerek kalıcı ID oluştur
        final fingerprint = [
          iosInfo.systemName,
          iosInfo.model,
          iosInfo.name,
          iosInfo.systemVersion,
          iosInfo.localizedModel,
          iosInfo.utsname.machine,
          // identifierForVendor app silinince değişir, kullanmıyoruz
        ].where((s) => s.isNotEmpty).join('|');

        _cachedDeviceId = _generateHash(fingerprint);
        return _cachedDeviceId!;
      }

      _cachedDeviceId = 'unknown_device';
      return _cachedDeviceId!;
    } catch (e) {
      print('Error getting device ID: $e');
      // Fallback: daha basit ama yine de kalıcı bilgiler
      _cachedDeviceId = _generateFallbackId();
      return _cachedDeviceId!;
    }
  }

  /// String'den güvenli hash oluştur
  String _generateHash(String input) {
    // SHA-256 hash oluştur
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);

    // İlk 16 karakteri al (yeterli benzersizlik için)
    return 'device_${digest.toString().substring(0, 16)}';
  }

  /// Fallback ID oluştur
  String _generateFallbackId() {
    // Platform bilgilerini kullan
    final platform = Platform.operatingSystem;
    final version = Platform.operatingSystemVersion;

    return _generateHash('$platform|$version|fallback');
  }

  /// Cache'i temizle (test amaçlı)
  void clearCache() {
    _cachedDeviceId = null;
  }
}

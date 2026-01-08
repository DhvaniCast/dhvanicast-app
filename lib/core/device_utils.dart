import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Device utility class for getting unique device ID and info
class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get unique device ID
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use androidId as unique identifier
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor as unique identifier
        return iosInfo.identifierForVendor ?? 'unknown-ios-device';
      } else {
        return 'unknown-platform';
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device ID: $e');
      }
      return 'error-getting-device-id';
    }
  }

  /// Get device info as string
  static Future<String> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting device info: $e');
      }
      return 'Unknown Device';
    }
  }

  /// Get platform name
  static String getPlatform() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else {
      return 'Unknown';
    }
  }
}

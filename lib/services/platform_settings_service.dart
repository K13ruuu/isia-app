import 'package:flutter/services.dart';

class PlatformSettingsService {
  static const MethodChannel _channel = MethodChannel('isia/settings');

  /// Opens the app's "App info" settings page.
  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (_) {
      // Silently fail — user can navigate manually
    }
  }

  /// Opens the app's notification settings page.
  static Future<void> openNotificationSettings() async {
    try {
      await _channel.invokeMethod('openNotificationSettings');
    } catch (_) {
      await openAppSettings();
    }
  }

  /// Opens the app's battery optimization settings.
  static Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod('openBatterySettings');
    } catch (_) {
      await openAppSettings();
    }
  }

  /// Opens the vendor-specific autostart screen (Xiaomi, OPPO, Vivo, Huawei).
  /// Falls back to the app info page if no vendor screen is available.
  static Future<void> openAutostartSettings() async {
    try {
      await _channel.invokeMethod('openAutostartSettings');
    } catch (_) {
      await openAppSettings();
    }
  }
}
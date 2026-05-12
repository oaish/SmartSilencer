import 'package:flutter/services.dart';

import '../models/geofence_zone.dart';

/// Controls Android ringer mode via a MethodChannel.
/// This service sends platform messages to native Android code.
class AudioModeService {
  static const _channel = MethodChannel('com.smartsilencer/audio');

  /// Apply silent or vibrate mode
  static Future<void> applyMode(SilenceMode mode) async {
    try {
      await _channel.invokeMethod(
        'setRingerMode',
        {'mode': mode == SilenceMode.silent ? 0 : 1},
      );
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('AudioModeService error: ${e.message}');
      if (e.code == 'DND_PERMISSION') {
        // We could notify the user here or let the caller handle it
      }
    }
  }

  /// Restore to normal (ring) mode
  static Future<void> restoreNormal() async {
    try {
      await _channel.invokeMethod('setRingerMode', {'mode': 2});
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('AudioModeService restore error: ${e.message}');
    }
  }

  /// Get current ringer mode: 0=silent, 1=vibrate, 2=normal
  static Future<int> getCurrentMode() async {
    try {
      final result = await _channel.invokeMethod<int>('getRingerMode');
      return result ?? 2;
    } on PlatformException {
      return 2;
    }
  }

  /// Check if "Do Not Disturb" access is granted
  static Future<bool> hasDnDPermission() async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>('checkDnDPermission');
      return granted ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open Android system settings for DnD access
  static Future<void> openDnDSettings() async {
    try {
      await _channel.invokeMethod('openDnDSettings');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Could not open DnD settings: ${e.message}');
    }
  }
}

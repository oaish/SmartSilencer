import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/geofence_zone.dart';

class SettingsProvider extends ChangeNotifier {
  SilenceMode _defaultMode = SilenceMode.silent;
  bool _showNotifications = true;
  bool _autoRestoreOnExit = true;
  bool _serviceEnabled = true;
  
  // New: Monitoring sensitivity settings
  int _distanceFilter = 10; // meters
  int _updateIntervalMs = 5000; // milliseconds (5s)

  SilenceMode get defaultMode => _defaultMode;
  bool get showNotifications => _showNotifications;
  bool get autoRestoreOnExit => _autoRestoreOnExit;
  bool get serviceEnabled => _serviceEnabled;
  int get distanceFilter => _distanceFilter;
  int get updateIntervalMs => _updateIntervalMs;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _defaultMode = SilenceMode.values[prefs.getInt('default_mode') ?? 0];
    _showNotifications = prefs.getBool('show_notifications') ?? true;
    _autoRestoreOnExit = prefs.getBool('auto_restore_on_exit') ?? true;
    _serviceEnabled = prefs.getBool('service_enabled') ?? true;
    _distanceFilter = prefs.getInt('distance_filter') ?? 10;
    _updateIntervalMs = prefs.getInt('update_interval_ms') ?? 5000;
    notifyListeners();
  }

  Future<void> setDefaultMode(SilenceMode mode) async {
    _defaultMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('default_mode', mode.index);
    notifyListeners();
  }

  Future<void> setShowNotifications(bool value) async {
    _showNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_notifications', value);
    notifyListeners();
  }

  Future<void> setAutoRestoreOnExit(bool value) async {
    _autoRestoreOnExit = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_restore_on_exit', value);
    notifyListeners();
  }

  Future<void> setServiceEnabled(bool value) async {
    _serviceEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('service_enabled', value);
    notifyListeners();
  }

  Future<void> setDistanceFilter(int meters) async {
    _distanceFilter = meters;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('distance_filter', meters);
    notifyListeners();
  }

  Future<void> setUpdateIntervalMs(int ms) async {
    _updateIntervalMs = ms;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('update_interval_ms', ms);
    notifyListeners();
  }
}

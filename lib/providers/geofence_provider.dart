import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/geofence_zone.dart';
import '../services/audio_mode_service.dart';
import '../services/notification_service.dart';

const _uuid = Uuid();

class GeofenceProvider extends ChangeNotifier {
  List<GeofenceZone> _zones = [];
  Position? _currentPosition;
  String? _activeZoneId;
  bool _isMonitoring = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionSubscription;

  List<GeofenceZone> get zones => List.unmodifiable(_zones);
  Position? get currentPosition => _currentPosition;
  String? get activeZoneId => _activeZoneId;
  bool get isMonitoring => _isMonitoring;
  bool get isLoading => _isLoading;
  String? get error => _error;

  GeofenceZone? get activeZone =>
      _activeZoneId != null
          ? _zones.firstWhere((z) => z.id == _activeZoneId,
              orElse: () => _zones.first)
          : null;

  Future<void> init() async {
    if (kDebugMode) print('GeofenceProvider: Initializing...');
    await _loadZones();
    // Monitoring will be started by the UI or Settings initialization
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  // ─── Persistence ──────────────────────────────────────────────────────────

  Future<void> _loadZones() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('geofence_zones') ?? [];
    _zones = raw
        .map((s) => GeofenceZone.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    if (kDebugMode) print('GeofenceProvider: Loaded ${_zones.length} zones');
    notifyListeners();
  }

  Future<void> _saveZones() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'geofence_zones',
      _zones.map((z) => jsonEncode(z.toJson())).toList(),
    );
  }

  // ─── CRUD ──────────────────────────────────────────────────────────────────

  Future<GeofenceZone> addZone({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required LocationCategory category,
    required SilenceMode silenceMode,
  }) async {
    final zone = GeofenceZone(
      id: _uuid.v4(),
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      category: category,
      silenceMode: silenceMode,
      createdAt: DateTime.now(),
    );
    _zones.add(zone);
    await _saveZones();
    notifyListeners();
    return zone;
  }

  Future<void> updateZone(GeofenceZone updated) async {
    final idx = _zones.indexWhere((z) => z.id == updated.id);
    if (idx == -1) return;
    _zones[idx] = updated;
    await _saveZones();
    notifyListeners();
  }

  Future<void> deleteZone(String id) async {
    if (kDebugMode) print('GeofenceProvider: Deleting zone $id');
    _zones.removeWhere((z) => z.id == id);
    if (_activeZoneId == id) {
      _activeZoneId = null;
      if (kDebugMode) print('GeofenceProvider: Active zone deleted, restoring normal');
      await AudioModeService.restoreNormal();
    }
    await _saveZones();
    notifyListeners();
  }

  Future<void> toggleZone(String id) async {
    final idx = _zones.indexWhere((z) => z.id == id);
    if (idx == -1) return;
    _zones[idx] = _zones[idx].copyWith(isActive: !_zones[idx].isActive);
    
    if (kDebugMode) print('GeofenceProvider: Toggled zone ${id}, isActive: ${_zones[idx].isActive}');

    if (!_zones[idx].isActive && _activeZoneId == id) {
      _activeZoneId = null;
      if (kDebugMode) print('GeofenceProvider: Active zone deactivated, restoring normal');
      await AudioModeService.restoreNormal();
    }
    
    await _saveZones();
    notifyListeners();
  }

  // ─── Monitoring ────────────────────────────────────────────────────────────

  Future<bool> requestPermissions() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> startMonitoring({int? distanceFilter, int? intervalMs}) async {
    if (kDebugMode) {
      print('GeofenceProvider: Starting monitoring (Filter: $distanceFilter m, Interval: $intervalMs ms)...');
    }
    
    final granted = await requestPermissions();
    if (!granted) {
      _error = 'Location permission denied';
      notifyListeners();
      return;
    }

    await _positionSubscription?.cancel();
    
    _isMonitoring = true;
    _error = null;
    notifyListeners();

    // Use AndroidSettings for fine-grained control over intervals
    final LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter ?? 10,
        intervalDuration: Duration(milliseconds: intervalMs ?? 5000),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Smart Silencer is monitoring your location zones.",
          notificationTitle: "Smart Silencer Active",
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter ?? 10,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) => _onPositionUpdate(position),
      onError: (e) {
        if (kDebugMode) print('GeofenceProvider: Stream error: $e');
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isMonitoring = false;
    notifyListeners();
  }

  void _onPositionUpdate(Position position) {
    _currentPosition = position;
    _checkGeofences(position);
    notifyListeners();
  }

  void _checkGeofences(Position position) {
    String? newActiveId;

    for (final zone in _zones) {
      if (!zone.isActive) continue;
      final distance = _haversineDistance(
        position.latitude,
        position.longitude,
        zone.latitude,
        zone.longitude,
      );
      if (distance <= zone.radiusMeters) {
        newActiveId = zone.id;
        break; 
      }
    }

    if (newActiveId != _activeZoneId) {
      if (kDebugMode) {
        print('GeofenceProvider: Zone change detected. Old: $_activeZoneId, New: $newActiveId');
      }
      _handleZoneChange(newActiveId);
    }
  }

  Future<void> _handleZoneChange(String? newActiveId) async {
    GeofenceZone? prevZone;
    if (_activeZoneId != null) {
      try {
        prevZone = _zones.firstWhere((z) => z.id == _activeZoneId);
      } catch (_) {}
    }

    _activeZoneId = newActiveId;

    if (newActiveId != null) {
      try {
        final zone = _zones.firstWhere((z) => z.id == newActiveId);
        if (kDebugMode) print('GeofenceProvider: ENTERING zone: ${zone.name}');
        await AudioModeService.applyMode(zone.silenceMode);
        await NotificationService.showZoneEntered(zone);
      } catch (e) {
        if (kDebugMode) print('GeofenceProvider: Error entering zone: $e');
      }
    } else if (prevZone != null) {
      if (kDebugMode) print('GeofenceProvider: EXITING zone: ${prevZone.name}');
      await AudioModeService.restoreNormal();
      await NotificationService.showZoneExited(prevZone);
    }

    notifyListeners();
  }

  Future<void> refreshAudioMode() async {
    if (_activeZoneId != null) {
      final zone = activeZone;
      if (zone != null) {
        if (kDebugMode) print('GeofenceProvider: REFRESHING audio mode for zone: ${zone.name}');
        await AudioModeService.applyMode(zone.silenceMode);
      }
    } else {
      if (kDebugMode) print('GeofenceProvider: REFRESHING to normal mode (no active zone)');
      await AudioModeService.restoreNormal();
    }
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  double? distanceTo(GeofenceZone zone) {
    if (_currentPosition == null) return null;
    return _haversineDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      zone.latitude,
      zone.longitude,
    );
  }
}

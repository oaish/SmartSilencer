import 'package:flutter/material.dart';

/// All location category types supported by Smart Silencer
enum LocationCategory {
  custom,
  hospital,
  court,
  templeOrMosque,
  college,
  library,
  cinema,
  office,
}

extension LocationCategoryExtension on LocationCategory {
  String get displayName {
    switch (this) {
      case LocationCategory.custom:
        return 'Custom Location';
      case LocationCategory.hospital:
        return 'Hospital';
      case LocationCategory.court:
        return 'Court';
      case LocationCategory.templeOrMosque:
        return 'Temple / Mosque';
      case LocationCategory.college:
        return 'College / University';
      case LocationCategory.library:
        return 'Library';
      case LocationCategory.cinema:
        return 'Cinema';
      case LocationCategory.office:
        return 'Office';
    }
  }

  IconData get icon {
    switch (this) {
      case LocationCategory.custom:
        return Icons.place_rounded;
      case LocationCategory.hospital:
        return Icons.local_hospital_rounded;
      case LocationCategory.court:
        return Icons.gavel_rounded;
      case LocationCategory.templeOrMosque:
        return Icons.temple_hindu_rounded;
      case LocationCategory.college:
        return Icons.school_rounded;
      case LocationCategory.library:
        return Icons.local_library_rounded;
      case LocationCategory.cinema:
        return Icons.movie_rounded;
      case LocationCategory.office:
        return Icons.business_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LocationCategory.custom:
        return const Color(0xFF6C63FF);
      case LocationCategory.hospital:
        return const Color(0xFFEF5350);
      case LocationCategory.court:
        return const Color(0xFF8D6E63);
      case LocationCategory.templeOrMosque:
        return const Color(0xFFFF9800);
      case LocationCategory.college:
        return const Color(0xFF29B6F6);
      case LocationCategory.library:
        return const Color(0xFF66BB6A);
      case LocationCategory.cinema:
        return const Color(0xFFAB47BC);
      case LocationCategory.office:
        return const Color(0xFF26A69A);
    }
  }

  /// Default radius in meters for this category
  double get defaultRadius {
    switch (this) {
      case LocationCategory.hospital:
        return 200;
      case LocationCategory.court:
        return 150;
      case LocationCategory.templeOrMosque:
        return 100;
      case LocationCategory.college:
        return 300;
      case LocationCategory.library:
        return 80;
      case LocationCategory.cinema:
        return 100;
      case LocationCategory.office:
        return 150;
      case LocationCategory.custom:
        return 100;
    }
  }
}

/// What action to take when entering the geofence
enum SilenceMode {
  silent,
  vibrate,
}

extension SilenceModeExtension on SilenceMode {
  String get displayName => this == SilenceMode.silent ? 'Silent' : 'Vibrate';

  IconData get icon =>
      this == SilenceMode.silent ? Icons.volume_off_rounded : Icons.vibration_rounded;

  Color get color =>
      this == SilenceMode.silent ? const Color(0xFFEF5350) : const Color(0xFF6C63FF);
}

/// A single geofence zone
class GeofenceZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final LocationCategory category;
  final SilenceMode silenceMode;
  final bool isActive;
  final DateTime createdAt;

  const GeofenceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.category,
    required this.silenceMode,
    this.isActive = true,
    required this.createdAt,
  });

  GeofenceZone copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    LocationCategory? category,
    SilenceMode? silenceMode,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return GeofenceZone(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      category: category ?? this.category,
      silenceMode: silenceMode ?? this.silenceMode,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'category': category.index,
        'silenceMode': silenceMode.index,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GeofenceZone.fromJson(Map<String, dynamic> json) => GeofenceZone(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: (json['radiusMeters'] as num).toDouble(),
        category: LocationCategory.values[json['category'] as int],
        silenceMode: SilenceMode.values[json['silenceMode'] as int],
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

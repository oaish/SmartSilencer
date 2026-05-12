import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/geofence_zone.dart';

class ActiveZoneCard extends StatelessWidget {
  final GeofenceZone zone;
  const ActiveZoneCard({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            zone.category.color.withOpacity(0.25),
            zone.category.color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: zone.category.color.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: zone.category.color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: zone.category.color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(zone.category.icon, color: zone.category.color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      '📍 ',
                      style: TextStyle(fontSize: 14),
                    ),
                    Text(
                      'You are inside',
                      style: TextStyle(
                        color: zone.category.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  zone.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ModeChip(zone: zone),
                    const SizedBox(width: 8),
                    Text(
                      '${zone.radiusMeters.toInt()} m zone',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final GeofenceZone zone;
  const _ModeChip({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: zone.silenceMode == SilenceMode.silent
            ? const LinearGradient(
                colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
              )
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: zone.silenceMode.color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(zone.silenceMode.icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            zone.silenceMode.displayName.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

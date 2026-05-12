import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/geofence_zone.dart';
import '../providers/geofence_provider.dart';

class QuickStatsRow extends StatelessWidget {
  final GeofenceProvider provider;
  const QuickStatsRow({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.zones.length;
    final active = provider.zones.where((z) => z.isActive).length;
    final silentCount =
        provider.zones.where((z) => z.silenceMode == SilenceMode.silent).length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.layers_rounded,
            value: total.toString(),
            label: 'Total Zones',
            gradient: AppTheme.primaryGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_rounded,
            value: active.toString(),
            label: 'Active',
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF00A082)],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.volume_off_rounded,
            value: silentCount.toString(),
            label: 'Silent',
            gradient: const LinearGradient(
              colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final LinearGradient gradient;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

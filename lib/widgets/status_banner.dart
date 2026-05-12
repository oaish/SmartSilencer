import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../providers/geofence_provider.dart';

class StatusBanner extends StatefulWidget {
  final GeofenceProvider provider;
  const StatusBanner({super.key, required this.provider});

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _rippleAnim;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _rippleAnim = CurvedAnimation(parent: _rippleController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInZone = widget.provider.activeZoneId != null;
    final isMonitoring = widget.provider.isMonitoring;
    final pos = widget.provider.currentPosition;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isInZone
            ? const LinearGradient(
                colors: [Color(0xFF4A42E0), Color(0xFF6C63FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  AppTheme.surfaceLight,
                  AppTheme.cardBg,
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInZone ? AppTheme.primary : AppTheme.borderColor,
          width: isInZone ? 2 : 1,
        ),
        boxShadow: isInZone
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          // Radar animation
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isMonitoring) ...[
                  AnimatedBuilder(
                    animation: _rippleAnim,
                    builder: (_, __) => CustomPaint(
                      size: const Size(60, 60),
                      painter: _RipplePainter(
                        progress: _rippleAnim.value,
                        color: isInZone ? Colors.white : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isInZone
                        ? Colors.white.withOpacity(0.2)
                        : AppTheme.primary.withOpacity(0.15),
                    border: Border.all(
                      color: isInZone ? Colors.white : AppTheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isInZone
                        ? Icons.volume_off_rounded
                        : Icons.sensors_rounded,
                    color: isInZone ? Colors.white : AppTheme.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInZone
                      ? 'Inside Geofence'
                      : isMonitoring
                          ? 'Monitoring Active'
                          : 'Service Off',
                  style: TextStyle(
                    color: isInZone ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isInZone
                      ? 'Phone mode adjusted automatically'
                      : pos != null
                          ? '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
                          : 'Waiting for GPS fix...',
                  style: TextStyle(
                    color: isInZone
                        ? Colors.white.withOpacity(0.75)
                        : AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (pos != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 12,
                        color: isInZone
                            ? Colors.white.withOpacity(0.6)
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Accuracy ±${pos.accuracy.toStringAsFixed(0)} m',
                        style: TextStyle(
                          color: isInZone
                              ? Colors.white.withOpacity(0.6)
                              : AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isInZone)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 2; i++) {
      final p = (progress + i * 0.5) % 1.0;
      final radius = 18 + p * 12;
      final opacity = (1 - p) * 0.4;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

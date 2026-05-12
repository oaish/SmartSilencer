import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/geofence_provider.dart';
import '../providers/settings_provider.dart';
import 'zones_screen.dart';
import 'add_zone_screen.dart';
import 'settings_screen.dart';
import '../models/geofence_zone.dart';
import '../widgets/status_banner.dart';
import '../widgets/active_zone_card.dart';
import '../widgets/quick_stats_row.dart';
import '../services/audio_mode_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize monitoring with saved settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = context.read<SettingsProvider>();
      if (settings.serviceEnabled) {
        context.read<GeofenceProvider>().startMonitoring(
              distanceFilter: settings.distanceFilter,
              intervalMs: settings.updateIntervalMs,
            );
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          ZonesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddZoneScreen()),
              ),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add Zone'),
              backgroundColor: AppTheme.primary,
            )
          : null,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_rounded),
            label: 'Zones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final geo = context.watch<GeofenceProvider>();
    final settings = context.watch<SettingsProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(context, settings),
            ),
            // Status banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: StatusBanner(provider: geo),
              ),
            ),
            // Active zone card
            if (geo.activeZone != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: ActiveZoneCard(zone: geo.activeZone!),
                ),
              ),
            // DnD Permission Warning
            SliverToBoxAdapter(
              child: _DnDWarningBanner(),
            ),
            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: QuickStatsRow(provider: geo),
              ),
            ),
            // Recent zones
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Text(
                  'Your Zones',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            if (geo.zones.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState(context))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final zone = geo.zones[i];
                    final dist = geo.distanceTo(zone);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: _ZoneTile(
                        zone: zone,
                        distance: dist,
                        isActive: geo.activeZoneId == zone.id,
                        onToggle: () => geo.toggleZone(zone.id),
                      ),
                    );
                  },
                  childCount: geo.zones.length,
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Silencer',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                ),
              ),
              Text(
                settings.serviceEnabled
                    ? 'Monitoring your location'
                    : 'Service paused',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const Spacer(),
          _ServiceToggle(settings: settings),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(
              Icons.add_location_alt_rounded,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No zones added yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the Zones tab and add your first\ngeofence to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ServiceToggle extends StatelessWidget {
  final SettingsProvider settings;
  const _ServiceToggle({required this.settings});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => settings.setServiceEnabled(!settings.serviceEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: settings.serviceEnabled
              ? AppTheme.primaryGradient
              : const LinearGradient(
                  colors: [AppTheme.surfaceLight, AppTheme.surfaceLight],
                ),
          border: Border.all(
            color: settings.serviceEnabled ? AppTheme.primary : AppTheme.borderColor,
            width: 2,
          ),
          boxShadow: settings.serviceEnabled
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: Icon(
          settings.serviceEnabled
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_off_rounded,
          color: settings.serviceEnabled ? Colors.white : AppTheme.textMuted,
          size: 26,
        ),
      ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  final GeofenceZone zone;
  final double? distance;
  final bool isActive;
  final VoidCallback onToggle;

  const _ZoneTile({
    required this.zone,
    required this.distance,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final distLabel = distance != null
        ? distance! < 1000
            ? '${distance!.toStringAsFixed(0)} m away'
            : '${(distance! / 1000).toStringAsFixed(1)} km away'
        : 'Locating...';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary.withOpacity(0.12) : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.primary : AppTheme.borderColor,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: zone.category.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(zone.category.icon, color: zone.category.color, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                zone.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      zone.silenceMode.icon,
                      size: 14,
                      color: zone.silenceMode.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      zone.silenceMode.displayName,
                      style: TextStyle(
                        color: zone.silenceMode.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.straighten_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${zone.radiusMeters.toInt()}m',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                distLabel,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: Switch(
          value: zone.isActive,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}
class _DnDWarningBanner extends StatefulWidget {
  @override
  State<_DnDWarningBanner> createState() => _DnDWarningBannerState();
}

class _DnDWarningBannerState extends State<_DnDWarningBanner> {
  bool _hasPermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final has = await AudioModeService.hasDnDPermission();
    if (mounted) setState(() => _hasPermission = has);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermission) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permission Required',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.error,
                              fontSize: 14,
                            ),
                      ),
                      const Text(
                        'Do Not Disturb access is needed to silence your phone.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await AudioModeService.openDnDSettings();
                  // Check again after coming back
                  await Future.delayed(const Duration(seconds: 1));
                  await _checkPermission();
                  if (_hasPermission && mounted) {
                    context.read<GeofenceProvider>().refreshAudioMode();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Grant Access', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/geofence_zone.dart';
import '../providers/settings_provider.dart';
import '../providers/geofence_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.displayMedium),
            Text(
              'Customize your experience',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),

            // App Behaviour
            _SectionHeader(title: 'Monitoring Sensitivity'),
            _SettingsCard(
              children: [
                _SliderTile(
                  title: 'Distance Filter',
                  subtitle: 'Update after moving ${settings.distanceFilter}m',
                  icon: Icons.map_rounded,
                  value: settings.distanceFilter.toDouble(),
                  min: 5,
                  max: 100,
                  onChanged: (v) => settings.setDistanceFilter(v.toInt()),
                  onChangeEnd: (v) {
                    context.read<GeofenceProvider>().startMonitoring(
                      distanceFilter: v.toInt(),
                      intervalMs: settings.updateIntervalMs,
                    );
                  },
                  iconColor: AppTheme.primary,
                ),
                const Divider(height: 1),
                _SliderTile(
                  title: 'Update Interval',
                  subtitle: 'Refresh every ${(settings.updateIntervalMs / 1000).toStringAsFixed(1)}s',
                  icon: Icons.timer_rounded,
                  value: settings.updateIntervalMs.toDouble(),
                  min: 1000,
                  max: 30000,
                  onChanged: (v) => settings.setUpdateIntervalMs(v.toInt()),
                  onChangeEnd: (v) {
                    context.read<GeofenceProvider>().startMonitoring(
                      distanceFilter: settings.distanceFilter,
                      intervalMs: v.toInt(),
                    );
                  },
                  iconColor: AppTheme.accent,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Behaviour
            _SectionHeader(title: 'App Behaviour'),
            _SettingsCard(
              children: [
                _SwitchTile(
                  title: 'Service Enabled',
                  subtitle: 'Monitor geofences in the background',
                  icon: Icons.sensors_rounded,
                  value: settings.serviceEnabled,
                  onChanged: (v) {
                    settings.setServiceEnabled(v);
                    if (v) {
                      context.read<GeofenceProvider>().startMonitoring(
                            distanceFilter: settings.distanceFilter,
                            intervalMs: settings.updateIntervalMs,
                          );
                    } else {
                      context.read<GeofenceProvider>().stopMonitoring();
                    }
                  },
                  iconColor: AppTheme.accent,
                ),
                const Divider(height: 1),
                _SwitchTile(
                  title: 'Show Notifications',
                  subtitle: 'Alert when entering/exiting zones',
                  icon: Icons.notifications_active_rounded,
                  value: settings.showNotifications,
                  onChanged: settings.setShowNotifications,
                  iconColor: AppTheme.warning,
                ),
                const Divider(height: 1),
                _SwitchTile(
                  title: 'Auto-Restore on Exit',
                  subtitle: 'Set phone back to normal when leaving zone',
                  icon: Icons.restore_rounded,
                  value: settings.autoRestoreOnExit,
                  onChanged: settings.setAutoRestoreOnExit,
                  iconColor: AppTheme.success,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Default Mode
            _SectionHeader(title: 'Default Silence Mode'),
            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Applied when no custom mode is set for a zone',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: SilenceMode.values.map((mode) {
                          final selected = settings.defaultMode == mode;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: mode == SilenceMode.silent ? 8 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () => settings.setDefaultMode(mode),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: selected
                                        ? (mode == SilenceMode.silent
                                            ? const LinearGradient(
                                                colors: [
                                                  Color(0xFFEF5350),
                                                  Color(0xFFB71C1C),
                                                ],
                                              )
                                            : AppTheme.primaryGradient)
                                        : null,
                                    color: selected ? null : AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.transparent
                                          : AppTheme.borderColor,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        mode.icon,
                                        color: selected
                                            ? Colors.white
                                            : AppTheme.textMuted,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        mode.displayName,
                                        style: TextStyle(
                                          color: selected
                                              ? Colors.white
                                              : AppTheme.textMuted,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // About
            _SectionHeader(title: 'About'),
            _SettingsCard(
              children: [
                _InfoTile(
                  icon: Icons.info_rounded,
                  title: 'Smart Silencer',
                  value: 'v1.0.0',
                  iconColor: AppTheme.primary,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.code_rounded,
                  title: 'Platform',
                  value: 'Android',
                  iconColor: AppTheme.accent,
                ),
                const Divider(height: 1),
                _InfoTile(
                  icon: Icons.policy_rounded,
                  title: 'Location Privacy',
                  value: 'On-device only',
                  iconColor: AppTheme.success,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your location data never leaves your device. '
                      'Smart Silencer is fully privacy-first.',
                      style: TextStyle(
                        color: AppTheme.accent.withOpacity(0.9),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color iconColor;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final Color iconColor;

  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              activeColor: iconColor,
              inactiveColor: iconColor.withOpacity(0.2),
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

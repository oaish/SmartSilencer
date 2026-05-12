import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/geofence_zone.dart';
import '../providers/geofence_provider.dart';

class AddZoneScreen extends StatefulWidget {
  final GeofenceZone? editZone;
  const AddZoneScreen({super.key, this.editZone});

  @override
  State<AddZoneScreen> createState() => _AddZoneScreenState();
}

class _AddZoneScreenState extends State<AddZoneScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  LocationCategory _category = LocationCategory.custom;
  SilenceMode _silenceMode = SilenceMode.silent;
  double _radius = 100;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  String? _resolvedAddress;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool get isEditing => widget.editZone != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    if (isEditing) {
      final z = widget.editZone!;
      _nameCtrl.text = z.name;
      _latCtrl.text = z.latitude.toString();
      _lngCtrl.text = z.longitude.toString();
      _category = z.category;
      _silenceMode = z.silenceMode;
      _radius = z.radiusMeters;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Zone' : 'Add Zone'),
        backgroundColor: AppTheme.surface,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildCategorySelector(),
              const SizedBox(height: 24),
              _buildNameField(),
              const SizedBox(height: 20),
              _buildLocationSection(),
              const SizedBox(height: 20),
              _buildRadiusSlider(),
              const SizedBox(height: 24),
              _buildSilenceModeSelector(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Category selector ────────────────────────────────────────────────────

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Location Type'),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: LocationCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final cat = LocationCategory.values[i];
              final selected = _category == cat;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _category = cat;
                    _radius = cat.defaultRadius;
                    if (_nameCtrl.text.isEmpty) {
                      _nameCtrl.text = cat.displayName;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  decoration: BoxDecoration(
                    color: selected
                        ? cat.color.withOpacity(0.2)
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? cat.color : AppTheme.borderColor,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(cat.icon, color: cat.color, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        cat.displayName.split('/').first.split(' ').first,
                        style: TextStyle(
                          color: selected ? cat.color : AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Name ──────────────────────────────────────────────────────────────────

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Zone Name'),
        const SizedBox(height: 10),
        TextFormField(
          controller: _nameCtrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. City Hospital, My Office...',
            prefixIcon: Icon(Icons.label_rounded, color: AppTheme.textMuted),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Enter a name' : null,
        ),
      ],
    );
  }

  // ─── Location ──────────────────────────────────────────────────────────────

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Location'),
        const SizedBox(height: 10),
        // Address search
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search address or place name...',
                  prefixIcon:
                      Icon(Icons.search_rounded, color: AppTheme.textMuted),
                ),
                onSubmitted: (_) => _searchAddress(),
              ),
            ),
            const SizedBox(width: 10),
            _IconBtn(
              icon: Icons.search_rounded,
              color: AppTheme.primary,
              onTap: _searchAddress,
              loading: false,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Current location
        OutlinedButton.icon(
          onPressed: _useCurrentLocation,
          icon: _isLoadingLocation
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.accent,
                  ),
                )
              : const Icon(Icons.my_location_rounded, size: 18),
          label: Text(_isLoadingLocation ? 'Getting location...' : 'Use Current Location'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.accent,
            side: const BorderSide(color: AppTheme.accent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Lat/Lng manual
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Latitude',
                  prefixIcon:
                      Icon(Icons.location_on_rounded, color: AppTheme.textMuted),
                ),
                onChanged: (_) => _tryReverseGeocode(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final d = double.tryParse(v);
                  if (d == null || d < -90 || d > 90) return 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _lngCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Longitude',
                  prefixIcon:
                      Icon(Icons.location_on_rounded, color: AppTheme.textMuted),
                ),
                onChanged: (_) => _tryReverseGeocode(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final d = double.tryParse(v);
                  if (d == null || d < -180 || d > 180) return 'Invalid';
                  return null;
                },
              ),
            ),
          ],
        ),
        if (_resolvedAddress != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place_rounded, size: 14, color: AppTheme.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _resolvedAddress!,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── Radius ────────────────────────────────────────────────────────────────

  Widget _buildRadiusSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('Geofence Radius'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_radius.toInt()} m',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _radius,
          min: 50,
          max: 1000,
          divisions: 38,
          onChanged: (v) => setState(() => _radius = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('50 m', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            Text('1 km', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  // ─── Silence Mode ──────────────────────────────────────────────────────────

  Widget _buildSilenceModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Mode When Inside Zone'),
        const SizedBox(height: 12),
        Row(
          children: SilenceMode.values.map((mode) {
            final selected = _silenceMode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _silenceMode = mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(
                    right: mode == SilenceMode.silent ? 8 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? (mode == SilenceMode.silent
                            ? const LinearGradient(
                                colors: [Color(0xFFEF5350), Color(0xFFB71C1C)],
                              )
                            : AppTheme.primaryGradient)
                        : null,
                    color: selected ? null : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppTheme.borderColor,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: mode.color.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        mode.icon,
                        color: selected ? Colors.white : AppTheme.textMuted,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          color: selected ? Colors.white : AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Center(
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.save_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Save Changes' : 'Create Zone',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Logic ──────────────────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        setState(() {
          _latCtrl.text = pos.latitude.toStringAsFixed(6);
          _lngCtrl.text = pos.longitude.toStringAsFixed(6);
        });
        await _tryReverseGeocode();
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _isLoadingLocation = true);
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _latCtrl.text = loc.latitude.toStringAsFixed(6);
          _lngCtrl.text = loc.longitude.toStringAsFixed(6);
        });
        await _tryReverseGeocode();
      } else {
        _showError('No results found for "$query"');
      }
    } catch (e) {
      _showError('Search failed: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _tryReverseGeocode() async {
    final lat = double.tryParse(_latCtrl.text);
    final lng = double.tryParse(_lngCtrl.text);
    if (lat == null || lng == null) return;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _resolvedAddress = [
            p.name,
            p.street,
            p.locality,
            p.administrativeArea,
            p.country,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
        });
      }
    } catch (_) {
      // Silently ignore geocoding failures
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final geo = context.read<GeofenceProvider>();
    final lat = double.parse(_latCtrl.text);
    final lng = double.parse(_lngCtrl.text);

    if (isEditing) {
      await geo.updateZone(widget.editZone!.copyWith(
        name: _nameCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
        radiusMeters: _radius,
        category: _category,
        silenceMode: _silenceMode,
      ));
    } else {
      await geo.addZone(
        name: _nameCtrl.text.trim(),
        latitude: lat,
        longitude: lng,
        radiusMeters: _radius,
        category: _category,
        silenceMode: _silenceMode,
      );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Zone updated!' : 'Zone created!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: loading
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, color: color),
      ),
    );
  }
}

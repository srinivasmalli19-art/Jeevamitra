import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/farm_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../widgets/common/jm_button.dart';
import '../../../widgets/common/jm_text_field.dart';

// ─── Page state ───────────────────────────────────────────────────────────────

class _AddLandState {
  // Step 1 — Basic info
  final String title;
  final String description;
  final String area;
  final String areaUnit;
  final String price;
  final String maxAnimals;

  // Step 2 — Location
  final double? lat;
  final double? lng;
  final String village;
  final String district;
  final String state;

  // Step 3 — Fodder & amenities
  final List<String> fodderTypes;
  final bool hasWater;
  final bool hasShade;
  final bool hasFencing;
  final bool hasVetNearby;

  // Step 4 — Photos
  final List<XFile> images;

  const _AddLandState({
    this.title = '',
    this.description = '',
    this.area = '',
    this.areaUnit = 'acre',
    this.price = '',
    this.maxAnimals = '',
    this.lat,
    this.lng,
    this.village = '',
    this.district = '',
    this.state = 'Andhra Pradesh',
    this.fodderTypes = const [],
    this.hasWater = false,
    this.hasShade = false,
    this.hasFencing = false,
    this.hasVetNearby = false,
    this.images = const [],
  });

  _AddLandState copyWith({
    String? title, String? description, String? area, String? areaUnit,
    String? price, String? maxAnimals, double? lat, double? lng,
    String? village, String? district, String? state,
    List<String>? fodderTypes, bool? hasWater, bool? hasShade,
    bool? hasFencing, bool? hasVetNearby, List<XFile>? images,
  }) => _AddLandState(
    title: title ?? this.title,
    description: description ?? this.description,
    area: area ?? this.area,
    areaUnit: areaUnit ?? this.areaUnit,
    price: price ?? this.price,
    maxAnimals: maxAnimals ?? this.maxAnimals,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    village: village ?? this.village,
    district: district ?? this.district,
    state: state ?? this.state,
    fodderTypes: fodderTypes ?? this.fodderTypes,
    hasWater: hasWater ?? this.hasWater,
    hasShade: hasShade ?? this.hasShade,
    hasFencing: hasFencing ?? this.hasFencing,
    hasVetNearby: hasVetNearby ?? this.hasVetNearby,
    images: images ?? this.images,
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AddLandScreen extends ConsumerStatefulWidget {
  final String? editFarmId;
  const AddLandScreen({super.key, this.editFarmId});

  @override
  ConsumerState<AddLandScreen> createState() => _AddLandScreenState();
}

class _AddLandScreenState extends ConsumerState<AddLandScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  _AddLandState _data = const _AddLandState();

  // Step 1 controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _maxAnimalsCtrl = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();

  // Step 2 controllers
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'Andhra Pradesh');
  final _formKey2 = GlobalKey<FormState>();

  bool _locating = false;
  bool _submitting = false;
  final _imgService = ImageUploadService();
  final _locService = LocationService();

  static const _fodderOptions = [
    ('grass', 'Grass / Pasture', '🌿'),
    ('sorghum', 'Sorghum / Jowar', '🌾'),
    ('maize', 'Maize / Corn', '🌽'),
    ('cotton', 'Cotton Stubble', '🪴'),
    ('groundnut', 'Groundnut Tops', '🥜'),
    ('paddy', 'Paddy Straw', '🌾'),
    ('sugarcane', 'Sugarcane Tops', '🎋'),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _areaCtrl.dispose();
    _priceCtrl.dispose();
    _maxAnimalsCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step == 0 && !_formKey1.currentState!.validate()) return;
    if (_step == 1 && !_formKey2.currentState!.validate()) return;
    if (_step == 1 && _data.lat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set the location of your land')),
      );
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  Future<void> _pickOnMap() async {
    final extra = _data.lat != null
        ? {'lat': _data.lat, 'lng': _data.lng}
        : null;
    final result = await context.push<Map<String, dynamic>>(
      RouteConstants.mapPicker,
      extra: extra,
    );
    if (result != null && mounted) {
      final lat = (result['lat'] as num).toDouble();
      final lng = (result['lng'] as num).toDouble();
      setState(() => _data = _data.copyWith(lat: lat, lng: lng));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            'Location set: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}')),
      );
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      final loc = await _locService.getCurrentLocation();
      setState(() {
        _data = _data.copyWith(lat: loc.lat, lng: loc.lng);
        _locating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location set: ${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}')),
        );
      }
    } catch (e) {
      setState(() => _locating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    final files = await _imgService.pickMultipleImages(maxImages: 5 - _data.images.length);
    if (files.isNotEmpty) {
      setState(() => _data = _data.copyWith(images: [..._data.images, ...files]));
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final userDoc = ref.read(currentUserDocProvider).valueOrNull;

      // Upload images
      List<String> imageUrls = [];
      if (_data.images.isNotEmpty) {
        imageUrls = await _imgService.uploadImages(
          files: _data.images,
          folder: 'farms',
          ownerId: uid,
        );
      }

      final areaSqMeters = _areaToSqMeters(_areaCtrl.text.trim(), _data.areaUnit);
      final geohash = GeoHashHelper.encode(_data.lat!, _data.lng!);

      final farm = FarmModel(
        id: '',
        ownerId: uid,
        ownerName: userDoc?.name ?? '',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        lat: _data.lat!,
        lng: _data.lng!,
        geohash: geohash,
        village: _villageCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        areaSqMeters: areaSqMeters,
        areaUnit: _data.areaUnit,
        fodderTypes: _data.fodderTypes,
        pricePerDayPerAnimal: double.tryParse(_priceCtrl.text.trim()) ?? 0,
        maxAnimals: int.tryParse(_maxAnimalsCtrl.text.trim()) ?? 0,
        hasWater: _data.hasWater,
        hasShade: _data.hasShade,
        hasFencing: _data.hasFencing,
        hasVetNearby: _data.hasVetNearby,
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
      );

      final id = await ref.read(addFarmProvider.notifier).addFarm(farm);

      if (!mounted) return;
      if (id != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Land added successfully!')),
        );
        context.go(RouteConstants.farmerLands);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.'), backgroundColor: AppColors.error),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not upload photos. Check your connection and try again, or remove photos and add the land without them for now.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double _areaToSqMeters(String value, String unit) {
    final v = double.tryParse(value) ?? 0;
    switch (unit) {
      case 'acre': return v * 4046.856;
      case 'hectare': return v * 10000;
      case 'guntha': return v * 101.17;
      default: return v;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editFarmId != null ? 'Edit Land' : 'Add Land'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: _prevStep),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepBar(current: _step),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1BasicInfo(
                  formKey: _formKey1,
                  titleCtrl: _titleCtrl,
                  descCtrl: _descCtrl,
                  areaCtrl: _areaCtrl,
                  priceCtrl: _priceCtrl,
                  maxAnimalsCtrl: _maxAnimalsCtrl,
                  areaUnit: _data.areaUnit,
                  onAreaUnitChanged: (u) => setState(() => _data = _data.copyWith(areaUnit: u)),
                ),
                _Step2Location(
                  formKey: _formKey2,
                  villageCtrl: _villageCtrl,
                  districtCtrl: _districtCtrl,
                  stateCtrl: _stateCtrl,
                  lat: _data.lat,
                  lng: _data.lng,
                  locating: _locating,
                  onDetectLocation: _detectLocation,
                  onPickOnMap: _pickOnMap,
                ),
                _Step3Fodder(
                  fodderTypes: _data.fodderTypes,
                  hasWater: _data.hasWater,
                  hasShade: _data.hasShade,
                  hasFencing: _data.hasFencing,
                  hasVetNearby: _data.hasVetNearby,
                  fodderOptions: _fodderOptions,
                  onFodderToggle: (type) {
                    final list = List<String>.from(_data.fodderTypes);
                    if (list.contains(type)) { list.remove(type); } else { list.add(type); }
                    setState(() => _data = _data.copyWith(fodderTypes: list));
                  },
                  onAmenityToggle: (key, val) => setState(() {
                    switch (key) {
                      case 'water': _data = _data.copyWith(hasWater: val);
                      case 'shade': _data = _data.copyWith(hasShade: val);
                      case 'fencing': _data = _data.copyWith(hasFencing: val);
                      case 'vet': _data = _data.copyWith(hasVetNearby: val);
                    }
                  }),
                ),
                _Step4Photos(
                  images: _data.images,
                  onPickImages: _pickImages,
                  onRemove: (i) => setState(() {
                    final list = List<XFile>.from(_data.images);
                    list.removeAt(i);
                    _data = _data.copyWith(images: list);
                  }),
                ),
              ],
            ),
          ),
          // Bottom action
          Padding(
            padding: AppSpacing.screenPadding.copyWith(top: AppSpacing.md),
            child: _step < 3
                ? JmButton(label: 'Next →', onPressed: _nextStep)
                : JmButton(
                    label: 'Submit Land',
                    onPressed: _submitting ? null : _submit,
                    isLoading: _submitting,
                    leadingIcon: Icons.check_rounded,
                  ),
          ),
          const SizedBox(height: AppSpacing.base),
        ],
      ),
    );
  }
}

// ─── Step bar ─────────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int current;
  const _StepBar({required this.current});

  static const _labels = ['Basic Info', 'Location', 'Fodder', 'Photos'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      color: AppColors.surface,
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == current;
          final done = i < current;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.success : active ? AppColors.primary : AppColors.outline,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                        : Text('${i + 1}',
                            style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: active ? Colors.white : AppColors.textDisabled,
                            )),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(_labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? AppColors.primary : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
                if (i < _labels.length - 1) ...[
                  const SizedBox(width: 4),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Basic Info ───────────────────────────────────────────────────────

class _Step1BasicInfo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl, descCtrl, areaCtrl, priceCtrl, maxAnimalsCtrl;
  final String areaUnit;
  final ValueChanged<String> onAreaUnitChanged;

  const _Step1BasicInfo({
    required this.formKey, required this.titleCtrl, required this.descCtrl,
    required this.areaCtrl, required this.priceCtrl, required this.maxAnimalsCtrl,
    required this.areaUnit, required this.onAreaUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.base),
            Text('Basic Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.base),
            JmTextField(
              label: 'Land Title',
              hint: 'e.g. Green Meadow Farm',
              controller: titleCtrl,
              validator: (v) => Validators.required(v, 'Title'),
            ),
            const SizedBox(height: AppSpacing.base),
            JmTextField(
              label: 'Description',
              hint: 'Describe your land, fodder quality, access roads...',
              controller: descCtrl,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              validator: (v) => Validators.required(v, 'Description'),
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: JmTextField(
                    label: 'Area',
                    hint: '5.0',
                    controller: areaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    validator: Validators.area,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: areaUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: const [
                      DropdownMenuItem(value: 'acre', child: Text('Acres')),
                      DropdownMenuItem(value: 'hectare', child: Text('Hectares')),
                      DropdownMenuItem(value: 'guntha', child: Text('Guntha')),
                    ],
                    onChanged: (v) { if (v != null) onAreaUnitChanged(v); },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            JmTextField(
              label: 'Price per Day per Animal (₹)',
              hint: '50',
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: Validators.price,
              prefixIcon: const Icon(Icons.currency_rupee_rounded),
            ),
            const SizedBox(height: AppSpacing.base),
            JmTextField(
              label: 'Max Animals at a Time',
              hint: '100',
              controller: maxAnimalsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: Validators.sheepCount,
              prefixIcon: const Icon(Icons.groups_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Location ─────────────────────────────────────────────────────────

class _Step2Location extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController villageCtrl, districtCtrl, stateCtrl;
  final double? lat, lng;
  final bool locating;
  final VoidCallback onDetectLocation;
  final VoidCallback onPickOnMap;

  const _Step2Location({
    required this.formKey, required this.villageCtrl,
    required this.districtCtrl, required this.stateCtrl,
    required this.lat, required this.lng,
    required this.locating, required this.onDetectLocation,
    required this.onPickOnMap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.base),
            Text('Land Location', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.base),
            // GPS detection
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: lat != null ? AppColors.primaryContainer : AppColors.surfaceVariant,
                borderRadius: AppSpacing.cardRadius,
                border: Border.all(color: lat != null ? AppColors.primary : AppColors.outline),
              ),
              child: Row(
                children: [
                  Icon(
                    lat != null ? Icons.my_location_rounded : Icons.location_searching_rounded,
                    color: lat != null ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lat != null ? 'Location Set' : 'GPS Location Required',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          lat != null
                              ? '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                              : 'Tap to detect your current location',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (locating)
                    const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    TextButton(
                      onPressed: onDetectLocation,
                      child: Text(lat != null ? 'Update' : 'Detect'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onPickOnMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(lat != null ? 'Adjust on Map' : 'Pick on Map'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            JmTextField(
              label: 'Village / Town',
              controller: villageCtrl,
              validator: Validators.village,
              prefixIcon: const Icon(Icons.location_city_rounded),
            ),
            const SizedBox(height: AppSpacing.base),
            JmTextField(
              label: 'District',
              controller: districtCtrl,
              validator: (v) => Validators.required(v, 'District'),
              prefixIcon: const Icon(Icons.map_rounded),
            ),
            const SizedBox(height: AppSpacing.base),
            JmTextField(
              label: 'State',
              controller: stateCtrl,
              validator: (v) => Validators.required(v, 'State'),
              prefixIcon: const Icon(Icons.flag_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Fodder & Amenities ───────────────────────────────────────────────

class _Step3Fodder extends StatelessWidget {
  final List<String> fodderTypes;
  final bool hasWater, hasShade, hasFencing, hasVetNearby;
  final List<(String, String, String)> fodderOptions;
  final ValueChanged<String> onFodderToggle;
  final void Function(String key, bool val) onAmenityToggle;

  const _Step3Fodder({
    required this.fodderTypes, required this.hasWater, required this.hasShade,
    required this.hasFencing, required this.hasVetNearby,
    required this.fodderOptions, required this.onFodderToggle, required this.onAmenityToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.base),
          Text('Fodder Available', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Select all fodder types available on your land',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.base),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: fodderOptions.map((opt) {
              final selected = fodderTypes.contains(opt.$1);
              return FilterChip(
                label: Text('${opt.$3} ${opt.$2}'),
                selected: selected,
                onSelected: (_) => onFodderToggle(opt.$1),
                selectedColor: AppColors.primaryContainer,
                checkmarkColor: AppColors.primary,
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Amenities', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _AmenityTile(
            icon: Icons.water_drop_rounded, label: 'Water Available',
            value: hasWater, onChanged: (v) => onAmenityToggle('water', v),
          ),
          _AmenityTile(
            icon: Icons.park_rounded, label: 'Shade / Trees',
            value: hasShade, onChanged: (v) => onAmenityToggle('shade', v),
          ),
          _AmenityTile(
            icon: Icons.fence_rounded, label: 'Fencing Available',
            value: hasFencing, onChanged: (v) => onAmenityToggle('fencing', v),
          ),
          _AmenityTile(
            icon: Icons.medical_services_rounded, label: 'Vet Nearby',
            value: hasVetNearby, onChanged: (v) => onAmenityToggle('vet', v),
          ),
        ],
      ),
    );
  }
}

class _AmenityTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AmenityTile({
    required this.icon, required this.label, required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: value ? AppColors.primary : AppColors.textSecondary),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// ─── Step 4: Photos ───────────────────────────────────────────────────────────

class _Step4Photos extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemove;

  const _Step4Photos({required this.images, required this.onPickImages, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.base),
          Text('Photos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Add up to 5 photos of your land (optional)',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.base),
          if (images.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: _XFileImage(xfile: images[i]),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
          ],
          if (images.length < 5)
            OutlinedButton.icon(
              onPressed: onPickImages,
              icon: const Icon(Icons.add_photo_alternate_rounded),
              label: Text(images.isEmpty ? 'Add Photos' : 'Add More Photos'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Cross-platform picked-image preview ──────────────────────────────────────
// Image.file() is not supported on Flutter Web. This widget reads bytes from
// the XFile (works on all platforms) and displays via Image.memory.

class _XFileImage extends StatefulWidget {
  final XFile xfile;
  const _XFileImage({required this.xfile});

  @override
  State<_XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<_XFileImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    widget.xfile.readAsBytes().then((b) {
      if (mounted) setState(() => _bytes = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return const AspectRatio(
        aspectRatio: 1,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Image.memory(_bytes!, fit: BoxFit.cover);
  }
}

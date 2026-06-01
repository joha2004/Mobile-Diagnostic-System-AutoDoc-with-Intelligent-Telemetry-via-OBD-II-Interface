import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/map/map_service.dart';

class ServiceMapScreen extends ConsumerStatefulWidget {
  const ServiceMapScreen({super.key});

  @override
  ConsumerState<ServiceMapScreen> createState() => _ServiceMapScreenState();
}

class _ServiceMapScreenState extends ConsumerState<ServiceMapScreen> with TickerProviderStateMixin {
  String _selectedCategory = 'all';
  bool _isLoading = true;
  LatLng? _currentLocation;
  List<ServiceCenter> _centers = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadRealData();
  }

  Future<void> _loadRealData() async {
    setState(() => _isLoading = true);
    
    // 1. Get real user location
    final position = await MapService.getCurrentLocation();
    
    // Fallback location if GPS fails (e.g. Windows desktop without GPS)
    double lat = position?.latitude ?? 51.1694;
    double lng = position?.longitude ?? 71.4491;
    
    _currentLocation = LatLng(lat, lng);
    
    // 2. Fetch real mechanics from OpenStreetMap Overpass API (50km radius)
    final mechanics = await MapService.getNearbyMechanics(lat, lng, radiusMeters: 50000);
    
    if (mounted) {
      setState(() {
        _centers = mechanics;
        _isLoading = false;
      });
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  List<ServiceCenter> get _filteredCenters {
    if (_selectedCategory == 'all') return _centers;
    return _centers.where((c) => c.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(localeProvider);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                  ),
                  const SizedBox(width: 8),
                  Text(t.get('map_title'), style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            
            // Category filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoryChip(
                      label: t.get('map_all'),
                      icon: Icons.apps,
                      isActive: _selectedCategory == 'all',
                      onTap: () => setState(() => _selectedCategory = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: t.get('map_diagnostics'),
                      icon: Icons.search,
                      isActive: _selectedCategory == 'diagnostics',
                      onTap: () => setState(() => _selectedCategory = 'diagnostics'),
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: t.get('map_electrician'),
                      icon: Icons.electrical_services,
                      isActive: _selectedCategory == 'electrician',
                      onTap: () => setState(() => _selectedCategory = 'electrician'),
                    ),
                    const SizedBox(width: 8),
                    _CategoryChip(
                      label: t.get('map_engine_specialist'),
                      icon: Icons.build,
                      isActive: _selectedCategory == 'engine',
                      onTap: () => setState(() => _selectedCategory = 'engine'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Expanded(
                flex: 5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text("Поиск вашего местоположения...", style: TextStyle(color: AppColors.textSecondary))
                    ],
                  ),
                ),
              )
            else ...[
              // Map (OpenStreetMap) with Stack for FAB
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation ?? const LatLng(51.1694, 71.4491),
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.autodokdor1',
                          ),
                          MarkerLayer(
                            markers: [
                              // User Location Marker
                              if (_currentLocation != null)
                                Marker(
                                  point: _currentLocation!,
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.blueAccent,
                                    size: 30,
                                  ),
                                ),
                              // Mechanics Markers
                              ..._filteredCenters.map((center) => Marker(
                                point: LatLng(center.lat, center.lng),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _animatedMapMove(LatLng(center.lat, center.lng), 16.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _categoryColor(center.category),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _categoryColor(center.category).withAlpha(100),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _categoryIcon(center.category),
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ],
                      ),
                      // My Location FAB
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          heroTag: 'my_location_fab',
                          backgroundColor: AppColors.surface,
                          child: const Icon(Icons.my_location, color: AppColors.primary),
                          onPressed: () {
                            if (_currentLocation != null) {
                              _animatedMapMove(_currentLocation!, 13.0);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Service list
              Expanded(
                flex: 2,
                child: _filteredCenters.isEmpty
                    ? Center(
                        child: Text("Поблизости ничего не найдено", style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredCenters.length,
                        itemBuilder: (context, index) {
                          final center = _filteredCenters[index];
                          return InkWell(
                            onTap: () => _animatedMapMove(LatLng(center.lat, center.lng), 16.0),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _categoryColor(center.category).withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _categoryIcon(center.category),
                                      color: _categoryColor(center.category),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          center.name, 
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, size: 14, color: AppColors.warning),
                                            const SizedBox(width: 3),
                                            Text('\${center.rating}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.location_on, size: 14, color: AppColors.textTertiary),
                                            const SizedBox(width: 2),
                                            Text(center.distance, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.navigation, color: AppColors.primary, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'diagnostics': return AppColors.primary;
      case 'electrician': return AppColors.warning;
      case 'engine': return AppColors.accentPurple;
      default: return AppColors.textSecondary;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'diagnostics': return Icons.search;
      case 'electrician': return Icons.electrical_services;
      case 'engine': return Icons.build;
      default: return Icons.location_on;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withAlpha(30) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AppColors.primary : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

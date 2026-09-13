import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/mapbox_service.dart';

// Brand colors
const Color _kNavyBlue = Color(0xFF0F2D52);
const Color _kSuccessColor = Color(0xFF10B981);
const Color _kBorderColor = Color(0xFFE2E8F0);
const Color _kOffWhite = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

class MapboxLocationPickerCard extends StatefulWidget {
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final Function(double lat, double lng) onLocationSelected;
  final bool isLoading;

  const MapboxLocationPickerCard({
    super.key,
    required this.latCtrl,
    required this.lngCtrl,
    required this.onLocationSelected,
    this.isLoading = false,
  });

  @override
  State<MapboxLocationPickerCard> createState() => _MapboxLocationPickerCardState();
}

class _MapboxLocationPickerCardState extends State<MapboxLocationPickerCard> {
  final MapController _mapController = MapController();
  LatLng _centerPosition = const LatLng(20.2961, 85.8245); // Default Odisha, India center
  String _currentStyle = 'streets-v12';
  bool _isLocating = false;
  bool _isMapInitialized = false;

  @override
  void initState() {
    super.initState();
    _initPositionFromControllers();
    widget.latCtrl.addListener(_onControllerChange);
    widget.lngCtrl.addListener(_onControllerChange);
    
    // Automatically fetch GPS if location is not set yet
    if (widget.latCtrl.text.isEmpty || widget.lngCtrl.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchCurrentGPS();
      });
    }
  }

  @override
  void dispose() {
    widget.latCtrl.removeListener(_onControllerChange);
    widget.lngCtrl.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    double? lat = double.tryParse(widget.latCtrl.text);
    double? lng = double.tryParse(widget.lngCtrl.text);
    if (lat != null && lng != null && (lat != _centerPosition.latitude || lng != _centerPosition.longitude)) {
      setState(() {
        _centerPosition = LatLng(lat, lng);
      });
      if (_isMapInitialized) {
        _mapController.move(_centerPosition, 16.0);
      }
    }
  }

  void _initPositionFromControllers() {
    double? lat = double.tryParse(widget.latCtrl.text);
    double? lng = double.tryParse(widget.lngCtrl.text);
    if (lat != null && lng != null) {
      _centerPosition = LatLng(lat, lng);
    }
  }

  Future<void> _fetchCurrentGPS() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS is disabled. Please turn on location services.')),
          );
          await Geolocator.openLocationSettings();
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission permanently denied. Enable in App Settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: Geolocator.openAppSettings,
                textColor: Colors.white,
              ),
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get GPS location. Please ensure location is enabled on the device/emulator.')),
          );
          setState(() => _isLocating = false);
        }
        return;
      }

      double lat = position.latitude;
      double lng = position.longitude;

      final newLatLng = LatLng(lat, lng);
      setState(() {
        _centerPosition = newLatLng;
        widget.latCtrl.text = lat.toStringAsFixed(6);
        widget.lngCtrl.text = lng.toStringAsFixed(6);
      });

      if (_isMapInitialized) {
        _mapController.move(newLatLng, 16.5);
      }

      widget.onLocationSelected(lat, lng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS fetch error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _centerPosition = latLng;
      widget.latCtrl.text = latLng.latitude.toStringAsFixed(6);
      widget.lngCtrl.text = latLng.longitude.toStringAsFixed(6);
    });
    _mapController.move(latLng, _mapController.camera.zoom);
    widget.onLocationSelected(latLng.latitude, latLng.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = widget.latCtrl.text.isNotEmpty && widget.lngCtrl.text.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _kOffWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasLocation ? _kNavyBlue : _kBorderColor,
          width: hasLocation ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kNavyBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.map_outlined, color: _kNavyBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mapbox GPS Location & Mapping',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: _kTextPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tap or move map pin to mark exact location',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Style Toggle Dropdown
                PopupMenuButton<String>(
                  icon: const Icon(Icons.layers_outlined, color: _kNavyBlue),
                  tooltip: 'Map Style',
                  onSelected: (style) {
                    setState(() => _currentStyle = style);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'streets-v12', child: Text('🗺️ Streets Map')),
                    PopupMenuItem(value: 'satellite-streets-v12', child: Text('🛰️ Satellite View')),
                    PopupMenuItem(value: 'dark-v11', child: Text('🌙 Dark Mode Map')),
                  ],
                ),
              ],
            ),
          ),

          // Interactive Mapbox View Container
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _centerPosition,
                      initialZoom: hasLocation ? 16.0 : 12.0,
                      minZoom: 4.0,
                      maxZoom: 19.0,
                      onTap: _onMapTap,
                      onMapReady: () {
                        _isMapInitialized = true;
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapboxService.getStyleTileUrl(style: _currentStyle),
                        userAgentPackageName: 'com.example.cartkaro_partner_hub',
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _centerPosition,
                            width: 60,
                            height: 60,
                            alignment: Alignment.topCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: _kNavyBlue,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _kNavyBlue.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.restaurant,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: _kNavyBlue,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating GPS Recenter Button
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'mapbox_recenter_fab',
                      backgroundColor: Colors.white,
                      foregroundColor: _kNavyBlue,
                      elevation: 4,
                      onPressed: (_isLocating || widget.isLoading) ? null : _fetchCurrentGPS,
                      child: _isLocating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _kNavyBlue),
                            )
                          : const Icon(Icons.my_location_rounded, size: 20),
                    ),
                  ),

                  // Map instruction pill
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Tap map to set pin location',
                            style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Action & Status Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (widget.isLoading || _isLocating) ? null : _fetchCurrentGPS,
                    icon: (widget.isLoading || _isLocating)
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded, size: 20, color: Colors.white),
                    label: Text(
                      (widget.isLoading || _isLocating) ? 'Detecting GPS Location...' : '📍 Track Current Location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavyBlue,
                      disabledBackgroundColor: _kNavyBlue.withValues(alpha: 0.7),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Coordinates Row
                Row(
                  children: [
                    Expanded(
                      child: _CoordField(
                        controller: widget.latCtrl,
                        label: 'Latitude',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CoordField(
                        controller: widget.lngCtrl,
                        label: 'Longitude',
                      ),
                    ),
                  ],
                ),

                if (hasLocation) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kSuccessColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kSuccessColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, color: _kSuccessColor, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '✅ Mapbox Pin Set — Address, Area & Pincode Auto-Filled',
                            style: TextStyle(
                              color: _kSuccessColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _CoordField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: _kTextSecondary),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorderColor),
        ),
      ),
    );
  }
}

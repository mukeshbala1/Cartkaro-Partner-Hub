import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/mapbox_service.dart';

// Unified Brand Colors
const Color _kNavyBlue = Color(0xFF152744);
const Color _kSuccessColor = Color(0xFF10B981);
const Color _kBorderColor = Color(0xFFE2E8F0);
const Color _kOffWhite = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

class MapboxLocationPickerCard extends StatefulWidget {
  final TextEditingController latCtrl;
  final TextEditingController lngCtrl;
  final Function(double lat, double lng) onLocationSelected;
  final Function(Map<String, String> geoDetails)? onAddressDetailsFetched;
  final String businessType; // 'restaurant', 'grocery', 'medical'
  final bool isLoading;

  const MapboxLocationPickerCard({
    super.key,
    required this.latCtrl,
    required this.lngCtrl,
    required this.onLocationSelected,
    this.onAddressDetailsFetched,
    this.businessType = 'restaurant',
    this.isLoading = false,
  });

  @override
  State<MapboxLocationPickerCard> createState() => _MapboxLocationPickerCardState();
}

class _MapboxLocationPickerCardState extends State<MapboxLocationPickerCard> {
  final MapController _mapController = MapController();
  LatLng _centerPosition = const LatLng(28.6139, 77.2090); // Default New Delhi, India
  String _currentStyle = 'streets-v12'; // 'streets-v12' or 'satellite-streets-v12'
  bool _isLocating = false;
  bool _isGeocoding = false;
  bool _isMapInitialized = false;
  String _geocodedSummary = '';

  @override
  void initState() {
    super.initState();
    _initPositionFromControllers();
    widget.latCtrl.addListener(_onControllerChange);
    widget.lngCtrl.addListener(_onControllerChange);

    // Auto-fetch GPS if coordinates are not set yet
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

  void _initPositionFromControllers() {
    double? lat = double.tryParse(widget.latCtrl.text);
    double? lng = double.tryParse(widget.lngCtrl.text);
    if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
      _centerPosition = LatLng(lat, lng);
    }
  }

  void _onControllerChange() {
    double? lat = double.tryParse(widget.latCtrl.text);
    double? lng = double.tryParse(widget.lngCtrl.text);
    if (lat != null && lng != null && (lat != _centerPosition.latitude || lng != _centerPosition.longitude)) {
      setState(() {
        _centerPosition = LatLng(lat, lng);
      });
      if (_isMapInitialized) {
        _mapController.move(_centerPosition, _mapController.camera.zoom);
      }
    }
  }

  IconData get _markerIcon {
    switch (widget.businessType.toLowerCase()) {
      case 'restaurant':
      case 'cafe':
        return Icons.restaurant;
      case 'medical':
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'grocery':
      default:
        return Icons.shopping_basket;
    }
  }

  Color get _markerColor {
    switch (widget.businessType.toLowerCase()) {
      case 'restaurant':
      case 'cafe':
        return const Color(0xFFEA580C);
      case 'medical':
      case 'pharmacy':
        return const Color(0xFF0284C7);
      case 'grocery':
      default:
        return const Color(0xFF059669);
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
            const SnackBar(content: Text('GPS is disabled. Please turn on device location services.')),
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
            const SnackBar(content: Text('Unable to detect GPS location. You can tap on the map to place the pin.')),
          );
          setState(() => _isLocating = false);
        }
        return;
      }

      if (!mounted) return;
      final newLatLng = LatLng(position.latitude, position.longitude);
      _updateLocation(newLatLng, shouldAnimate: true);
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

  Future<void> _updateLocation(LatLng newLatLng, {bool shouldAnimate = true}) async {
    if (!mounted) return;
    setState(() {
      _centerPosition = newLatLng;
      widget.latCtrl.text = newLatLng.latitude.toStringAsFixed(6);
      widget.lngCtrl.text = newLatLng.longitude.toStringAsFixed(6);
      _isGeocoding = true;
    });

    if (_isMapInitialized && shouldAnimate) {
      _mapController.move(newLatLng, 16.5);
    }

    widget.onLocationSelected(newLatLng.latitude, newLatLng.longitude);

    // Reverse geocode the new pin coordinates
    try {
      final geo = await MapboxService.reverseGeocode(newLatLng.latitude, newLatLng.longitude);
      if (!mounted) return;

      setState(() {
        _isGeocoding = false;
        _geocodedSummary = geo['address'] ?? '';
      });

      if (widget.onAddressDetailsFetched != null && geo.isNotEmpty) {
        widget.onAddressDetailsFetched!(geo);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    _updateLocation(latLng, shouldAnimate: true);
  }

  void _zoomIn() {
    if (_isMapInitialized) {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(_centerPosition, (currentZoom + 1).clamp(4.0, 19.0));
    }
  }

  void _zoomOut() {
    if (_isMapInitialized) {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(_centerPosition, (currentZoom - 1).clamp(4.0, 19.0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLocation = widget.latCtrl.text.isNotEmpty && widget.lngCtrl.text.isNotEmpty;
    final bool isSatellite = _currentStyle.contains('satellite');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasLocation ? _kNavyBlue.withValues(alpha: 0.3) : _kBorderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Map Style Switcher (Default vs Satellite)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kNavyBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: _kNavyBlue, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Mapbox GPS Location',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: _kTextPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Tap map or move pin to mark exact store',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _kTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Map View Switcher: Default vs Satellite Toggle
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Default / Streets View Button
                      InkWell(
                        onTap: () {
                          if (isSatellite) {
                            setState(() => _currentStyle = 'streets-v12');
                          }
                        },
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: !isSatellite ? _kNavyBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: !isSatellite
                                ? [BoxShadow(color: _kNavyBlue.withValues(alpha: 0.25), blurRadius: 4)]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 14,
                                color: !isSatellite ? Colors.white : _kTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: !isSatellite ? Colors.white : _kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),

                      // Satellite View Button
                      InkWell(
                        onTap: () {
                          if (!isSatellite) {
                            setState(() => _currentStyle = 'satellite-streets-v12');
                          }
                        },
                        borderRadius: BorderRadius.circular(9),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSatellite ? _kNavyBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: isSatellite
                                ? [BoxShadow(color: _kNavyBlue.withValues(alpha: 0.25), blurRadius: 4)]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.satellite_alt_outlined,
                                size: 14,
                                color: isSatellite ? Colors.white : _kTextSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Satellite',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSatellite ? Colors.white : _kTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Interactive Mapbox View Container
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 250,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _centerPosition,
                      initialZoom: hasLocation ? 16.5 : 12.0,
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
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: _markerColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _markerColor.withValues(alpha: 0.45),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(_markerIcon, color: Colors.white, size: 18),
                                  ),
                                  Container(
                                    width: 3,
                                    height: 7,
                                    color: _markerColor,
                                  ),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: _markerColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Map Hint Pill: "Tap anywhere on map to move pin"
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.touch_app_rounded, color: Color(0xFFFBBF24), size: 14),
                          SizedBox(width: 5),
                          Text(
                            'Tap map to set exact pin point',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Controls: Zoom In / Zoom Out / Recenter
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Zoom In Button
                        _buildFloatingMapButton(
                          icon: Icons.add,
                          onPressed: _zoomIn,
                          tooltip: 'Zoom In',
                        ),
                        const SizedBox(height: 6),

                        // Zoom Out Button
                        _buildFloatingMapButton(
                          icon: Icons.remove,
                          onPressed: _zoomOut,
                          tooltip: 'Zoom Out',
                        ),
                        const SizedBox(height: 6),

                        // Recenter Pin Button
                        _buildFloatingMapButton(
                          icon: Icons.my_location_rounded,
                          onPressed: (_isLocating || widget.isLoading) ? null : _fetchCurrentGPS,
                          tooltip: 'Fetch GPS Location',
                          isLoading: _isLocating,
                          color: _kNavyBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action & Location Info Strip
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                // GPS Fetch Button
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (widget.isLoading || _isLocating) ? null : _fetchCurrentGPS,
                      icon: (_isLocating || widget.isLoading)
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded, size: 20, color: Colors.white),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isLocating ? 'Detecting Precise GPS Location...' : 'Fetch Current GPS Location',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kNavyBlue,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Live Coordinates & Geocoding Feedback Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kOffWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasLocation ? _kSuccessColor.withValues(alpha: 0.35) : _kBorderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasLocation ? Icons.check_circle_rounded : Icons.info_outline,
                            color: hasLocation ? _kSuccessColor : _kTextSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasLocation
                                  ? 'Exact Pin: ${widget.latCtrl.text}, ${widget.lngCtrl.text}'
                                  : 'No location pinned yet. Tap on map or fetch GPS.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: hasLocation ? _kTextPrimary : _kTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isGeocoding) ...[
                            const SizedBox(width: 8),
                            const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(strokeWidth: 1.8, color: _kNavyBlue),
                            ),
                          ],
                        ],
                      ),
                      if (_geocodedSummary.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Auto-filled: $_geocodedSummary',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _kSuccessColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMapButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
    bool isLoading = false,
    Color? color,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _kNavyBlue),
                  )
                : Icon(icon, size: 18, color: color ?? _kTextPrimary),
          ),
        ),
      ),
    );
  }
}

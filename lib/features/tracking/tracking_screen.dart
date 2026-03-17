import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_colours.dart';
import '../../main.dart';
import '../../shared/models/vehicle.dart';
import '../../shared/models/trip.dart';
import 'tracking_provider.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  
  late TextEditingController _purposeController;
  final FocusNode _purposeFocus = FocusNode();
  String _selectedCategory = 'Business';
  List<Vehicle> _availableVehicles = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _purposeController = TextEditingController();
    _loadVehicles();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _purposeFocus.dispose();
    _mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await isar.vehicles.where().findAll();
    if (mounted) {
      setState(() {
        _availableVehicles = vehicles;
      });
    }
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _getLocation();
    }
  }

  Future<void> _getLocation() async {
    try {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.high)
        );
      if (mounted) {
        final position = pos;
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _recenterMap(_currentLocation);
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  void _recenterMap(LatLng? location) {
    if (location != null && _mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 15.5));
    }
  }

  void _handleStartTrip() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_availableVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please add a vehicle first"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Vehicle? selectedVehicle;
    if (_availableVehicles.length == 1) {
      selectedVehicle = _availableVehicles.first;
    } else {
      selectedVehicle = await showModalBottomSheet<Vehicle>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Select Vehicle", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
              const Gap(16),
              ..._availableVehicles.map((v) => ListTile(
                leading: const Icon(Icons.directions_car_rounded, color: AppColours.canadianRed),
                title: Text(v.nickname, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColours.charcoal)),
                subtitle: Text("${v.year} ${v.make} ${v.model}", style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[600])),
                onTap: () => Navigator.pop(context, v),
              )),
              const Gap(16),
            ],
          ),
        ),
      );
    }

    if (selectedVehicle != null && mounted) {
      _showStartTripOptions(selectedVehicle);
    }
  }

  void _showStartTripOptions(Vehicle vehicle) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final odoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text("Start Trip", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vehicle: ${vehicle.nickname}",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColours.canadianRed),
            ),
            const Gap(16),
            Text(
              "Optional: Enter current odometer reading for precise tracking.",
              style: GoogleFonts.inter(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[600]),
            ),
            const Gap(16),
            TextField(
              controller: odoController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: isDark ? Colors.white : AppColours.charcoal),
              decoration: InputDecoration(
                labelText: "Current Odometer (km)",
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColours.canadianRed)),
                prefixIcon: const Icon(Icons.speed_rounded, color: AppColours.canadianRed),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("CANCEL", style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.grey))),
          ElevatedButton(
            onPressed: () {
              final double? odo = double.tryParse(odoController.text);
              ref.read(tripProvider.notifier).startTrip(vehicle, startOdometer: odo);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColours.successGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("START NOW", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleStopTrip() {
    ref.read(tripProvider.notifier).stopTrackingOnly();
    _showTripSummary();
  }

  void _showTripSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _buildTripReviewSheet(setSheetState),
        ),
      ),
    ).then((_) {
      _purposeFocus.unfocus();
    });
  }

  Future<void> _saveTripToIsar() async {
    final state = ref.read(tripProvider);
    final vehicle = state.selectedVehicle;
    if (vehicle == null) return;

    final trip = Trip()
      ..date = state.startTime ?? DateTime.now()
      ..startTime = state.startTime
      ..endTime = DateTime.now()
      ..distanceKm = state.currentKm
      ..purpose = _purposeController.text.trim().isEmpty ? "" : _purposeController.text.trim()
      ..category = _selectedCategory
      ..vehicleId = vehicle.id
      ..startAddress = "GPS Tracked"
      ..endAddress = "GPS Tracked"
      ..deductionCad = state.currentKm * 0.73 // Updated rate
      ..isCraCompliant = _purposeController.text.trim().isNotEmpty
      ..latitudePoints = state.points.map((p) => p.latitude).toList()
      ..longitudePoints = state.points.map((p) => p.longitude).toList()
      ..startOdometer = state.startOdometer
      ..endOdometer = state.startOdometer != null ? (state.startOdometer! + state.currentKm) : null
      ..needsReview = _purposeController.text.trim().isEmpty;

    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });

    ref.read(tripProvider.notifier).resetTrip();
    _purposeController.clear();
    
    if (mounted) {
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Trip saved successfully!"),
          backgroundColor: AppColours.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tripState = ref.watch(tripProvider);

    ref.listen<TripState>(tripProvider, (previous, next) {
      if (next.isTracking && next.lastPosition != null) {
        final pos = next.lastPosition!;
        final newLatLng = LatLng(pos.latitude, pos.longitude);
        _currentLocation = newLatLng;

        if (previous?.lastPosition == null || 
            previous!.lastPosition!.latitude != pos.latitude ||
            previous.lastPosition!.longitude != pos.longitude) {
          _recenterMap(newLatLng);
        }
      }
    });
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "Live Tracking",
          style: GoogleFonts.poppins(color: isDark ? Colors.white : AppColours.charcoal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: BackButton(color: isDark ? Colors.white : AppColours.charcoal),
      ),
      body: Stack(
        children: [
          _currentLocation == null 
              ? Center(child: CircularProgressIndicator(color: AppColours.canadianRed))
              : GoogleMap(
                  initialCameraPosition: CameraPosition(target: _currentLocation!, zoom: 15.5),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                  polylines: tripState.points.isEmpty ? {} : {
                    Polyline(
                      polylineId: const PolylineId("live_track"),
                      points: tripState.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                      color: AppColours.canadianRed,
                      width: 5,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                    )
                  },
                ),
          
          // Floating Stats Card
          if (tripState.isTracking || tripState.currentKm > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20, right: 20,
              child: _buildTrackingOverlay(tripState),
            ),

          // Recenter Button
          Positioned(
            right: 20,
            bottom: 140,
            child: FloatingActionButton(
              heroTag: "recenter_fab",
              mini: true,
              elevation: 4,
              backgroundColor: theme.colorScheme.surface,
              onPressed: () {
                if (tripState.lastPosition != null) {
                  _recenterMap(LatLng(tripState.lastPosition!.latitude, tripState.lastPosition!.longitude));
                } else if (_currentLocation != null) {
                  _recenterMap(_currentLocation);
                } else {
                  _getLocation();
                }
              },
              child: const Icon(Icons.my_location_rounded, color: AppColours.canadianRed),
            ),
          ),
          
          // Bottom Control Panel
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: _buildControlPanel(tripState),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(TripState tripState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          if (tripState.isTracking) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ),
            Expanded(
              child: Text(
                "Tracking Active",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal),
              ),
            ),
          ] else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Ready to drive?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
                    if (_availableVehicles.length == 1)
                      Text(_availableVehicles.first.nickname, style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey)),
                  ],
                ),
              ),
            ),
          
          const Gap(8),
          
          ElevatedButton(
            onPressed: tripState.isTracking ? _handleStopTrip : _handleStartTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: tripState.isTracking ? AppColours.canadianRed : AppColours.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              elevation: 0,
            ),
            child: Text(
              tripState.isTracking ? "STOP" : "START",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingOverlay(TripState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem("DISTANCE", state.currentKm.toStringAsFixed(2), "km", Icons.straighten_rounded, Colors.blue)),
          Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.grey.shade100),
          Expanded(child: _buildStatItem("TIME", _formatDuration(state.elapsed), "", Icons.access_time_rounded, Colors.orange)),
          Container(width: 1, height: 40, color: isDark ? Colors.white10 : Colors.grey.shade100),
          Expanded(child: _buildStatItem("VALUE", "\$${(state.currentKm * 0.73).toStringAsFixed(2)}", "CAD", Icons.attach_money_rounded, AppColours.successGreen)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const Gap(4),
            Text(label, style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        const Gap(4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : AppColours.charcoal)),
            if (unit.isNotEmpty) ...[
              const Gap(2),
              Text(unit, style: GoogleFonts.inter(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    if (d.inHours > 0) {
      return "${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
    }
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildTripReviewSheet(StateSetter setSheetState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tripState = ref.read(tripProvider);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Trip Summary", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
              IconButton(
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white10 : AppColours.lightGrey),
              ),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? Colors.white10 : AppColours.lightGrey, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.directions_car_rounded, color: AppColours.canadianRed),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tripState.selectedVehicle?.nickname ?? "Unknown Vehicle", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColours.charcoal)),
                      Text("${tripState.selectedVehicle?.make} ${tripState.selectedVehicle?.model}", style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildReviewStat("DISTANCE", "${tripState.currentKm.toStringAsFixed(2)} km"),
              _buildReviewStat("DURATION", _formatDuration(tripState.elapsed)),
              _buildReviewStat("DEDUCTION", "\$${(tripState.currentKm * 0.73).toStringAsFixed(2)}"),
            ],
          ),
          const Gap(24),
          TextField(
            controller: _purposeController,
            focusNode: _purposeFocus,
            style: TextStyle(color: isDark ? Colors.white : AppColours.charcoal),
            spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
            decoration: InputDecoration(
              labelText: "Trip Purpose",
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
              hintText: "e.g. Client visit at downtown",
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColours.canadianRed)),
              prefixIcon: const Icon(Icons.edit_rounded, color: AppColours.canadianRed),
            ),
          ),
          const Gap(20),
          Text("Category", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColours.charcoal)),
          const Gap(12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Business', 'Personal', 'Medical', 'Charity'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setSheetState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppColours.canadianRed.withValues(alpha: 0.1),
                    backgroundColor: isDark ? Colors.white10 : Colors.white,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? AppColours.canadianRed : (isDark ? Colors.white70 : Colors.grey[600]),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),
          const Gap(32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(tripProvider.notifier).resetTrip();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("DISCARD"),
                ),
              ),
              const Gap(16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveTripToIsar,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColours.successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text("SAVE TRIP", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const Gap(16),
        ],
      ),
    );
  }

  Widget _buildReviewStat(String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: isDark ? Colors.white54 : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const Gap(4),
        Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColours.charcoal)),
      ],
    );
  }
}

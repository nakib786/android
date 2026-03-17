import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:isar/isar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
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

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  
  late TextEditingController _purposeController;
  final FocusNode _purposeFocus = FocusNode();
  String _selectedCategory = 'Business';
  List<Vehicle> _availableVehicles = [];

  @override
  void initState() {
    super.initState();
    _purposeController = TextEditingController();
    _loadVehicles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _purposeFocus.dispose();
    _mapController?.dispose();
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
      if (pos == null) {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(accuracy: LocationAccuracy.high)
        );
      }
      if (mounted && pos != null) {
        final position = pos; // Local non-nullable
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
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
    }
  }

  void _handleStartTrip() async {
    if (_availableVehicles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a vehicle in settings first.")),
      );
      return;
    }

    Vehicle? selectedVehicle;
    if (_availableVehicles.length == 1) {
      selectedVehicle = _availableVehicles.first;
    } else {
      selectedVehicle = await showDialog<Vehicle>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Select Vehicle"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableVehicles.length,
              itemBuilder: (context, index) {
                final v = _availableVehicles[index];
                return ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(v.nickname),
                  subtitle: Text("${v.year} ${v.make} ${v.model}"),
                  onTap: () => Navigator.pop(context, v),
                );
              },
            ),
          ),
        ),
      );
    }

    if (selectedVehicle != null && mounted) {
      _showStartTripOptions(selectedVehicle);
    }
  }

  void _showStartTripOptions(Vehicle vehicle) {
    final odoController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Start Trip - ${vehicle.nickname}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Optional: Enter current odometer reading to track precisely."),
            const SizedBox(height: 16),
            TextField(
              controller: odoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Current Odometer (km)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.speed),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              final double? odo = double.tryParse(odoController.text);
              ref.read(tripProvider.notifier).startTrip(vehicle, startOdometer: odo);
              Navigator.pop(context);
            },
            child: const Text("START NOW"),
          ),
        ],
      ),
    );
  }

  void _handleStopTrip() {
    // Only stop the tracking logic, but keep the data for the review sheet
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
      ..purpose = _purposeController.text.trim().isEmpty ? "No purpose specified" : _purposeController.text.trim()
      ..category = _selectedCategory
      ..vehicleId = vehicle.id
      ..startAddress = "GPS Tracked" // Could use geocoding here
      ..endAddress = "GPS Tracked"
      ..deductionCad = state.currentKm * 0.70 // Simplified CRA rate
      ..isCraCompliant = _purposeController.text.isNotEmpty
      ..latitudePoints = state.points.map((p) => p.latitude).toList()
      ..longitudePoints = state.points.map((p) => p.longitude).toList()
      ..startOdometer = state.startOdometer
      ..endOdometer = state.startOdometer != null ? (state.startOdometer! + state.currentKm) : null;

    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });

    ref.read(tripProvider.notifier).resetTrip();
    _purposeController.clear();
    
    if (mounted) {
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip saved successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    // Listen for position changes to follow the user during tracking
    ref.listen<TripState>(tripProvider, (previous, next) {
      if (next.isTracking && next.lastPosition != null) {
        final pos = next.lastPosition!;
        final newLatLng = LatLng(pos.latitude, pos.longitude);
        
        // Update local variable so manual recentering uses latest tracking point
        _currentLocation = newLatLng;

        // Only animate if the position has actually changed
        if (previous?.lastPosition == null || 
            previous!.lastPosition!.latitude != pos.latitude ||
            previous.lastPosition!.longitude != pos.longitude) {
          _recenterMap(newLatLng);
        }
      }
    });
    
    return Scaffold(
      appBar: AppBar(title: const Text("Live Tracking")),
      body: Stack(
        children: [
          _currentLocation == null 
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(target: _currentLocation!, zoom: 15),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false, // Disable default to use custom positioned button
                  onMapCreated: (controller) => _mapController = controller,
                ),
          
          Positioned(
            top: 20, left: 20, right: 20,
            child: _buildTrackingOverlay(tripState),
          ),

          // Custom "Center to Location" button positioned above zoom buttons
          Positioned(
            right: 12,
            bottom: 220, // Positioned in the right middle-to-down area
            child: FloatingActionButton(
              heroTag: "recenter_fab",
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () {
                if (tripState.lastPosition != null) {
                  _recenterMap(LatLng(tripState.lastPosition!.latitude, tripState.lastPosition!.longitude));
                } else if (_currentLocation != null) {
                  _recenterMap(_currentLocation);
                } else {
                  _getLocation();
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
          
          Positioned(
            bottom: 40, left: 50, right: 50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: tripState.isTracking ? _handleStopTrip : _handleStartTrip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tripState.isTracking ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: Column(
                    children: [
                      Text(
                        tripState.isTracking ? "STOP TRIP" : "START TRIP",
                        style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      if (!tripState.isTracking && _availableVehicles.length == 1)
                        Text(
                          _availableVehicles.first.nickname,
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        ),
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

  Widget _buildTrackingOverlay(TripState state) {
    if (!state.isTracking && state.currentKm == 0) return const SizedBox.shrink();
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("Distance", "${state.currentKm.toStringAsFixed(2)} km"),
            _buildStatItem("Time", _formatDuration(state.elapsed)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildTripReviewSheet(StateSetter setSheetState) {
    final tripState = ref.read(tripProvider);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Review Trip", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.directions_car, color: Colors.grey),
              const SizedBox(width: 8),
              Text(tripState.selectedVehicle?.nickname ?? "Unknown Vehicle", style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildReviewStat("Distance", "${tripState.currentKm.toStringAsFixed(2)} km"),
              _buildReviewStat("Duration", _formatDuration(tripState.elapsed)),
              _buildReviewStat("Deduction", "\$${(tripState.currentKm * 0.70).toStringAsFixed(2)}"),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _purposeController,
            focusNode: _purposeFocus,
            spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
            decoration: const InputDecoration(
              labelText: "Trip Purpose",
              hintText: "e.g. Client visit",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
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
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(tripProvider.notifier).resetTrip();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), foregroundColor: Colors.red),
                  child: const Text("DISCARD"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveTripToIsar,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.green),
                  child: const Text("SAVE TRIP", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildReviewStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}

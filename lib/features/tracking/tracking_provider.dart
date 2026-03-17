import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:isar/isar.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/notification_service.dart';
import '../../shared/models/vehicle.dart';
import '../../shared/models/trip.dart';
import '../../main.dart';

class TripState {
  final bool isTracking;
  final double currentKm;
  final Duration elapsed;
  final Position? lastPosition;
  final List<Position> points;
  final Vehicle? selectedVehicle;
  final DateTime? startTime;
  final double? startOdometer;
  final bool isAutoDetected;

  TripState({
    this.isTracking = false,
    this.currentKm = 0.0,
    this.elapsed = Duration.zero,
    this.lastPosition,
    this.points = const [],
    this.selectedVehicle,
    this.startTime,
    this.startOdometer,
    this.isAutoDetected = false,
  });

  TripState copyWith({
    bool? isTracking,
    double? currentKm,
    Duration? elapsed,
    Position? lastPosition,
    List<Position>? points,
    Vehicle? selectedVehicle,
    DateTime? startTime,
    double? startOdometer,
    bool? isAutoDetected,
  }) {
    return TripState(
      isTracking: isTracking ?? this.isTracking,
      currentKm: currentKm ?? this.currentKm,
      elapsed: elapsed ?? this.elapsed,
      lastPosition: lastPosition ?? this.lastPosition,
      points: points ?? this.points,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      startTime: startTime ?? this.startTime,
      startOdometer: startOdometer ?? this.startOdometer,
      isAutoDetected: isAutoDetected ?? this.isAutoDetected,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  TripNotifier() : super(TripState()) {
    _initAutoDetection();
  }

  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Position>? _autoDetectSubscription;
  final Stopwatch _stopwatch = Stopwatch();
  
  // Auto-detection variables
  DateTime? _lowSpeedStartTime;
  static const double _startSpeedThreshold = 10.0 / 3.6; // 10 km/h in m/s
  static const double _stopSpeedThreshold = 3.0 / 3.6;  // 3 km/h in m/s
  static const int _stopDurationMinutes = 3;

  void _initAutoDetection() {
    _autoDetectSubscription = GpsService.getPositionStream().listen((position) {
      if (state.isTracking) {
        _handleTrackingAutoStop(position);
      } else {
        _handleAutoStart(position);
      }
    });
  }

  void _handleAutoStart(Position position) async {
    // Speed is in m/s
    if (position.speed >= _startSpeedThreshold) {
      final vehicles = await isar.vehicles.where().findAll();
      if (vehicles.isNotEmpty) {
        final defaultVehicle = vehicles.firstWhere((v) => v.isDefault, orElse: () => vehicles.first);
        startTrip(defaultVehicle, isAuto: true);
        NotificationService.showNotification(
          id: 101,
          title: "Trip Started Automatically",
          body: "Driving detected at ${ (position.speed * 3.6).toStringAsFixed(1) } km/h",
        );
      }
    }
  }

  void _handleTrackingAutoStop(Position position) {
    if (position.speed < _stopSpeedThreshold) {
      if (_lowSpeedStartTime == null) {
        _lowSpeedStartTime = DateTime.now();
      } else {
        final duration = DateTime.now().difference(_lowSpeedStartTime!);
        if (duration.inMinutes >= _stopDurationMinutes) {
          stopAndSaveTrip(isAuto: true);
          _lowSpeedStartTime = null;
        }
      }
    } else {
      _lowSpeedStartTime = null;
    }
  }

  void startTrip(Vehicle vehicle, {double? startOdometer, bool isAuto = false}) {
    if (state.isTracking) return;

    _stopwatch.reset();
    _stopwatch.start();
    state = state.copyWith(
      isTracking: true, 
      currentKm: 0.0, 
      elapsed: Duration.zero, 
      lastPosition: null,
      points: [],
      selectedVehicle: vehicle,
      startTime: DateTime.now(),
      startOdometer: startOdometer,
      isAutoDetected: isAuto,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        state = state.copyWith(elapsed: _stopwatch.elapsed);
        _updateNotification();
      }
    });

    _positionSubscription = GpsService.getPositionStream().listen((position) {
      if (!mounted) return;
      
      double distance = 0.0;
      if (state.lastPosition != null) {
        distance = Geolocator.distanceBetween(
          state.lastPosition!.latitude,
          state.lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
      }
      
      final updatedPoints = List<Position>.from(state.points)..add(position);
      
      state = state.copyWith(
        currentKm: state.currentKm + (distance / 1000),
        lastPosition: position,
        points: updatedPoints,
      );
    });
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return "${place.street}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      print(e);
    }
    return "Unknown Address";
  }

  Future<void> stopAndSaveTrip({bool isAuto = false}) async {
    if (!state.isTracking) return;

    String startAddress = "Auto-detected Start";
    String endAddress = "Auto-detected End";

    if (state.points.isNotEmpty) {
      startAddress = await _getAddressFromLatLng(state.points.first.latitude, state.points.first.longitude);
      endAddress = await _getAddressFromLatLng(state.points.last.latitude, state.points.last.longitude);
    }

    final trip = Trip()
      ..date = DateTime.now()
      ..startTime = state.startTime
      ..endTime = DateTime.now()
      ..distanceKm = state.currentKm
      ..vehicleId = state.selectedVehicle?.id ?? 0
      ..startOdometer = state.startOdometer
      ..startAddress = startAddress
      ..endAddress = endAddress
      ..purpose = "Unclassified"
      ..category = "Personal"
      ..deductionCad = 0.0
      ..isCraCompliant = false
      ..isAutoDetected = state.isAutoDetected || isAuto
      ..needsReview = state.isAutoDetected || isAuto
      ..latitudePoints = state.points.map((p) => p.latitude).toList()
      ..longitudePoints = state.points.map((p) => p.longitude).toList();

    await isar.writeTxn(() async {
      await isar.trips.put(trip);
    });

    if (isAuto) {
      NotificationService.showNotification(
        id: 102,
        title: "Trip Ended Automatically",
        body: "Trip of ${state.currentKm.toStringAsFixed(1)} km saved for review.",
      );
    }

    stopTrackingOnly();
    resetTrip();
  }

  void stopTrackingOnly() {
    _stopwatch.stop();
    _timer?.cancel();
    _positionSubscription?.cancel();
    state = state.copyWith(isTracking: false);
    NotificationService.cancelNotification(100);
  }

  void resetTrip() {
    state = TripState();
  }

  void _updateNotification() {
    NotificationService.showNotification(
      id: 100,
      title: "Trip in Progress",
      body: "${state.currentKm.toStringAsFixed(1)} km · ${_formatDuration(state.elapsed)}",
      ongoing: true,
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _autoDetectSubscription?.cancel();
    super.dispose();
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier();
});

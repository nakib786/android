import 'package:isar/isar.dart';

part 'trip.g.dart';

@collection
class Trip {
  Id id = Isar.autoIncrement;

  late DateTime date;
  late String startAddress;
  late String endAddress;
  late String purpose;
  late double distanceKm;
  late String category; // Business, Medical, Moving, Charity, Personal
  late int vehicleId;
  String? notes;
  late double deductionCad;
  late bool isCraCompliant;
  
  // Track location points for polyline
  List<double>? latitudePoints;
  List<double>? longitudePoints;

  DateTime? startTime;
  DateTime? endTime;

  // Odometer readings
  double? startOdometer;
  double? endOdometer;

  // For automatic detection
  bool needsReview = false;
  bool isAutoDetected = false;
}

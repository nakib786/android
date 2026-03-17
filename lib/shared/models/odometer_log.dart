import 'package:isar/isar.dart';

part 'odometer_log.g.dart';

@collection
class OdometerLog {
  Id id = Isar.autoIncrement;

  late int vehicleId;
  late DateTime date;
  late double reading;
}

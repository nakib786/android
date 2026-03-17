import 'package:isar/isar.dart';

part 'vehicle.g.dart';

@collection
class Vehicle {
  Id id = Isar.autoIncrement;

  late String nickname;
  late String make;
  late String model;
  late int year;
  late String licensePlate;
  late String province;
  late int colorHex;
  late String iconType; // car, truck, van, suv, motorcycle
  late bool isDefault;
}

import 'package:intl/intl.dart';

class KmFormatter {
  static final _numberFormat = NumberFormat("#,##0.0", "en_CA");

  static String format(double km) {
    return "${_numberFormat.format(km)} km";
  }
}

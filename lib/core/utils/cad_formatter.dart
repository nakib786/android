import 'package:intl/intl.dart';

class CadFormatter {
  static final _currencyFormat = NumberFormat.currency(
    symbol: "\$",
    decimalDigits: 2,
    locale: "en_CA",
  );

  static String format(double amount) {
    return _currencyFormat.format(amount);
  }
}

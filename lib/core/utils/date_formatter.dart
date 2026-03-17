import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFull(DateTime date) {
    return DateFormat("EEEE, MMMM d, y", "en_CA").format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat("MMM d, y", "en_CA").format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat("h:mm a").format(time);
  }

  static String formatIso(DateTime date) {
    return DateFormat("yyyy-MM-dd").format(date);
  }
}

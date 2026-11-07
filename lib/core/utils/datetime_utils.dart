import 'package:cloud_firestore/cloud_firestore.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static DateTime toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  static Timestamp toTimestamp(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }

  static String formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    return '$month ${dt.day}, ${dt.year}';
  }

  static String formatDateTime(DateTime dt) {
    final date = formatDate(dt);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$date at $hour:$minute';
  }
}


import 'package:cloud_firestore/cloud_firestore.dart';

/// Calendar date from the date picker (local). Send this to Cloud Functions so
/// the server never misreads timezone offsets as a different day.
String visitAppointmentCalendarKey(DateTime pickedLocal) {
  return '${pickedLocal.year.toString().padLeft(4, '0')}-'
      '${pickedLocal.month.toString().padLeft(2, '0')}-'
      '${pickedLocal.day.toString().padLeft(2, '0')}';
}

/// Noon UTC on the picked calendar date. Storing **midnight UTC** for Y-M-D makes
/// the same instant show as the **previous** evening in US timezones; noon UTC
/// keeps the usual US local calendar day aligned with the picker.
DateTime visitAppointmentAtNoonUtc(DateTime pickedLocal) {
  return DateTime.utc(
    pickedLocal.year,
    pickedLocal.month,
    pickedLocal.day,
    12,
  );
}

Timestamp visitAppointmentFirestoreTimestamp(DateTime pickedLocal) {
  return Timestamp.fromDate(visitAppointmentAtNoonUtc(pickedLocal));
}

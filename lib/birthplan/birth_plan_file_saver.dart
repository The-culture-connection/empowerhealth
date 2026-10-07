// Saves a generated birth plan PDF in a platform-appropriate way.
//
// Web builds trigger a browser download (Blob + <a download>); mobile/desktop
// builds write a temp file and open the system share sheet so the person can
// save it to Files, print it, or send it on. The web implementation is behind
// a conditional import so mobile builds never pull in browser libraries.

import 'dart:typed_data';

import 'birth_plan_file_saver_io.dart'
    if (dart.library.js_interop) 'birth_plan_file_saver_web.dart' as impl;

/// Saves [bytes] as [fileName]. Returns normally on success, throws on failure.
Future<void> saveBirthPlanPdf(Uint8List bytes, String fileName) =>
    impl.savePdf(bytes, fileName);

// Mobile/desktop: write the PDF to a temp file and open the share sheet so the
// person can save it to Files, print it, or send it.

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> savePdf(Uint8List bytes, String fileName) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'My Birth Plan',
    ),
  );
}

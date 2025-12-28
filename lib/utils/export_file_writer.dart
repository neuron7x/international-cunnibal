import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ExportFileWriter {
  const ExportFileWriter();

  Future<String> writeJson({
    required String filename,
    required String jsonPayload,
    String? directoryOverridePath,
  }) async {
    final directory = await _resolveExportDirectory(directoryOverridePath);
    final file = File('${directory.path}/$filename');
    await file.writeAsString(jsonPayload);
    return file.path;
  }

  Future<String> resolveDirectoryPath({String? directoryOverridePath}) async {
    final directory = await _resolveExportDirectory(directoryOverridePath);
    return directory.path;
  }

  Future<Directory> _resolveExportDirectory(
    String? directoryOverridePath,
  ) async {
    if (directoryOverridePath != null) {
      final override = Directory(directoryOverridePath);
      if (!override.existsSync()) {
        await override.create(recursive: true);
      }
      return override;
    }

    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp.createTemp('international_cunnibal_export_');
    }
  }
}

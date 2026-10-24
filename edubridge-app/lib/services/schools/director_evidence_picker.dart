import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../model/schools/director_evidence.dart';
import 'director_api_client.dart';

/// Read a bounded stream instead of loading an unbounded file into memory.
Future<DirectorDocumentDraft?> _pickDirectorEvidence(
  DirectorDocumentKind kind,
) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    allowMultiple: false,
    withData: false,
    withReadStream: true,
  );
  if (result == null) return null;
  final file = result.files.single;
  if (file.size <= 0 ||
      file.size > DirectorDocumentDraft.maxBytes ||
      file.readStream == null) {
    throw const DirectorApiException(DirectorFailure.invalidFile);
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in file.readStream!) {
    if (bytes.length + chunk.length > DirectorDocumentDraft.maxBytes) {
      throw const DirectorApiException(DirectorFailure.invalidFile);
    }
    bytes.add(chunk);
  }
  final draft = DirectorDocumentDraft(
    kind: kind,
    fileName: file.name,
    bytes: bytes.takeBytes(),
  );
  if (!draft.isValid)
    throw const DirectorApiException(DirectorFailure.invalidFile);
  return draft;
}

Future<DirectorDocumentDraft?> pickDirectorEvidence(
  DirectorDocumentKind kind,
) async {
  try {
    return await _pickDirectorEvidence(kind);
  } on DirectorApiException {
    rethrow;
  } on Exception {
    throw const DirectorApiException(DirectorFailure.invalidFile);
  }
}

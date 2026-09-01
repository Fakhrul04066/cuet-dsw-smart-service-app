import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';

class FirebaseStorageService {
  FirebaseStorageService._();

  static final instance = FirebaseStorageService._();
  static const uploadsEnabled = false;
  static const maxFileSizeBytes = 5 * 1024 * 1024;
  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const allowedMimeTypes = [
    'application/pdf',
    'image/jpeg',
    'image/png',
  ];

  Future<List<Map<String, dynamic>>> pickAndUpload({
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    if (!uploadsEnabled) return const [];

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to upload files.');
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result == null) return const [];

    final uploaded = <Map<String, dynamic>>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Could not read ${file.name}.');
      }
      final mimeType = lookupMimeType(file.name, headerBytes: bytes) ?? '';
      if (!allowedMimeTypes.contains(mimeType)) {
        throw StateError('${file.name} is not a supported file type.');
      }
      if (bytes.length > maxFileSizeBytes) {
        throw StateError('${file.name} exceeds the 5 MB size limit.');
      }

      final safeName = file.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final uniqueName = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
      final reference = FirebaseStorage.instance.ref(
        '$folder/${user.uid}/$uniqueName',
      );
      final task = reference.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(
          contentType: mimeType,
          customMetadata: {'uploadedBy': user.uid},
        ),
      );
      task.snapshotEvents.listen((snapshot) {
        onProgress?.call(
          snapshot.totalBytes == 0
              ? 0
              : snapshot.bytesTransferred / snapshot.totalBytes,
        );
      });
      await task;
      final url = await reference.getDownloadURL();
      uploaded.add({
        'url': url,
        'storagePath': reference.fullPath,
        'fileName': file.name,
        'name': file.name,
        'fileType': mimeType,
        'type': mimeType,
        'size': bytes.length,
        'uploadedBy': user.uid,
        'uploadedAt': DateTime.now().toIso8601String(),
      });
    }
    onProgress?.call(1);
    return uploaded;
  }
}

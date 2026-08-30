class DocumentUploadMetadata {
  final String url;
  final String publicId;
  final String fileName;
  final String fileType;
  final DateTime uploadedAt;
  final String uploadedBy;

  const DocumentUploadMetadata({
    required this.url,
    required this.publicId,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  Map<String, dynamic> toMap() => {
    'url': url,
    'publicId': publicId,
    'fileName': fileName,
    'fileType': fileType,
    'uploadedAt': uploadedAt.toIso8601String(),
    'uploadedBy': uploadedBy,
  };
}

class DocumentUploadService {
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static const List<String> allowedMimeTypes = <String>[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/jpg',
  ];

  static bool isAllowedFileType(String fileType) {
    final normalized = fileType.toLowerCase();
    return normalized == 'application/pdf' ||
        normalized == 'image/jpeg' ||
        normalized == 'image/png' ||
        normalized == 'image/jpg';
  }

  static bool isAllowedFileSize(int fileSizeInBytes) {
    return fileSizeInBytes > 0 && fileSizeInBytes <= maxFileSizeBytes;
  }

  static Map<String, dynamic> buildUploadMetadata({
    required String url,
    required String publicId,
    required String fileName,
    required String fileType,
    required String uploadedBy,
  }) {
    return DocumentUploadMetadata(
      url: url,
      publicId: publicId,
      fileName: fileName,
      fileType: fileType,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedBy,
    ).toMap();
  }
}

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/application.dart';
import '../models/user_model.dart';
import '../services/certificate_pdf_service.dart';

class CertificatePreviewScreen extends StatelessWidget {
  final Application application;
  final StudentUser student;

  const CertificatePreviewScreen({
    super.key,
    required this.application,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character Certificate')),
      body: PdfPreview(
        build: (_) => CertificatePdfService.instance.buildPdf(
          application: application,
          student: student,
        ),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}

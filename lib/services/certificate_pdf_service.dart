import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/application.dart';
import '../models/user_model.dart';

class CertificatePdfService {
  CertificatePdfService._();

  static final CertificatePdfService instance = CertificatePdfService._();

  bool canGenerate(Application application) {
    return application.type == 'character_certificate' &&
        application.status == 'CERTIFICATE_ISSUED';
  }

  String fileName(Application application, StudentUser student) {
    final studentId = _safeFilePart(student.studentId);
    final applicationId = _safeFilePart(application.id);
    return 'CUET_Character_Certificate_${studentId}_$applicationId.pdf';
  }

  Future<Uint8List> buildPdf({
    required Application application,
    required StudentUser student,
  }) async {
    if (!canGenerate(application)) {
      throw StateError('This certificate has not been issued yet.');
    }
    if (student.studentId != application.studentId) {
      throw StateError('This certificate does not belong to this student.');
    }

    final pdf = pw.Document();

    final issueDate = _formatDate(application.updatedAt);
    final studentName = student.name.trim().isEmpty ? 'Student' : student.name;
    final department = student.department.trim().isEmpty
        ? 'Not provided'
        : student.department;
    final batch = student.batch.trim().isEmpty ? 'Not provided' : student.batch;
    final hall = student.hall.trim().isEmpty ? 'Not provided' : student.hall;
    final purpose = application.purpose.trim().isEmpty
        ? 'Official purpose'
        : application.purpose.trim();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(44),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1.5, color: PdfColors.black),
          ),
          padding: const pw.EdgeInsets.all(28),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'CHITTAGONG UNIVERSITY OF ENGINEERING & TECHNOLOGY',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Directorate of Students Welfare',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 24),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 18),
              pw.Text(
                'CHARACTER CERTIFICATE',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 28),
              pw.Text(
                'This is to certify that $studentName, Student ID '
                '${student.studentId}, is a student of the $department '
                'department of Chittagong University of Engineering & '
                'Technology (CUET).',
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 18),
              pw.Text(
                'This certificate has been issued through the CUET DSW Smart '
                'Service for the purpose stated in the approved application.',
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 24),
              _detailTable(
                studentId: student.studentId,
                department: department,
                batch: batch,
                hall: hall,
                purpose: purpose,
                applicationId: application.id,
                issueDate: issueDate,
              ),
              pw.Spacer(),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Verification / Reference ID',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(application.id),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 36),
                  pw.Container(
                    width: 180,
                    child: pw.Column(
                      children: [
                        pw.SizedBox(height: 34),
                        pw.Divider(thickness: 1),
                        pw.Text(
                          'Director, Students Welfare',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'CUET',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Generated electronically by CUET DSW Smart Service.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> viewCertificate({
    required Application application,
    required StudentUser student,
  }) async {
    final bytes = await buildPdf(application: application, student: student);
    await Printing.layoutPdf(
      name: fileName(application, student),
      onLayout: (_) async => bytes,
    );
  }

  Future<void> downloadCertificate({
    required Application application,
    required StudentUser student,
  }) async {
    final bytes = await buildPdf(application: application, student: student);
    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName(application, student),
    );
  }

  pw.Widget _detailTable({
    required String studentId,
    required String department,
    required String batch,
    required String hall,
    required String purpose,
    required String applicationId,
    required String issueDate,
  }) {
    final rows = <List<String>>[
      ['Student ID', studentId],
      ['Department', department],
      ['Batch', batch],
      ['Hall', hall],
      ['Purpose', purpose],
      ['Application ID', applicationId],
      ['Issue Date', issueDate],
    ];

    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(2.2),
      },
      children: rows
          .map(
            (row) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(7),
                  child: pw.Text(
                    row[0],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(7),
                  child: pw.Text(row[1]),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day-$month-${local.year}';
  }

  String _safeFilePart(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return cleaned.isEmpty ? 'unknown' : cleaned;
  }
}

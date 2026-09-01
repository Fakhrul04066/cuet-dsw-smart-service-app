import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;

  const StatusChip({super.key, required this.label});

  String _displayLabel() {
    switch (label) {
      case 'SUBMITTED':
        return 'Submitted';
      case 'OFFICER_REVIEW':
        return 'Officer Processing';
      case 'CORRECTION_REQUIRED':
        return 'Correction Required';
      case 'OFFICER_APPROVED':
        return 'Officer Approved';
      case 'DIRECTOR_REVIEW':
        return 'Director Processing';
      case 'APPROVED':
        return 'Approved';
      case 'CERTIFICATE_ISSUED':
        return 'Certificate Issued';
      case 'REJECTED':
        return 'Rejected';
      default:
        return label;
    }
  }

  Color _chipColor() {
    switch (label) {
      case 'SUBMITTED':
      case 'Submitted':
        return const Color(0xFFE3F2FD);
      case 'OFFICER_REVIEW':
      case 'Officer Processing':
        return const Color(0xFFFFF3CD);
      case 'CORRECTION_REQUIRED':
      case 'Correction Required':
        return const Color(0xFFFFE0B2);
      case 'OFFICER_APPROVED':
      case 'Officer Approved':
        return const Color(0xFFE8EAF6);
      case 'DIRECTOR_REVIEW':
      case 'Director Processing':
        return const Color(0xFFE0F7FA);
      case 'APPROVED':
      case 'Approved':
        return const Color(0xFFE8F5E9);
      case 'CERTIFICATE_ISSUED':
      case 'Certificate Issued':
        return const Color(0xFFE0F2F1);
      case 'REJECTED':
      case 'Rejected':
        return const Color(0xFFFFEBEE);
      default:
        return const Color(0xFFEAEAF3);
    }
  }

  Color _textColor() {
    switch (label) {
      case 'SUBMITTED':
      case 'Submitted':
        return const Color(0xFF1565C0);
      case 'OFFICER_REVIEW':
      case 'Officer Processing':
        return const Color(0xFF9C6B00);
      case 'CORRECTION_REQUIRED':
      case 'Correction Required':
        return const Color(0xFFB26A00);
      case 'OFFICER_APPROVED':
      case 'Officer Approved':
        return const Color(0xFF3949AB);
      case 'DIRECTOR_REVIEW':
      case 'Director Processing':
        return const Color(0xFF00838F);
      case 'APPROVED':
      case 'Approved':
        return const Color(0xFF2E7D32);
      case 'CERTIFICATE_ISSUED':
      case 'Certificate Issued':
        return const Color(0xFF00695C);
      case 'REJECTED':
      case 'Rejected':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLabel = _displayLabel();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        displayLabel,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _textColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

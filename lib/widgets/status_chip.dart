import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;

  const StatusChip({super.key, required this.label});

  Color _chipColor() {
    switch (label) {
      case 'Submitted':
        return const Color(0xFFE3F2FD);
      case 'Under Review':
        return const Color(0xFFFFF3CD);
      case 'Correction Required':
        return const Color(0xFFFFE0B2);
      case 'Resubmitted':
        return const Color(0xFFE8EAF6);
      case 'Approved':
        return const Color(0xFFE8F5E9);
      case 'Rejected':
        return const Color(0xFFFFEBEE);
      case 'Assigned':
        return const Color(0xFFEDE7F6);
      case 'In Progress':
        return const Color(0xFFE0F7FA);
      case 'Resolved':
        return const Color(0xFFE0F2F1);
      case 'Closed':
        return const Color(0xFFEEF2FF);
      default:
        return const Color(0xFFEAEAF3);
    }
  }

  Color _textColor() {
    switch (label) {
      case 'Submitted':
        return const Color(0xFF1565C0);
      case 'Under Review':
        return const Color(0xFF9C6B00);
      case 'Correction Required':
        return const Color(0xFFB26A00);
      case 'Resubmitted':
        return const Color(0xFF3949AB);
      case 'Approved':
        return const Color(0xFF2E7D32);
      case 'Rejected':
        return const Color(0xFFC62828);
      case 'Assigned':
        return const Color(0xFF5E35B1);
      case 'In Progress':
        return const Color(0xFF00838F);
      case 'Resolved':
        return const Color(0xFF00695C);
      case 'Closed':
        return const Color(0xFF3949AB);
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: _textColor(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

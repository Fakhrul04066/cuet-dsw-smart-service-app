import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;

  const StatusChip({super.key, required this.label});

  Color _chipColor(BuildContext context) {
    switch (label) {
      case 'Under Review':
        return const Color(0xFFFFF3CD);
      case 'In Progress':
        return const Color(0xFFE3F2FD);
      case 'Approved':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFEAEAF3);
    }
  }

  Color _textColor() {
    switch (label) {
      case 'Under Review':
        return const Color(0xFF9C6B00);
      case 'In Progress':
        return const Color(0xFF1565C0);
      case 'Approved':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF4B5563);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _chipColor(context),
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

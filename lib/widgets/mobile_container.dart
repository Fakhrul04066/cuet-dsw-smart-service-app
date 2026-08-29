import 'package:flutter/material.dart';

class MobileContainer extends StatelessWidget {
  final Widget child;

  const MobileContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: child,
      ),
    );
  }
}

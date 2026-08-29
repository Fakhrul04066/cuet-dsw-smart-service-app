import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CUETDSWApp());
}

class CUETDSWApp extends StatelessWidget {
  const CUETDSWApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUET DSW Smart Service',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        );
      },
      home: const SplashScreen(),
    );
  }
}

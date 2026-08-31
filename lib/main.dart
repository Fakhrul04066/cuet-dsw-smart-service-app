import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      home: const AuthGate(),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Android App Check is enabled immediately. For Flutter Web, configure a
  // reCAPTCHA provider in Firebase before enforcing App Check in production.
  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider()
          : AndroidPlayIntegrityProvider(),
    );
  }

  runApp(const CUETDSWApp());
}

class CUETDSWApp extends StatelessWidget {
  const CUETDSWApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUET DSW Operations & Student Services',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) => child ?? const SizedBox.shrink(),
      home: const AuthGate(),
    );
  }
}

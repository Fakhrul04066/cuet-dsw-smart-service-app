import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuet_dsw_app/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase connection smoke test', () {
    test(
      'Firestore can write and read a temporary dev-only document',
      () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        final firestore = FirebaseFirestore.instance;
        final collection = firestore.collection('__firebase_connect_test__');
        final docId = 'connect_${DateTime.now().millisecondsSinceEpoch}';
        final ref = collection.doc(docId);

        await ref.set({
          'status': 'ok',
          'createdAt': FieldValue.serverTimestamp(),
          'message': 'Connection check',
        });

        final snapshot = await ref.get();

        expect(snapshot.exists, isTrue);
        expect(snapshot.data()?['status'], 'ok');

        await ref.delete();
      },
    );
  });
}

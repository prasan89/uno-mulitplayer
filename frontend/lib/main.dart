import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before any async work.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the generated options from FlutterFire CLI.
  // Run `flutterfire configure` once to generate lib/firebase_options.dart,
  // then uncomment the import and the options line below.
  //
  // import 'firebase_options.dart';
  // options: DefaultFirebaseOptions.currentPlatform,
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: UnoApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is NOT initialized in M1 — all services use mock implementations.
  // Wire real Firebase in M2 behind #if FIREBASE_ENABLED.
  runApp(const ProviderScope(child: WildDeckApp()));
}

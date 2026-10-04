import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';

class WildDeckApp extends ConsumerWidget {
  const WildDeckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'WildDeck',
      debugShowCheckedModeBanner: false,
      theme: WildDeckTheme.themeData,
      routerConfig: router,
    );
  }
}

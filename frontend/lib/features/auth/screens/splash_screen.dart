import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Splash screen that checks auth state and redirects appropriately.
/// The actual redirect logic is handled by GoRouter's redirect callback.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Allow the GoRouter redirect to handle navigation after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // Router redirect will handle destination based on auth state.
        // If we reach here and no redirect happened, go to login.
        context.go('/auth/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: Text(
                  'UNO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

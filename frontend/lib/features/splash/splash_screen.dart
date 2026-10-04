import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';

/// WildDeck Splash screen — original branding, no UNO/Mattel assets.
class WildDeckSplashScreen extends StatefulWidget {
  const WildDeckSplashScreen({super.key});

  @override
  State<WildDeckSplashScreen> createState() => _WildDeckSplashScreenState();
}

class _WildDeckSplashScreenState extends State<WildDeckSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _taglineCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _taglineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5)),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_taglineCtrl);
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _taglineCtrl.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) context.go(WildRoutes.login);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _taglineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.heroGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: _WildDeckLogo(size: 120),
                  ),
                ),
                const SizedBox(height: 28),
                // Title
                FadeTransition(
                  opacity: _logoOpacity,
                  child: const Text(
                    'WILDDECK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tagline
                SlideTransition(
                  position: _taglineSlide,
                  child: FadeTransition(
                    opacity: _taglineOpacity,
                    child: const Text(
                      'Play Wild. Win Fast.',
                      style: TextStyle(
                        color: WildDeckTheme.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: const CircularProgressIndicator(
                    color: WildDeckTheme.gold,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WildDeckLogo extends StatelessWidget {
  final double size;
  const _WildDeckLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WildDeckTheme.cardRed, WildDeckTheme.cardBlue, WildDeckTheme.cardWild],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: WildDeckTheme.cardRed.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'WD',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            shadows: const [
              Shadow(color: Colors.black38, offset: Offset(2, 2), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

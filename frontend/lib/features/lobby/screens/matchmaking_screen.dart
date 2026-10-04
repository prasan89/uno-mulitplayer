import 'dart:async';
import 'package:flutter/material.dart';

class MatchmakingScreen extends StatefulWidget {
  final VoidCallback? onCancel;
  final void Function(String gameId)? onMatchFound;

  const MatchmakingScreen({
    super.key,
    this.onCancel,
    this.onMatchFound,
  });

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _queuePosition = 0;
  int _elapsedSeconds = 0;
  Timer? _simulationTimer;

  // Dots loading animation
  int _dotCount = 1;
  Timer? _dotsTimer;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
        // Simulate queue position update
        if (_elapsedSeconds % 5 == 0 && _queuePosition > 1) {
          _queuePosition--;
        }
      });
    });

    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _dotCount = _dotCount % 3 + 1;
      });
    });

    // Simulate initial queue position
    _queuePosition = 4;
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _simulationTimer?.cancel();
    _dotsTimer?.cancel();
    super.dispose();
  }

  String get _elapsedText {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    if (m > 0) {
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '${s}s';
  }

  String get _dotsText => '.' * _dotCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Finding a Match',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated WildDeck logo / spinner
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E1E),
                    border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spinning ring
                      RotationTransition(
                        turns: _rotateController,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                const Color(0xFFE53935),
                                const Color(0xFFE53935).withOpacity(0.0),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E1E1E),
                        ),
                        child: const Center(
                          child: Text(
                            'WD',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Main status text
              Text(
                'Finding opponents$_dotsText',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Time elapsed: $_elapsedText',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              // Queue position chip
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_outline,
                      color: Colors.white38,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _queuePosition > 0
                          ? 'Position #$_queuePosition in queue'
                          : 'Almost there!',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Players found indicator
              _PlayersFoundRow(found: 1, total: 4),
              const Spacer(),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayersFoundRow extends StatelessWidget {
  final int found;
  final int total;

  const _PlayersFoundRow({required this.found, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (index) {
        final isFilled = index < found;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? const Color(0xFFE53935)
                  : const Color(0xFF1E1E1E),
              border: Border.all(
                color: isFilled
                    ? const Color(0xFFE53935)
                    : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.person,
              size: 18,
              color: isFilled ? Colors.white : Colors.white24,
            ),
          ),
        );
      }),
    );
  }
}

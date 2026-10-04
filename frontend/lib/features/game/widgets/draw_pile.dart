import 'package:flutter/material.dart';

class DrawPile extends StatefulWidget {
  final int cardCount;
  final VoidCallback? onDraw;
  final bool canDraw;

  const DrawPile({
    super.key,
    required this.cardCount,
    this.onDraw,
    this.canDraw = false,
  });

  @override
  State<DrawPile> createState() => _DrawPileState();
}

class _DrawPileState extends State<DrawPile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(DrawPile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.canDraw && !oldWidget.canDraw) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.canDraw && oldWidget.canDraw) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Draw',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white54,
              ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: widget.canDraw ? widget.onDraw : null,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: SizedBox(
              width: 80,
              height: 112,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pile depth effect
                  for (int i = 4; i >= 1; i--)
                    Positioned(
                      top: i.toDouble(),
                      left: i.toDouble(),
                      child: Container(
                        width: 70,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.6 + i * 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white12,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  // Top card
                  Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF1A237E),
                          Color(0xFF283593),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.canDraw
                            ? const Color(0xFFE53935)
                            : Colors.white24,
                        width: widget.canDraw ? 2.5 : 1.5,
                      ),
                      boxShadow: widget.canDraw
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFFE53935).withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'WD',
                            style: TextStyle(
                              color: widget.canDraw
                                  ? const Color(0xFFE53935)
                                  : Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (widget.canDraw)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'TAP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.cardCount} cards',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white38,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

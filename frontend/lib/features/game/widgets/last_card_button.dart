import 'package:flutter/material.dart';

class LastCardButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isVisible;

  const LastCardButton({
    super.key,
    this.onPressed,
    this.isVisible = false,
  });

  @override
  State<LastCardButton> createState() => _LastCardButtonState();
}

class _LastCardButtonState extends State<LastCardButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _colorAnimation = ColorTween(
      begin: const Color(0xFFE53935),
      end: const Color(0xFFF9A825),
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeInOut));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LastCardButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _flashController.repeat(reverse: true);
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _flashController.stop();
      _flashController.reset();
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: AnimatedBuilder(
          animation: _flashController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTap: widget.onPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _colorAnimation.value,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white30, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (_colorAnimation.value ?? const Color(0xFFE53935))
                            .withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Text(
                    'LAST CARD!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

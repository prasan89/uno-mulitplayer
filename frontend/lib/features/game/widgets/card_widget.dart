import 'package:flutter/material.dart';

enum CardColor { red, blue, green, yellow, wild }

enum CardValue {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  skip,
  reverse,
  drawTwo,
  wild,
  wildDrawFour,
}

class UnoCard {
  final CardColor color;
  final CardValue value;
  final String id;

  const UnoCard({
    required this.color,
    required this.value,
    required this.id,
  });

  String get displayValue {
    switch (value) {
      case CardValue.zero:
        return '0';
      case CardValue.one:
        return '1';
      case CardValue.two:
        return '2';
      case CardValue.three:
        return '3';
      case CardValue.four:
        return '4';
      case CardValue.five:
        return '5';
      case CardValue.six:
        return '6';
      case CardValue.seven:
        return '7';
      case CardValue.eight:
        return '8';
      case CardValue.nine:
        return '9';
      case CardValue.skip:
        return '⊘';
      case CardValue.reverse:
        return '↺';
      case CardValue.drawTwo:
        return '+2';
      case CardValue.wild:
        return 'W';
      case CardValue.wildDrawFour:
        return '+4';
    }
  }

  bool get isWild =>
      value == CardValue.wild || value == CardValue.wildDrawFour;
}

class CardWidget extends StatefulWidget {
  final UnoCard card;
  final bool isPlayable;
  final bool isSelected;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardWidget({
    super.key,
    required this.card,
    this.isPlayable = true,
    this.isSelected = false,
    this.onTap,
    this.width = 70,
    this.height = 100,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getCardColor() {
    switch (widget.card.color) {
      case CardColor.red:
        return const Color(0xFFE53935);
      case CardColor.blue:
        return const Color(0xFF1565C0);
      case CardColor.green:
        return const Color(0xFF2E7D32);
      case CardColor.yellow:
        return const Color(0xFFF9A825);
      case CardColor.wild:
        return Colors.black;
    }
  }

  Gradient? _getCardGradient() {
    if (widget.card.color == CardColor.wild) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE53935),
          Color(0xFF1565C0),
          Color(0xFF2E7D32),
          Color(0xFFF9A825),
        ],
        stops: [0.0, 0.33, 0.66, 1.0],
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getCardGradient();
    final cardColor = _getCardColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      transform: widget.isSelected
          ? (Matrix4.identity()..translate(0.0, -10.0))
          : Matrix4.identity(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IgnorePointer(
          ignoring: !widget.isPlayable,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) {
              if (widget.isPlayable) {
                _animationController.forward();
              }
            },
            onTapUp: (_) {
              _animationController.reverse();
            },
            onTapCancel: () {
              _animationController.reverse();
            },
            child: Opacity(
              opacity: widget.isPlayable ? 1.0 : 0.5,
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: gradient == null ? cardColor : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    width: widget.isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                          widget.isSelected ? 0.6 : 0.3),
                      blurRadius: widget.isSelected ? 12 : 6,
                      offset: Offset(0, widget.isSelected ? 6 : 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Oval background
                    Center(
                      child: Container(
                        width: widget.width * 0.75,
                        height: widget.height * 0.75,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(widget.width * 0.3),
                        ),
                      ),
                    ),
                    // Center value
                    Center(
                      child: Text(
                        widget.card.displayValue,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.width * 0.38,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Top-left corner value
                    Positioned(
                      top: 4,
                      left: 6,
                      child: Text(
                        widget.card.displayValue,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.width * 0.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Bottom-right corner value (rotated)
                    Positioned(
                      bottom: 4,
                      right: 6,
                      child: Transform.rotate(
                        angle: 3.14159,
                        child: Text(
                          widget.card.displayValue,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.width * 0.2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

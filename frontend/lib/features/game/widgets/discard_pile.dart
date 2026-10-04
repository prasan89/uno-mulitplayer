import 'package:flutter/material.dart';
import 'card_widget.dart';

class DiscardPile extends StatefulWidget {
  final WildCard? topCard;
  final int totalDiscarded;

  const DiscardPile({
    super.key,
    this.topCard,
    this.totalDiscarded = 0,
  });

  @override
  State<DiscardPile> createState() => _DiscardPileState();
}

class _DiscardPileState extends State<DiscardPile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  WildCard? _previousCard;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void didUpdateWidget(DiscardPile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topCard?.id != widget.topCard?.id) {
      _previousCard = oldWidget.topCard;
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Discard',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white54,
              ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow pile effect
              if (widget.totalDiscarded > 1)
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (widget.topCard != null)
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: CardWidget(
                      card: widget.topCard!,
                      isPlayable: false,
                      onTap: null,
                    ),
                  ),
                )
              else
                Container(
                  width: 70,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Empty',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.totalDiscarded} cards',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white38,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

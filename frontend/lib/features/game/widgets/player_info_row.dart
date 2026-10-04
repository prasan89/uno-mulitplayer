import 'package:flutter/material.dart';
import 'card_widget.dart';

class PlayerInfoRow extends StatefulWidget {
  final String playerName;
  final int cardCount;
  final bool isCurrentTurn;
  final bool isCurrentPlayer;
  final String? avatarUrl;

  const PlayerInfoRow({
    super.key,
    required this.playerName,
    required this.cardCount,
    this.isCurrentTurn = false,
    this.isCurrentPlayer = false,
    this.avatarUrl,
  });

  @override
  State<PlayerInfoRow> createState() => _PlayerInfoRowState();
}

class _PlayerInfoRowState extends State<PlayerInfoRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _colorAnimation = ColorTween(
      begin: const Color(0xFF1E1E1E),
      end: const Color(0xFFE53935).withOpacity(0.2),
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    if (widget.isCurrentTurn) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PlayerInfoRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentTurn && !oldWidget.isCurrentTurn) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isCurrentTurn && oldWidget.isCurrentTurn) {
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
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCurrentTurn ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isCurrentTurn
                  ? _colorAnimation.value
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isCurrentTurn
                    ? const Color(0xFFE53935)
                    : Colors.white12,
                width: widget.isCurrentTurn ? 1.5 : 1.0,
              ),
              boxShadow: widget.isCurrentTurn
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _getAvatarColor(),
                      child: Text(
                        widget.playerName.isNotEmpty
                            ? widget.playerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (widget.isCurrentTurn)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                // Name
                SizedBox(
                  width: 64,
                  child: Text(
                    widget.playerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.isCurrentTurn
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 11,
                      fontWeight: widget.isCurrentTurn
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Card count
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.style,
                      size: 12,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.cardCount}',
                      style: TextStyle(
                        color: widget.cardCount == 1
                            ? const Color(0xFFF9A825)
                            : Colors.white54,
                        fontSize: 12,
                        fontWeight: widget.cardCount == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (widget.cardCount == 1)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9A825),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'LAST CARD!',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getAvatarColor() {
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFFF9A825),
      const Color(0xFF6A1B9A),
    ];
    final index = widget.playerName.isNotEmpty
        ? widget.playerName.codeUnitAt(0) % colors.length
        : 0;
    return colors[index];
  }
}

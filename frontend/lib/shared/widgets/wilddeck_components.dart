import 'package:flutter/material.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';

// ─── WildDeckCard ─────────────────────────────────────────────────────────────

/// Original WildDeck card widget. Not based on any external card game IP.
class WildDeckCardWidget extends StatefulWidget {
  final WildCardColor color;
  final WildCardType type;
  final int? number;
  final bool isPlayable;
  final bool isSelected;
  final bool isFaceDown;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const WildDeckCardWidget({
    super.key,
    required this.color,
    required this.type,
    this.number,
    this.isPlayable = true,
    this.isSelected = false,
    this.isFaceDown = false,
    this.onTap,
    this.width = 72,
    this.height = 104,
  });

  @override
  State<WildDeckCardWidget> createState() => _WildDeckCardWidgetState();
}

class _WildDeckCardWidgetState extends State<WildDeckCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _label {
    switch (widget.type) {
      case WildCardType.number:       return '${widget.number ?? 0}';
      case WildCardType.skip:         return '⊘';
      case WildCardType.reverse:      return '↺';
      case WildCardType.drawTwo:      return '+2';
      case WildCardType.wild:         return 'W';
      case WildCardType.wildDrawFour: return '+4';
    }
  }

  Color get _baseColor => WildDeckTheme.colorForCardColor(widget.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: widget.isSelected
          ? Matrix4.translationValues(0.0, -12.0, 0)
          : Matrix4.identity(),
      child: ScaleTransition(
        scale: _scale,
        child: GestureDetector(
          onTap: widget.isPlayable ? widget.onTap : null,
          onTapDown: (_) { if (widget.isPlayable) _ctrl.forward(); },
          onTapUp: (_) => _ctrl.reverse(),
          onTapCancel: () => _ctrl.reverse(),
          child: Opacity(
            opacity: widget.isPlayable ? 1.0 : 0.45,
            child: widget.isFaceDown ? _buildBack() : _buildFront(),
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WildDeckTheme.navyCard, WildDeckTheme.navyBorder],
        ),
        borderRadius: WildDeckTheme.radiusCard,
        border: Border.all(color: WildDeckTheme.navyBorder, width: 1.5),
        boxShadow: WildDeckTheme.cardShadow(WildDeckTheme.navyCard),
      ),
      child: Center(
        child: Text(
          'WD',
          style: TextStyle(
            color: WildDeckTheme.gold.withValues(alpha: 0.6),
            fontSize: widget.width * 0.28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFront() {
    final isWild = widget.color == WildCardColor.wild;
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: isWild
            ? WildDeckTheme.wildGradient
            : WildDeckTheme.cardGradient(_baseColor),
        borderRadius: WildDeckTheme.radiusCard,
        border: Border.all(
          color: widget.isSelected ? Colors.white : Colors.white.withValues(alpha: 0.25),
          width: widget.isSelected ? 2.5 : 1.5,
        ),
        boxShadow: WildDeckTheme.cardShadow(_baseColor, elevated: widget.isSelected),
      ),
      child: Stack(
        children: [
          // Inner oval
          Center(
            child: Container(
              width: widget.width * 0.7,
              height: widget.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(widget.width * 0.28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
            ),
          ),
          // Center symbol
          Center(
            child: Text(
              _label,
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.width * 0.4,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 4),
                ],
              ),
            ),
          ),
          // Top-left
          Positioned(
            top: 4, left: 6,
            child: Text(_label,
              style: TextStyle(color: Colors.white, fontSize: widget.width * 0.19, fontWeight: FontWeight.w800)),
          ),
          // Bottom-right (rotated)
          Positioned(
            bottom: 4, right: 6,
            child: Transform.rotate(
              angle: 3.14159,
              child: Text(_label,
                style: TextStyle(color: Colors.white, fontSize: widget.width * 0.19, fontWeight: FontWeight.w800)),
            ),
          ),
          // Playable glow ring
          if (widget.isPlayable && !widget.isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: WildDeckTheme.radiusCard,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.0),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── PlayerAvatar ─────────────────────────────────────────────────────────────

class PlayerAvatar extends StatelessWidget {
  final String? avatarId;
  final String displayName;
  final double size;
  final bool isCurrentTurn;
  final bool isBot;
  final bool showBorder;

  const PlayerAvatar({
    super.key,
    this.avatarId,
    required this.displayName,
    this.size = 48,
    this.isCurrentTurn = false,
    this.isBot = false,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isBot
              ? [const Color(0xFF37474F), const Color(0xFF263238)]
              : [_colorFromName(displayName), _colorFromName(displayName).withValues(alpha: 0.7)],
        ),
        border: showBorder ? Border.all(
          color: isCurrentTurn ? WildDeckTheme.gold : WildDeckTheme.navyBorder,
          width: isCurrentTurn ? 2.5 : 1.5,
        ) : null,
        boxShadow: isCurrentTurn
            ? WildDeckTheme.buttonGlow(WildDeckTheme.gold)
            : null,
      ),
      child: Center(
        child: isBot
            ? Icon(Icons.smart_toy, color: Colors.white70, size: size * 0.5)
            : Text(
                initial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Color _colorFromName(String name) {
    final colors = [
      const Color(0xFFFF3B5C), const Color(0xFF2979FF),
      const Color(0xFF00C853), const Color(0xFF7C4DFF),
      const Color(0xFFFF6D00), const Color(0xFF00B8D4),
    ];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % colors.length;
    return colors[idx];
  }
}

// ─── CoinBadge ────────────────────────────────────────────────────────────────

class CoinBadge extends StatelessWidget {
  final int amount;
  final bool compact;

  const CoinBadge({super.key, required this.amount, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: WildDeckTheme.goldGradient,
        borderRadius: WildDeckTheme.radiusSmall,
        boxShadow: WildDeckTheme.buttonGlow(WildDeckTheme.gold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: Colors.brown[900], size: compact ? 14 : 16),
          const SizedBox(width: 4),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              color: Colors.brown[900],
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ─── XPBar ────────────────────────────────────────────────────────────────────

class XPBar extends StatelessWidget {
  final int xp;
  final int xpToNext;
  final double height;
  final bool showLabel;

  const XPBar({
    super.key,
    required this.xp,
    required this.xpToNext,
    this.height = 6,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = xpToNext == 0 ? 1.0 : (xp / xpToNext).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(
            children: [
              Container(height: height, color: WildDeckTheme.navyBorder),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: height,
                  decoration: const BoxDecoration(
                    gradient: WildDeckTheme.goldGradient,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          Text(
            '$xp / $xpToNext XP',
            style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

// ─── PrimaryButton ────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsets? padding;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed != null
              ? WildDeckTheme.primaryButtonGradient
              : const LinearGradient(colors: [WildDeckTheme.navyBorder, WildDeckTheme.navyBorder]),
          borderRadius: WildDeckTheme.radiusMedium,
          boxShadow: onPressed != null
              ? WildDeckTheme.buttonGlow(WildDeckTheme.cardRed)
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: WildDeckTheme.radiusMedium),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                    Text(label, style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      letterSpacing: 1, color: Colors.white,
                    )),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── SecondaryButton ──────────────────────────────────────────────────────────

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: WildDeckTheme.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: borderColor ?? WildDeckTheme.navyBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: WildDeckTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5,
            )),
          ],
        ),
      ),
    );
  }
}

// ─── TurnIndicator ────────────────────────────────────────────────────────────

class TurnIndicator extends StatefulWidget {
  final bool isMyTurn;
  final String? currentPlayerName;

  const TurnIndicator({
    super.key,
    required this.isMyTurn,
    this.currentPlayerName,
  });

  @override
  State<TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<TurnIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMyTurn ? WildDeckTheme.gold : WildDeckTheme.textMuted;
    final label = widget.isMyTurn
        ? 'YOUR TURN'
        : '${widget.currentPlayerName ?? "Opponent"}\'S TURN';

    return ScaleTransition(
      scale: widget.isMyTurn ? _pulse : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: WildDeckTheme.radiusSmall,
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ─── GameStatus bar ───────────────────────────────────────────────────────────

class GameStatusBar extends StatelessWidget {
  final String gameId;
  final int drawPileCount;
  final int discardCount;
  final bool isClockwise;

  const GameStatusBar({
    super.key,
    required this.gameId,
    required this.drawPileCount,
    required this.discardCount,
    required this.isClockwise,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Stat(label: 'Draw', value: '$drawPileCount'),
        const SizedBox(width: 16),
        _Stat(label: 'Discard', value: '$discardCount'),
        const SizedBox(width: 16),
        _Stat(label: 'Direction', value: isClockwise ? '→' : '←'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: const TextStyle(
        color: WildDeckTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(
        color: WildDeckTheme.textMuted, fontSize: 10, letterSpacing: 0.8)),
    ],
  );
}

// ─── BottomNavigation ─────────────────────────────────────────────────────────

class WildDeckBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const WildDeckBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WildDeckTheme.navyMid,
        border: Border(top: BorderSide(color: WildDeckTheme.navyBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(icon: Icons.home_rounded,       label: 'Home',        index: 0, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.leaderboard_rounded, label: 'Rank',        index: 1, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.assignment,          label: 'Missions',    index: 2, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.storefront_rounded,  label: 'Shop',        index: 3, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.people_alt_rounded,  label: 'Friends',     index: 4, current: currentIndex, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: active
                    ? BoxDecoration(
                        color: WildDeckTheme.gold.withValues(alpha: 0.15),
                        borderRadius: WildDeckTheme.radiusSmall,
                      )
                    : null,
                child: Icon(icon,
                  color: active ? WildDeckTheme.gold : WildDeckTheme.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(
                color: active ? WildDeckTheme.gold : WildDeckTheme.textMuted,
                fontSize: 10, fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TopBar ───────────────────────────────────────────────────────────────────

class WildDeckTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;

  const WildDeckTopBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: WildDeckTheme.navyDeep,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: leading ?? (showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null),
      title: Text(title),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: WildDeckTheme.navyBorder),
      ),
    );
  }
}

// ─── Modal ────────────────────────────────────────────────────────────────────

class WildDeckModal extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const WildDeckModal({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => WildDeckModal(title: title, child: child, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: WildDeckTheme.navyMid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: WildDeckTheme.navyBorder)),
      ),
      padding: EdgeInsets.only(
        top: 20, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: WildDeckTheme.navyBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          child,
          if (actions != null) ...[
            const SizedBox(height: 16),
            ...actions!,
          ],
        ],
      ),
    );
  }
}

// ─── PlayerSeat ───────────────────────────────────────────────────────────────

class PlayerSeat extends StatelessWidget {
  final String displayName;
  final String? avatarId;
  final int cardCount;
  final bool isCurrentTurn;
  final bool isBot;
  final bool isConnected;
  final bool showCardCount;

  const PlayerSeat({
    super.key,
    required this.displayName,
    this.avatarId,
    required this.cardCount,
    this.isCurrentTurn = false,
    this.isBot = false,
    this.isConnected = true,
    this.showCardCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            PlayerAvatar(
              avatarId: avatarId,
              displayName: displayName,
              size: 44,
              isCurrentTurn: isCurrentTurn,
              isBot: isBot,
            ),
            if (!isConnected)
              Positioned(
                bottom: -2, right: -2,
                child: Container(
                  width: 14, height: 14,
                  decoration: const BoxDecoration(
                    color: WildDeckTheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          displayName.length > 8 ? '${displayName.substring(0, 7)}…' : displayName,
          style: TextStyle(
            color: isCurrentTurn ? WildDeckTheme.gold : WildDeckTheme.textSecond,
            fontSize: 11,
            fontWeight: isCurrentTurn ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        if (showCardCount) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.style, size: 11, color: WildDeckTheme.textMuted),
              const SizedBox(width: 3),
              Text('$cardCount', style: const TextStyle(
                color: WildDeckTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600,
              )),
            ],
          ),
        ],
      ],
    );
  }
}

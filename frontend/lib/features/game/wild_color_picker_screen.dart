import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wilddeck/core/services/wilddeck_services.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';

/// Wild color selection screen — 4 large color buttons.
class WildColorPickerScreen extends StatefulWidget {
  final WildGameCard? card;
  const WildColorPickerScreen({super.key, this.card});

  @override
  State<WildColorPickerScreen> createState() => _WildColorPickerScreenState();
}

class _WildColorPickerScreenState extends State<WildColorPickerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  WildCardColor? _selected;

  static const _colors = [
    (WildCardColor.red,    'RED',    WildDeckTheme.cardRed,    Icons.favorite_rounded),
    (WildCardColor.blue,   'BLUE',   WildDeckTheme.cardBlue,   Icons.water_drop_rounded),
    (WildCardColor.green,  'GREEN',  WildDeckTheme.cardGreen,  Icons.eco_rounded),
    (WildCardColor.yellow, 'YELLOW', WildDeckTheme.cardYellow, Icons.wb_sunny_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    unawaited(_ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pick(WildCardColor color) {
    setState(() => _selected = color);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) Navigator.of(context).pop(color);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _ctrl,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Title
                  const Text('CHOOSE A COLOR', textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900,
                      letterSpacing: 4)),
                  const SizedBox(height: 8),
                  const Text('Pick the color for your Wild card', textAlign: TextAlign.center,
                    style: TextStyle(color: WildDeckTheme.textMuted, fontSize: 14)),
                  const SizedBox(height: 40),
                  // Color grid
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: _colors.map((entry) {
                        final (color, label, colorValue, icon) = entry;
                        final isSelected = _selected == color;
                        return _ColorButton(
                          label: label,
                          color: colorValue,
                          icon: icon,
                          isSelected: isSelected,
                          onTap: () => _pick(color),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: WildDeckTheme.textMuted)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorButton extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ColorButton> createState() => _ColorButtonState();
}

class _ColorButtonState extends State<_ColorButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => unawaited(_pressCtrl.forward()),
      onTapUp: (_) { unawaited(_pressCtrl.reverse()); widget.onTap(); },
      onTapCancel: () => unawaited(_pressCtrl.reverse()),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [widget.color, widget.color.withValues(alpha: 0.6)],
            ),
            borderRadius: WildDeckTheme.radiusLarge,
            border: Border.all(
              color: widget.isSelected ? Colors.white : Colors.transparent, width: 3),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: widget.isSelected ? 0.7 : 0.35),
                blurRadius: widget.isSelected ? 24 : 12,
                spreadRadius: widget.isSelected ? 4 : 0,
              ),
            ],
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, color: Colors.white, size: 40,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 8)]),
            const SizedBox(height: 10),
            Text(widget.label, style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900,
              letterSpacing: 2, shadows: [Shadow(color: Colors.black38, blurRadius: 6)])),
          ]),
        ),
      ),
    );
  }
}

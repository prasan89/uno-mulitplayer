import 'package:flutter/material.dart';
import 'card_widget.dart';

class ColorPickerDialog extends StatelessWidget {
  const ColorPickerDialog({super.key});

  static Future<CardColor?> show(BuildContext context) {
    return showDialog<CardColor>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ColorPickerDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Choose a Color',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select the color to change to',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ColorButton(
                color: const Color(0xFFE53935),
                label: 'Red',
                onTap: () => Navigator.pop(context, CardColor.red),
              ),
              _ColorButton(
                color: const Color(0xFF1565C0),
                label: 'Blue',
                onTap: () => Navigator.pop(context, CardColor.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ColorButton(
                color: const Color(0xFF2E7D32),
                label: 'Green',
                onTap: () => Navigator.pop(context, CardColor.green),
              ),
              _ColorButton(
                color: const Color(0xFFF9A825),
                label: 'Yellow',
                onTap: () => Navigator.pop(context, CardColor.yellow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

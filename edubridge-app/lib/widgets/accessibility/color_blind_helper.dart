// أدوات عمى الألوان — رموز وأنماط بديلة
import 'package:flutter/material.dart';

enum ColorBlindnessType {
  none,
  protanopia,   // عمى الأحمر
  deuteranopia, // عمى الأخضر
  tritanopia,   // عمى الأزرق
}

class ColorBlindHelper {
  static const colorSymbols = {
    'red': '▲',
    'green': '●',
    'blue': '■',
    'yellow': '★',
    'orange': '♦',
    'purple': '♥',
    'pink': '♠',
  };

  static const colorPatterns = {
    'red': '░░░░',
    'green': '▓▓▓▓',
    'blue': '████',
    'yellow': '▪▪▪▪',
  };

  static ColorFilter? getFilter(ColorBlindnessType type) {
    switch (type) {
      case ColorBlindnessType.protanopia:
        return const ColorFilter.matrix([
          0.567, 0.433, 0, 0, 0,
          0.558, 0.442, 0, 0, 0,
          0, 0.242, 0.758, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessType.deuteranopia:
        return const ColorFilter.matrix([
          0.625, 0.375, 0, 0, 0,
          0.7, 0.3, 0, 0, 0,
          0, 0.3, 0.7, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessType.tritanopia:
        return const ColorFilter.matrix([
          0.95, 0.05, 0, 0, 0,
          0, 0.433, 0.567, 0, 0,
          0, 0.475, 0.525, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessType.none:
        return null;
    }
  }
}

/// زر بلون + رمز (للتمييز بدون رؤية اللون)
class AccessibleColorButton extends StatelessWidget {
  final String colorName;
  final Color color;
  final VoidCallback onTap;
  final bool selected;

  const AccessibleColorButton({
    super.key,
    required this.colorName,
    required this.color,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = ColorBlindHelper.colorSymbols[colorName] ?? '●';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              symbol,
              style: const TextStyle(
                fontSize: 40,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              colorName,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
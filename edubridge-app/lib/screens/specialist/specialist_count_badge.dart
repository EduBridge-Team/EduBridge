// Count badge displayed in specialist child filters.
part of 'specialist_screen.dart';

class _CountBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _CountBadge(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: c.body,
        ),
      ),
    );
  }
}

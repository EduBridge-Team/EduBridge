// lib/screens/ministry/ministry_tab_bar.dart
part of 'ministry_screen.dart';

class _MinistryTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _MinistryTabBar({required this.index, required this.onChanged});


  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final tabs = [
      (AppIcons.report, context.l10n.overview),
      (AppIcons.upload, context.l10n.requests),
      (AppIcons.users, context.l10n.users),
      (AppIcons.lesson, context.l10n.curricula),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == index;
          final (icon, label) = tabs[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: active ? AppColors.brandBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: active ? Colors.white : c.muted),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : c.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
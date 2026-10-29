// Shared EduBridge app bar.
part of 'theme.dart';

class JisrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const JisrAppBar({super.key, required this.title, this.actions, this.leading});

  @override
  Size get preferredSize => const Size.fromHeight(BrandAppBar.standardToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BrandAppBar(
      leading: leading,
      titleSpacing: 16,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions == null
          ? null
          : [
              ...actions!,
              const SizedBox(width: 12),
            ],
    );
  }
}

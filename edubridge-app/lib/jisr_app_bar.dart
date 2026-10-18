// Shared EduBridge app bar.
part of 'theme.dart';

class JisrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const JisrAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return BrandAppBar(
      toolbarHeight: 100,
      titleSpacing: 4,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: actions,
    );
  }
}

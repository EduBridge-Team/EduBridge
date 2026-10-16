// Shared EduBridge app bar.
part of 'theme.dart';

class JisrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const JisrAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return BrandAppBar(
      toolbarHeight: 72,
      titleSpacing: 18,
      title: Text(title),
      actions: actions,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
    );
  }
}

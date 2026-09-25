// Shared EduBridge app bar.
part of 'theme.dart';

class JisrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const JisrAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      ),
    );
  }
}

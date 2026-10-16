part of 'theme.dart';

/// One background for every toolbar; navigation and actions stay with callers.
class BrandAppBar extends AppBar {
  BrandAppBar({
    super.key,
    super.title,
    super.actions,
    super.leading,
    super.leadingWidth,
    super.centerTitle,
    super.titleSpacing,
    super.toolbarHeight,
    super.elevation,
    super.shape,
  }) : super(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          clipBehavior: Clip.antiAlias,
          flexibleSpace: const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.appBarGradient),
          ),
        );
}

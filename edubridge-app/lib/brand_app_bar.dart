part of 'theme.dart';

/// Specialist header surface shared by all roles, games and detail screens.
class BrandHeaderSurface extends StatelessWidget {
  const BrandHeaderSurface({super.key, this.child});

  final Widget? child;
  static const radius = BorderRadius.vertical(bottom: Radius.circular(28));

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: radius,
    child: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
      child: Stack(
        fit: child == null ? StackFit.expand : StackFit.passthrough,
        children: [
          Positioned(left: -56, bottom: -92, child: IgnorePointer(
            child: Container(width: 190, height: 170,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .19), width: 17))))),
          Positioned(left: -30, bottom: -94, child: IgnorePointer(
            child: Container(width: 138, height: 142,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .17), width: 14))))),
          if (child != null) child!,
        ],
      ),
    ),
  );
}

/// Shared dashboard surface, including legacy headers rendered in page bodies.
class BrandDashboardHeader extends StatelessWidget {
  const BrandDashboardHeader({super.key, required this.child, this.safeTop = true});
  final Widget child;
  final bool safeTop;

  @override
  Widget build(BuildContext context) => BrandHeaderSurface(
    child: SafeArea(top: safeTop, bottom: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: BrandAppBar.standardToolbarHeight),
        child: Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Align(alignment: Alignment.bottomCenter, child: child)),
      ),
    ),
  );
}

/// Brand toolbar with its title and controls aligned to the profile's bottom row.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const standardToolbarHeight = 124.0;
  static const controlBottomInset = 20.0;

  BrandAppBar({super.key, this.title, this.actions, this.leading,
    this.leadingWidth, this.centerTitle = false, this.titleSpacing = 4,
    double toolbarHeight = standardToolbarHeight, this.elevation = 0,
    ShapeBorder? shape,
  }) : toolbarHeight = toolbarHeight < standardToolbarHeight
          ? standardToolbarHeight : toolbarHeight,
       shape = shape ?? const RoundedRectangleBorder(borderRadius: BrandHeaderSurface.radius);

  final Widget? title, leading;
  final List<Widget>? actions;
  final double? leadingWidth;
  final bool centerTitle;
  final double titleSpacing, toolbarHeight, elevation;
  final ShapeBorder shape;
  Color get backgroundColor => AppColors.brandBlue;
  Color get foregroundColor => Colors.white;
  double get scrolledUnderElevation => 0;
  Clip get clipBehavior => Clip.antiAlias;
  Widget get flexibleSpace => const BrandHeaderSurface();
  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    final route = ModalRoute.of(context);
    Widget? navigation = leading;
    if (navigation == null) {
      if (scaffold?.hasDrawer == true) {
        navigation = const DrawerButton();
      } else if (route?.impliesAppBarDismissal == true) {
        navigation = route is PageRoute && route.fullscreenDialog
            ? const CloseButton() : const BackButton();
      }
    }
    final trailing = actions?.isNotEmpty == true ? actions
        : scaffold?.hasEndDrawer == true ? <Widget>[const EndDrawerButton()] : null;
    return AppBar(
      automaticallyImplyLeading: false,
      leading: navigation == null ? null : _BrandToolbarSlot(child: navigation),
      leadingWidth: leadingWidth,
      title: title == null ? null : _BrandToolbarSlot(child: title!),
      actions: trailing?.map((action) => _BrandToolbarSlot(child: action)).toList(),
      centerTitle: centerTitle, titleSpacing: titleSpacing,
      toolbarHeight: toolbarHeight, elevation: elevation,
      backgroundColor: backgroundColor, foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent, scrolledUnderElevation: scrolledUnderElevation,
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
      shape: shape, clipBehavior: clipBehavior, flexibleSpace: flexibleSpace,
    );
  }
}

class _BrandToolbarSlot extends StatelessWidget {
  const _BrandToolbarSlot({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter, widthFactor: 1,
    child: Padding(padding: const EdgeInsets.only(bottom: BrandAppBar.controlBottomInset),
      child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 48),
        child: Center(widthFactor: 1, heightFactor: 1, child: child))),
  );
}

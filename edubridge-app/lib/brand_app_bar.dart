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

/// A solid brand fallback keeps white controls visible beneath the gradient.
class BrandAppBar extends AppBar {
  BrandAppBar({
    super.key,
    super.title,
    super.actions,
    super.leading,
    super.leadingWidth,
    super.centerTitle = false,
    super.titleSpacing = 4,
    super.toolbarHeight = 100,
    super.elevation = 0,
    ShapeBorder? shape,
  }) : super(
          backgroundColor: AppColors.brandBlue,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: Colors.white),
          shape: shape ?? const RoundedRectangleBorder(borderRadius: BrandHeaderSurface.radius),
          clipBehavior: Clip.antiAlias,
          flexibleSpace: const BrandHeaderSurface(),
        );
}

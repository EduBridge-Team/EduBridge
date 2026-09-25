part of 'pet_avatar.dart';

extension _PetAvatarStateView on _PetAvatarState {
  Widget buildView(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Semantics(
      label: 'نور، المساعد الذكي',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final phase = reduceMotion ? 0.0 : _controller.value;
          final bob =
              reduceMotion ? 0.0 : math.sin(phase * math.pi * 2) * 2.8;
          return Transform.translate(
            offset: Offset(0, bob),
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _NoorPainter(phase: phase),
            ),
          );
        },
      ),
    );
  
  }
}

part of 'welcome_screen.dart';

extension _WelcomeMotion on _WelcomeScreenState {
  Widget _motion(double delay, Widget child, {bool active = true}) {
    if (_reduceMotion || !active) return child;
    return AnimatedBuilder(
      animation: _entrance,
      child: child,
      builder: (_, content) {
        final progress = Curves.easeOutCubic.transform(
          ((_entrance.value - delay) / (1 - delay)).clamp(0.0, 1.0));
        return Opacity(opacity: progress, child: Transform.translate(
          offset: Offset(0, 16 * (1 - progress)), child: content));
      },
    );
  }

  // Each item has its own entrance, phase and direction. Sharing a clock
  // avoids extra tickers while the artwork elements move independently.
  Widget _artMotion(int page, int order, Widget child, {
    double horizontal = 0, double vertical = 3, bool pulse = false,
  }) {
    if (_reduceMotion || page != _page) return child;
    return _motion(order * .07, AnimatedBuilder(
      animation: _float,
      child: child,
      builder: (_, content) {
        final angle = _float.value * math.pi * 2 + order * 1.3;
        return Transform.translate(
          offset: Offset(math.cos(angle) * horizontal, math.sin(angle) * vertical),
          child: Transform.scale(scale: pulse ? 1 + math.sin(angle) * .012 : 1,
            child: content),
        );
      },
    ));
  }
}

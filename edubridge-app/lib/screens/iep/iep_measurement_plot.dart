import 'package:flutter/material.dart';
import '../../model/iep/iep_measurement_series.dart';

class IepMeasurementPlot extends StatelessWidget {
  const IepMeasurementPlot({super.key, required this.series});
  final IepMeasurementSeries series;
  @override
  Widget build(BuildContext context) {
    final dates = MaterialLocalizations.of(context), points = series.plotted;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(height: 180, child: CustomPaint(
        painter: _MeasurementPainter(series, Theme.of(context).colorScheme.outlineVariant,
            Theme.of(context).colorScheme.onSurface))),
      Directionality(textDirection: TextDirection.ltr, child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(dates.formatMediumDate(points.first.observedOn))),
          const SizedBox(width: 12),
          Flexible(child: Text(dates.formatMediumDate(points.last.observedOn), textAlign: TextAlign.end)),
        ])),
    ]);
  }
}
class _MeasurementPainter extends CustomPainter {
  _MeasurementPainter(this.series, this.gridColor, this.dotColor);
  final IepMeasurementSeries series;
  final Color gridColor, dotColor;
  @override
  void paint(Canvas canvas, Size size) {
    const inset = 10.0;
    final width = size.width - 2 * inset, height = size.height - 2 * inset;
    if (width <= 0 || height <= 0) return;
    double y(num value) => inset + height * (1 - series.fraction(value));
    final grid = Paint()..color = gridColor..strokeWidth = 1;
    for (final part in [0.0, 0.5, 1.0]) {
      final dy = inset + height * part;
      canvas.drawLine(Offset(inset, dy), Offset(size.width - inset, dy), grid);
    }
    final baseline = Paint()..color = const Color(0xFF176BC1)..strokeWidth = 2;
    for (double dx = inset; dx < size.width - inset; dx += 12) {
      final end = (dx + 6).clamp(inset, size.width - inset).toDouble();
      canvas.drawLine(Offset(dx, y(series.baseline)), Offset(end, y(series.baseline)), baseline);
    }
    final target = Paint()..color = const Color(0xFF07989F)..strokeWidth = 2;
    canvas.drawLine(Offset(inset, y(series.target)), Offset(size.width - inset, y(series.target)), target);
    final dot = Paint()..color = dotColor;
    for (final entry in series.plotted) {
      canvas.drawCircle(Offset(inset + width * series.dateFraction(entry.observedOn),
          y(entry.measurement!)), 4, dot);
    }
  }
  @override
  bool shouldRepaint(covariant _MeasurementPainter oldDelegate) =>
      oldDelegate.series != series || oldDelegate.gridColor != gridColor || oldDelegate.dotColor != dotColor;
}


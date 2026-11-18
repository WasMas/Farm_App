import 'package:material_ui/material_ui.dart';

import '../../../core/theme.dart';

/// A small landscape drawn from field boundaries and olive branches.
class FieldSketch extends CustomPainter {
  const FieldSketch();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 300, size.height / 180);
    final line = Paint()
      ..color = FarmColors.paper.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(
      const Offset(240, 35),
      19,
      Paint()..color = FarmColors.wheat,
    );
    final hill = Path()
      ..moveTo(0, 105)
      ..cubicTo(80, 40, 135, 62, 195, 91)
      ..cubicTo(235, 110, 265, 67, 300, 80);
    canvas.drawPath(hill, line);
    for (var i = 0; i < 8; i++) {
      final y = 103.0 + i * 10;
      canvas.drawPath(
        Path()
          ..moveTo(0, y)
          ..cubicTo(90, y - 35, 180, y - 8, 300, y + 9),
        line,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(90, 78)
        ..lineTo(132, 180)
        ..moveTo(182, 86)
        ..lineTo(252, 180),
      line,
    );
    final branch = Paint()
      ..color = FarmColors.wheat
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(45, 115)
        ..quadraticBezierTo(47, 80, 64, 48)
        ..moveTo(52, 82)
        ..lineTo(35, 63)
        ..moveTo(58, 65)
        ..lineTo(78, 49),
      branch,
    );
    final leaf = Paint()..color = FarmColors.wheat;
    for (final point in [
      const Offset(34, 61),
      const Offset(43, 72),
      const Offset(59, 59),
      const Offset(65, 45),
      const Offset(77, 48),
      const Offset(50, 92),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: point, width: 8, height: 15),
        leaf,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FieldSketch oldDelegate) => false;
}

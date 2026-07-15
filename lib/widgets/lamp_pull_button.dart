import 'package:flutter/material.dart';

class LampPullButton extends StatefulWidget {
  final VoidCallback onPulled;
  final String tooltip;
  final Color shadeTop;
  final Color shadeBottom;
  final Color accentColor;
  const LampPullButton({
    super.key,
    required this.onPulled,
    this.tooltip = 'بوابة الموظفين — اسحب لتسجيل الدخول',
    this.shadeTop = const Color(0xFFFFFDF5),
    this.shadeBottom = const Color(0xFFFDE9C8),
    this.accentColor = const Color(0xFFF59E0B),
  });

  @override
  State<LampPullButton> createState() => _LampPullButtonState();
}

class _LampPullButtonState extends State<LampPullButton> with SingleTickerProviderStateMixin {
  static const double _restLength = 9;
  static const double _maxPull = 18;
  static const double _triggerThreshold = 12;

  late final AnimationController _springCtrl;
  double _dragExtra = 0;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dragExtra = (_dragExtra + d.delta.dy).clamp(0, _maxPull));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragExtra >= _triggerThreshold) {
      setState(() => _dragExtra = 0);
      widget.onPulled();
      return;
    }
    _springBack();
  }

  void _springBack() {
    final start = _dragExtra;
    _springCtrl.reset();
    void listener() {
      if (!mounted) return;
      final raw = start * (1 - Curves.elasticOut.transform(_springCtrl.value));
      setState(() => _dragExtra = raw.clamp(0, _maxPull));
    }
    _springCtrl.addListener(listener);
    _springCtrl.forward().whenComplete(() {
      if (!mounted) return;
      _springCtrl.removeListener(listener);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cordLength = _restLength + _dragExtra;
    final lit = _hovered || _dragExtra > 0;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPulled,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 15,
                  child: CustomPaint(
                    painter: _LampShadePainter(
                      lit: lit,
                      shadeTop: widget.shadeTop,
                      shadeBottom: widget.shadeBottom,
                      accentColor: widget.accentColor,
                    ),
                  ),
                ),
                Container(
                  width: 1.4,
                  height: cordLength,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(widget.accentColor, Colors.white, 0.45)!,
                        widget.accentColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(color: widget.accentColor.withValues(alpha: 0.55), blurRadius: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LampShadePainter extends CustomPainter {
  final bool lit;
  final Color shadeTop;
  final Color shadeBottom;
  final Color accentColor;
  const _LampShadePainter({
    required this.lit,
    required this.shadeTop,
    required this.shadeBottom,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    if (lit) {
      canvas.drawCircle(
        Offset(w / 2, h * 0.9),
        w * 0.9,
        Paint()
          ..shader = RadialGradient(
            colors: [accentColor.withValues(alpha: 0.4), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(w / 2, h * 0.9), radius: w * 0.9)),
      );
    }

    final shadePath = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.5, h * 0.1, w * 0.05, h * 0.3, w * 0.02, h * 0.75)
      ..quadraticBezierTo(w * 0.5, h * 1.05, w * 0.98, h * 0.75)
      ..cubicTo(w * 0.95, h * 0.3, w * 0.5, h * 0.1, w * 0.5, 0)
      ..close();
    canvas.drawPath(
      shadePath,
      Paint()
        ..shader = LinearGradient(
          colors: [shadeTop, shadeBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawCircle(
      Offset(w / 2, h * 0.62),
      w * 0.09,
      Paint()..color = lit ? Color.lerp(shadeTop, accentColor, 0.15)! : shadeBottom.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _LampShadePainter oldDelegate) =>
      oldDelegate.lit != lit ||
      oldDelegate.shadeTop != shadeTop ||
      oldDelegate.shadeBottom != shadeBottom ||
      oldDelegate.accentColor != accentColor;
}

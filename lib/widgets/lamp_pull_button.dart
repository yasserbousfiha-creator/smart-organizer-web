import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// زر "بوابة الموظفين" الجديد — لمبة صغيرة بحبل قابل للسحب. اسحب الحبل
/// للأسفل (أو اضغط) باش تفتح نافذة تسجيل الدخول، بدل زر نصّي عادي.
class LampPullButton extends StatefulWidget {
  final VoidCallback onPulled;
  final double shadeSize;
  const LampPullButton({super.key, required this.onPulled, this.shadeSize = 30});

  @override
  State<LampPullButton> createState() => _LampPullButtonState();
}

class _LampPullButtonState extends State<LampPullButton> with SingleTickerProviderStateMixin {
  static const double _restLength = 12;
  static const double _maxPull = 26;
  static const double _triggerThreshold = 18;

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
      _springBack();
      widget.onPulled();
      return;
    }
    _springBack();
  }

  void _springBack() {
    final start = _dragExtra;
    _springCtrl.reset();
    void listener() => _springTick(start);
    _springCtrl.addListener(listener);
    _springCtrl.forward().whenComplete(() => _springCtrl.removeListener(listener));
  }

  void _springTick(double start) {
    if (!mounted) return;
    setState(() => _dragExtra = start * (1 - Curves.elasticOut.transform(_springCtrl.value)));
  }

  @override
  Widget build(BuildContext context) {
    final cordLength = _restLength + _dragExtra;
    return Tooltip(
      message: 'اسحب لتسجيل الدخول',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPulled,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: SizedBox(
            width: widget.shadeSize + 10,
            height: widget.shadeSize * 0.7 + _maxPull + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: widget.shadeSize,
                  height: widget.shadeSize * 0.62,
                  child: CustomPaint(
                    painter: _LampShadePainter(lit: _hovered || _dragExtra > 0),
                  ),
                ),
                Container(
                  width: 1.5,
                  height: cordLength,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.5), blurRadius: 6),
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
  const _LampShadePainter({required this.lit});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    if (lit) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [AppColors.primaryLight.withValues(alpha: 0.5), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, h * 0.85), radius: w * 0.9));
      canvas.drawCircle(Offset(w / 2, h * 0.85), w * 0.9, glowPaint);
    }

    final shadePath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.12, h * 0.55)
      ..quadraticBezierTo(w * 0.5, h * 0.78, w * 0.88, h * 0.55)
      ..close();
    final shadePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDF5), Color(0xFFFDE9C8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shadePath, shadePaint);

    final bulbPaint = Paint()..color = lit ? const Color(0xFFFFF7E0) : const Color(0xFFE7DFC8);
    canvas.drawCircle(Offset(w / 2, h * 0.62), w * 0.07, bulbPaint);
  }

  @override
  bool shouldRepaint(covariant _LampShadePainter oldDelegate) => oldDelegate.lit != lit;
}

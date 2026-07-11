import 'package:flutter/material.dart';

/// مصباح طاولة كبير وأنيق بحبل قابل للسحب — اسحب الحبل للأسفل باش
/// "يضوي" المصباح ويكشف بقية المحتوى (بوابة الموظفين، شاشة moon abaya).
class TableLamp extends StatefulWidget {
  final VoidCallback onPulled;
  final double size;
  final Color shadeColorTop;
  final Color shadeColorBottom;
  final Color accentColor;
  const TableLamp({
    super.key,
    required this.onPulled,
    this.size = 220,
    this.shadeColorTop = const Color(0xFFFFFDF5),
    this.shadeColorBottom = const Color(0xFFF3DFB3),
    this.accentColor = const Color(0xFFF59E0B),
  });

  @override
  State<TableLamp> createState() => _TableLampState();
}

class _TableLampState extends State<TableLamp> with TickerProviderStateMixin {
  static const double _restLength = 36;
  static const double _maxPull = 72;
  static const double _triggerThreshold = 50;

  late final AnimationController _springCtrl;
  late final AnimationController _idleCtrl;
  double _dragExtra = 0;
  bool _hovered = false;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _springCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    // نبضة توهّج هادئة ومستمرة تدي للمصباح إحساس "حيّ" حتى قبل التفاعل معاه.
    _idleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _springCtrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_triggered) return;
    setState(() => _dragExtra = (_dragExtra + d.delta.dy).clamp(0, _maxPull));
  }

  void _onDragEnd(DragEndDetails d) {
    if (_triggered) return;
    if (_dragExtra >= _triggerThreshold) {
      setState(() => _triggered = true);
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
      // Curves.elasticOut كتفوت 1.0 مؤقتاً (ارتداد زنبركي)، فكنقصو
      // النتيجة بين 0 و_maxPull باش الحبل ما يبانش سالب.
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
    final s = widget.size;
    final domeW = s * 0.72;
    final domeH = s * 0.46;
    final poleH = s * 0.4;
    final baseW = s * 0.46;
    final lit = _hovered || _dragExtra > 0 || _triggered;
    final cordLength = _restLength + _dragExtra;

    return SizedBox(
      width: s,
      height: domeH + poleH + s * 0.14 + cordLength + 34,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _idleCtrl,
                builder: (context, _) => SizedBox(
                  width: domeW,
                  height: domeH,
                  child: CustomPaint(
                    painter: _DomePainter(
                      lit: lit,
                      top: widget.shadeColorTop,
                      bottom: widget.shadeColorBottom,
                      idlePulse: _idleCtrl.value,
                    ),
                  ),
                ),
              ),
              Container(
                width: s * 0.05,
                height: poleH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
              // قاعدة بطبقتين: منصة صغيرة فوق قاعدة أعرض
              SizedBox(
                width: baseW * 0.6,
                height: s * 0.035,
                child: CustomPaint(painter: _BasePainter()),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: baseW,
                height: s * 0.075,
                child: CustomPaint(painter: _BasePainter()),
              ),
              const SizedBox(height: 8),
              Container(
                width: baseW * 1.35,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(
                    colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: domeH * 0.74,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _triggered ? null : () { setState(() => _triggered = true); widget.onPulled(); },
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 2,
                        height: cordLength,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      // حلقة صغيرة فوق الكرة — تفصيل واقعي لسلسلة السحب
                      Container(
                        width: 9,
                        height: 9,
                        margin: const EdgeInsets.only(bottom: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.4),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.lerp(widget.accentColor, Colors.white, 0.4)!,
                              widget.accentColor,
                            ],
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.2),
                          boxShadow: [
                            BoxShadow(color: widget.accentColor.withValues(alpha: 0.6), blurRadius: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DomePainter extends CustomPainter {
  final bool lit;
  final Color top;
  final Color bottom;
  final double idlePulse;
  const _DomePainter({
    required this.lit,
    required this.top,
    required this.bottom,
    this.idlePulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // توهّج خافت ونابض حتى فحالة السكون، يقوى أكثر لما يكون "مضاوي".
    final ambientAlpha = 0.12 + (idlePulse * 0.08);
    final ambientGlow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: ambientAlpha), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(w / 2, h * 0.88), radius: w * 1.3));
    canvas.drawCircle(Offset(w / 2, h * 0.88), w * 1.3, ambientGlow);

    if (lit) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.5), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(w / 2, h * 0.88), radius: w * 1.15));
      canvas.drawCircle(Offset(w / 2, h * 0.88), w * 1.15, glowPaint);
    }

    // قبة ناعمة بمنحنيات دائرية بدل الزوايا الحادة
    final shadePath = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.5, h * 0.06, w * 0.1, h * 0.28, w * 0.04, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.88, w * 0.96, h * 0.62)
      ..cubicTo(w * 0.9, h * 0.28, w * 0.5, h * 0.06, w * 0.5, 0)
      ..close();
    final shadePaint = Paint()
      ..shader = LinearGradient(
        colors: [top, bottom],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shadePath, shadePaint);

    // إضاءة خفيفة على حافة القبة
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawPath(shadePath, rimPaint);

    final bulbPaint = Paint()..color = lit ? const Color(0xFFFFF7E0) : const Color(0xFFDDD4BC);
    canvas.drawCircle(Offset(w / 2, h * 0.72), w * 0.075, bulbPaint);
  }

  @override
  bool shouldRepaint(covariant _DomePainter oldDelegate) =>
      oldDelegate.lit != lit ||
      oldDelegate.top != top ||
      oldDelegate.bottom != bottom ||
      oldDelegate.idlePulse != idlePulse;
}

class _BasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFEFEAE0), Color(0xFFC9C0AC)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(h / 2));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

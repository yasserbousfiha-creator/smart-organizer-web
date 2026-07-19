import 'package:flutter/material.dart';
import '../state/visit_counter.dart';
import '../theme/app_colors.dart';

class VisitorCounterBadge extends StatefulWidget {
  final bool isEnglish;
  const VisitorCounterBadge({super.key, this.isEnglish = false});

  @override
  State<VisitorCounterBadge> createState() => _VisitorCounterBadgeState();
}

class _VisitorCounterBadgeState extends State<VisitorCounterBadge> {
  int? _count;

  @override
  void initState() {
    super.initState();
    logVisitAndGetCount().then((count) {
      if (!mounted || count == null) return;
      setState(() => _count = count);
    });
  }

  String _label(int count) {
    if (widget.isEnglish) {
      if (count == 0) return 'Be the first to join us!';
      if (count == 1) return '1 visitor joined us';
      if (count <= 10) return '$count visitors joined us';
      final rounded = (count ~/ 10) * 10;
      return 'More than $rounded people joined us';
    }
    if (count == 0) return 'كن أول من ينضمّ إلينا!';
    if (count == 1) return 'زائر واحد انضمّ إلينا';
    if (count == 2) return 'زائران انضمّا إلينا';
    if (count <= 10) return '$count زوار انضمّوا إلينا';
    final rounded = (count ~/ 10) * 10;
    return 'أكثر من $rounded زائر انضمّوا إلينا';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _count != null ? 1 : 0,
      child: _count == null
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_rounded, size: 14, color: AppColors.primaryLight),
                  const SizedBox(width: 7),
                  Text(
                    _label(_count!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

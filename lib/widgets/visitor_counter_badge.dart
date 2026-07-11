import 'package:flutter/material.dart';
import '../state/visit_counter.dart';
import '../theme/app_colors.dart';

/// شارة صغيرة كتبان بعد ما توصل عدد الزوار الحقيقي (المخزّن فـSupabase)
/// لعتبة معقولة — باش الموقع الجديد ما يبانش فيه "أكثر من 0 زائر".
class VisitorCounterBadge extends StatefulWidget {
  const VisitorCounterBadge({super.key});

  @override
  State<VisitorCounterBadge> createState() => _VisitorCounterBadgeState();
}

class _VisitorCounterBadgeState extends State<VisitorCounterBadge> {
  int? _rounded;

  @override
  void initState() {
    super.initState();
    logVisitAndGetCount().then((count) {
      if (!mounted || count == null) return;
      final rounded = (count ~/ 10) * 10;
      if (rounded >= 10) setState(() => _rounded = rounded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _rounded != null ? 1 : 0,
      child: _rounded == null
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
                    'انضمّ إلينا أكثر من $_rounded زائر',
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

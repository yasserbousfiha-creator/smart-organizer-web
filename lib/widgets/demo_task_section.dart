import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// قسم تفاعلي فالصفحة الرئيسية — يخلي الزائر يجرّب "تنظيم مهمة" مباشرة
/// بلا تسجيل دخول، باش يحس بفايدة التطبيق بدل ما يقرا وصفها بس.
class DemoTaskSection extends StatefulWidget {
  const DemoTaskSection({super.key});

  @override
  State<DemoTaskSection> createState() => _DemoTaskSectionState();
}

class _DemoTask {
  final int id;
  final String text;
  final String tag;
  final Color tagColor;
  bool done = false;
  _DemoTask({
    required this.id,
    required this.text,
    required this.tag,
    required this.tagColor,
  });
}

class _DemoTaskSectionState extends State<DemoTaskSection> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  int _nextId = 3;
  bool _organizing = false;

  static const _tagOptions = [
    ('🔥 عاجل', Color(0xFFF87171)),
    ('📅 اليوم', Color(0xFF60A5FA)),
    ('⭐ مهم', Color(0xFFFBBF24)),
    ('💡 فكرة', Color(0xFFA78BFA)),
    ('✅ سهل', Color(0xFF34D399)),
  ];

  late final List<_DemoTask> _tasks = [
    _DemoTask(id: 1, text: 'تصميم عرض تقديمي للاجتماع', tag: '⭐ مهم', tagColor: const Color(0xFFFBBF24)),
    _DemoTask(id: 2, text: 'اجتماع الفريق الساعة 5', tag: '📅 اليوم', tagColor: const Color(0xFF60A5FA)),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addTask() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _organizing) return;
    _ctrl.clear();
    setState(() => _organizing = true);
    // تأخير بسيط كيدي إحساس "كنرتّبو ليك المهمة تلقائياً" بدل ما تبان دغيا.
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    final choice = _tagOptions[math.Random().nextInt(_tagOptions.length)];
    setState(() {
      _tasks.insert(0, _DemoTask(id: _nextId++, text: text, tag: choice.$1, tagColor: choice.$2));
      _organizing = false;
    });
    _focusNode.requestFocus();
  }

  void _toggle(int id) {
    setState(() {
      final t = _tasks.firstWhere((t) => t.id == id);
      t.done = !t.done;
    });
  }

  void _remove(int id) {
    setState(() => _tasks.removeWhere((t) => t.id == id));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 70 : 100, horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primaryLight),
                const SizedBox(width: 6),
                Text(
                  'تجربة تفاعلية',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'جرّب التنظيم الذكي بنفسك',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'اكتب أي مهمة تخطر ببالك وشوف كيفاش كنرتبوها ليك تلقائياً — بلا تسجيل دخول.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.55), height: 1.6),
          ),
          const SizedBox(height: 44),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        onSubmitted: (_) => _addTask(),
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'مثلاً: تحضير التقرير الشهري...',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _addTask,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _organizing
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.add_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'لا توجد مهام بعد — جرّب تضيف وحدة 👆',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
                    ),
                  )
                else
                  Column(
                    children: _tasks
                        .map((t) => Padding(
                              key: ValueKey(t.id),
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _DemoTaskTile(
                                task: t,
                                onToggle: () => _toggle(t.id),
                                onRemove: () => _remove(t.id),
                              ),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoTaskTile extends StatelessWidget {
  final _DemoTask task;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  const _DemoTaskTile({required this.task, required this.onToggle, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.done ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: task.done ? AppColors.primary : Colors.white.withValues(alpha: 0.3),
                      width: 1.6,
                    ),
                  ),
                  child: task.done ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.text,
                style: TextStyle(
                  fontSize: 13.5,
                  color: task.done ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.9),
                  decoration: task.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: task.tagColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(task.tag, style: TextStyle(fontSize: 11, color: task.tagColor, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 6),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded, size: 15, color: Colors.white.withValues(alpha: 0.25)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

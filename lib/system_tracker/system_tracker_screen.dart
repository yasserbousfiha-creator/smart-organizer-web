import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import 'system_celebration.dart';
import 'system_task_storage.dart';

/// Short, written form-guidance for each exercise — shown via an info
/// button instead of a photo/video demo (no image or video capability
/// available to generate real media).
const Map<String, String> _kFormTips = {
  '100 Sit-ups':
      'Lie on your back, knees bent, feet flat on the floor. Cross your arms '
      'over your chest, then lift your torso toward your knees using your '
      'abs — not your neck. Lower back down with control and repeat.',
  '100 Push-ups':
      'Hands shoulder-width apart, body in a straight line from head to '
      'heels. Bend your elbows at about 45° to lower your chest toward the '
      'floor, then push back up until your arms are fully extended.',
  '5 km Running':
      'Relaxed upright posture, land mid-foot under your hips, short quick '
      'strides, steady breathing. Warm up with a 5-minute brisk walk first.',
  '5 km Walking':
      'Brisk pace, arms swinging naturally, shoulders relaxed, heel-to-toe '
      'steps. Keep a steady breathing rhythm and stay hydrated.',
};

/// Cloud-synced (Supabase) daily system tracker for Soufiane — entirely in
/// English. Each task type has its own interaction: rep/km/ml counters with
/// step buttons, an expandable 5-prayer checklist, and simple on/off custom
/// tasks. Completing any task shows a celebration overlay.
class SystemTrackerScreen extends StatefulWidget {
  const SystemTrackerScreen({super.key});

  @override
  State<SystemTrackerScreen> createState() => _SystemTrackerScreenState();
}

class _SystemTrackerScreenState extends State<SystemTrackerScreen> {
  List<SystemTask> _tasks = [];
  bool _loading = true;
  bool _celebrationOpen = false;
  bool _addingTask = false;
  String? _error;
  RealtimeChannel? _channel;
  final _newTaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await SystemTaskStorage.fetchToday();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
      _channel = SystemTaskStorage.subscribeToday(_refresh);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not reach the cloud:\n$e';
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final tasks = await SystemTaskStorage.fetchToday();
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (_) {
      // silently ignore — the next successful sync will fix the view
    }
  }

  void _applyUpdate(SystemTask updated) {
    if (!mounted) return;
    setState(() {
      _tasks = [for (final t in _tasks) if (t.id == updated.id) updated else t];
    });
  }

  void _celebrate() {
    if (_celebrationOpen) return;
    _celebrationOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SystemCelebrationOverlay(
        onClose: () => Navigator.of(context).pop(),
      ),
    ).then((_) => _celebrationOpen = false);
  }

  Future<void> _toggleSimple(SystemTask task, bool value) async {
    final updated = await SystemTaskStorage.setDone(task.id, value);
    _applyUpdate(updated);
    if (value) _celebrate();
  }

  Future<void> _adjust(SystemTask task, double delta) async {
    final target = task.target ?? 1;
    final wasDone = task.done;
    final updated = await SystemTaskStorage.setProgress(task.id, task.progress + delta, target);
    _applyUpdate(updated);
    if (!wasDone && updated.done) _celebrate();
  }

  Future<void> _toggleSubPrayer(SystemTask task, String key, bool value) async {
    final wasDone = task.done;
    final updated = await SystemTaskStorage.setSubPrayer(task.id, task.subStatus ?? {}, key, value);
    _applyUpdate(updated);
    if (!wasDone && updated.done) _celebrate();
  }

  Future<void> _addTask() async {
    final title = _newTaskController.text.trim();
    if (title.isEmpty || _addingTask) return;
    setState(() => _addingTask = true);
    try {
      await SystemTaskStorage.addCustomTask(title);
      _newTaskController.clear();
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add task: $e')),
      );
    } finally {
      if (mounted) setState(() => _addingTask = false);
    }
  }

  Future<void> _editTask(SystemTask task) async {
    final controller = TextEditingController(text: task.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit task', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Task name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newTitle == null || newTitle.isEmpty || newTitle == task.title) return;
    final updated = await SystemTaskStorage.renameTask(task.id, newTitle);
    _applyUpdate(updated);
  }

  Future<void> _deleteTask(SystemTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete task?', style: TextStyle(color: Colors.white)),
        content: Text('Remove "${task.title}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await SystemTaskStorage.deleteTask(task.id);
    if (!mounted) return;
    setState(() => _tasks = _tasks.where((t) => t.id != task.id).toList());
  }

  void _showTip(String title, String tip) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(tip, style: const TextStyle(color: Colors.white70, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _newTaskController.dispose();
    super.dispose();
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _formatToday() {
    final now = DateTime.now();
    return '${_months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Widget _buildDailyHeader() {
    final total = _tasks.length;
    final done = _tasks.where((t) => t.done).length;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatToday(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text('$done / $total tasks done today', style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  strokeWidth: 5,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
                Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Track Your Daily System'),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset('assets/system/soufiane.jpg', fit: BoxFit.cover),
              ),
            ),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _load,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildDailyHeader(),
                      const SizedBox(height: 20),
                      ..._tasks.map(_buildTile),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newTaskController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Add a custom task (e.g. Swimming)',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _addTask(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filled(
                            onPressed: _addingTask ? null : _addTask,
                            style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                            icon: const Icon(Icons.add_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(SystemTask task) {
    switch (task.kind) {
      case 'prayers':
        return _buildPrayersTile(task);
      case 'counter':
        return task.unit == 'ml' ? _buildWaterTile(task) : _buildCounterTile(task);
      default:
        return _buildSimpleTile(task);
    }
  }

  Widget _stepButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.white10 : AppColors.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.white24 : AppColors.primary),
      ),
    );
  }

  Widget _cardShell({required bool done, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? AppColors.primary : Colors.white12),
      ),
      child: child,
    );
  }

  Widget _buildCounterTile(SystemTask task) {
    final target = task.target ?? 1;
    final step = task.step ?? 1;
    final ratio = (task.progress / target).clamp(0.0, 1.0);
    final tip = _kFormTips[task.title];
    return _cardShell(
      done: task.done,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                task.done ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: task.done ? AppColors.primary : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              if (tip != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 20),
                  onPressed: () => _showTip(task.title, tip),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${_fmt(task.progress)} / ${_fmt(target)} ${task.unit}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              _stepButton(icon: Icons.remove_rounded, onTap: task.progress > 0 ? () => _adjust(task, -step) : null),
              const SizedBox(width: 8),
              _stepButton(icon: Icons.add_rounded, onTap: () => _adjust(task, step)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTile(SystemTask task) {
    final target = task.target ?? 3000;
    final step = task.step ?? 300;
    final cupsTotal = (target / step).round();
    final cupsFilled = (task.progress / step).round();
    return _cardShell(
      done: task.done,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                task.done ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: task.done ? AppColors.primary : Colors.white38,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              Text('${_fmt(task.progress)} / ${_fmt(target)} ml', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(cupsTotal, (i) {
              final filled = i < cupsFilled;
              return Icon(Icons.local_cafe_rounded, size: 22, color: filled ? AppColors.primary : Colors.white24);
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _stepButton(icon: Icons.remove_rounded, onTap: task.progress > 0 ? () => _adjust(task, -step) : null),
              const SizedBox(width: 10),
              Text('+${_fmt(step)}ml a cup', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(width: 10),
              _stepButton(icon: Icons.add_rounded, onTap: () => _adjust(task, step)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayersTile(SystemTask task) {
    final sub = task.subStatus ?? {for (final k in kPrayerSubKeys) k: false};
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: task.done ? AppColors.primary : Colors.white12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white54,
          leading: Icon(
            task.done ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: task.done ? AppColors.primary : Colors.white38,
          ),
          title: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${task.progress.toInt()} / 5 completed',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          children: kPrayerSubKeys.map((key) {
            return SwitchListTile(
              value: sub[key] == true,
              onChanged: (v) => _toggleSubPrayer(task, key, v),
              activeThumbColor: AppColors.primary,
              title: Text(kPrayerSubLabels[key]!, style: const TextStyle(color: Colors.white70)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSimpleTile(SystemTask task) {
    return _cardShell(
      done: task.done,
      child: Row(
        children: [
          Expanded(
            child: Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          if (task.isCustom) ...[
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 18),
              onPressed: () => _editTask(task),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
              onPressed: () => _deleteTask(task),
            ),
            const SizedBox(width: 10),
          ],
          Switch(
            value: task.done,
            onChanged: (v) => _toggleSimple(task, v),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

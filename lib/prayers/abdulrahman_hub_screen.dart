import 'package:flutter/material.dart';

import '../entertainment/entertainment_hub_screen.dart';
import '../theme/app_colors.dart';
import 'english_quiz_screen.dart';
import 'prayer_storage.dart';
import 'prayer_tracker_screen.dart';
import 'religious_quiz_screen.dart';

/// Landing screen shown right after Abdulrahman's passcode is accepted —
/// lets him pick between the prayer tracker and the games section.
class AbdulrahmanHubScreen extends StatefulWidget {
  const AbdulrahmanHubScreen({super.key});

  @override
  State<AbdulrahmanHubScreen> createState() => _AbdulrahmanHubScreenState();
}

class _AbdulrahmanHubScreenState extends State<AbdulrahmanHubScreen> {
  PrayerChallengeRecord? _challenge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final challenge = await PrayerStorage.fetchCurrentChallenge();
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('مرحباً عبدالرحمن'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hubButton(
                    context,
                    icon: Icons.nightlight_round,
                    label: 'الصلوات',
                    subtitle: 'تتبع صلاتك واجمع النقاط',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrayerTrackerScreen()),
                    ).then((_) => _load()),
                  ),
                  const SizedBox(height: 16),
                  _hubButton(
                    context,
                    icon: Icons.menu_book_rounded,
                    label: 'أسئلة دينية',
                    subtitle: '5 أسئلة يوميا عن القرآن والسنة، تتغير كل يوم لمدة 15 يوم',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReligiousQuizScreen()),
                    ).then((_) => _load()),
                  ),
                  const SizedBox(height: 16),
                  _hubButton(
                    context,
                    icon: Icons.quiz_rounded,
                    label: 'أسئلة انجليزية',
                    subtitle: '5 أسئلة يوميا، كل جواب صحيح يزيد نقطتين لتحدي الصلاة',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EnglishQuizScreen()),
                    ).then((_) => _load()),
                  ),
                  const SizedBox(height: 16),
                  _hubButton(
                    context,
                    icon: Icons.sports_esports_rounded,
                    label: 'الترفيه',
                    subtitle: 'ألعاب صغيرة تلعبها وقت الفراغ',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EntertainmentHubScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPointsSummary(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsSummary() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final challenge = _challenge;
    if (challenge == null) return const SizedBox.shrink();

    final progress = (challenge.totalPoints / kChallengeGoalPoints).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تحدي 1000 نقطة',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
              ),
              Text(
                'متبقي ${challenge.daysRemaining} يوم',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                challenge.rewardReached ? Colors.greenAccent : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${challenge.totalPoints} / $kChallengeGoalPoints نقطة',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _hubButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../entertainment/entertainment_hub_screen.dart';
import '../theme/app_colors.dart';
import 'prayer_tracker_screen.dart';

/// Landing screen shown right after Abdulrahman's passcode is accepted —
/// lets him pick between the prayer tracker and the games section.
class AbdulrahmanHubScreen extends StatelessWidget {
  const AbdulrahmanHubScreen({super.key});

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
                    ),
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
                ],
              ),
            ),
          ),
        ),
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

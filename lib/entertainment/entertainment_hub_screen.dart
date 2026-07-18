import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'connect_four_screen.dart';
import 'count_to_21_screen.dart';
import 'rock_paper_scissors_screen.dart';
import 'tic_tac_toe_screen.dart';
import 'timing_game_screen.dart';

class EntertainmentHubScreen extends StatelessWidget {
  const EntertainmentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('الترفيه'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _gameTile(
              context,
              icon: Icons.close_rounded,
              label: 'إكس أو (X O)',
              subtitle: 'العب مع شخص آخر على نفس الجهاز',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TicTacToeScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _gameTile(
              context,
              icon: Icons.grid_4x4_rounded,
              label: 'اربح 4',
              subtitle: 'رصّوا 4 قطع متتالية قبل خصمكم',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectFourScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _gameTile(
              context,
              icon: Icons.front_hand_rounded,
              label: 'حجر ورقة مقص',
              subtitle: 'مرّروا الهاتف بينكم واختاروا بالسر',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RockPaperScissorsScreen()),
              ),
            ),
            const SizedBox(height: 14),
            _gameTile(
              context,
              icon: Icons.filter_3_rounded,
              label: 'لعبة 21',
              subtitle: 'أضيفوا 1 أو 2 أو 3، من يصل لـ21 يفوز',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CountTo21Screen()),
              ),
            ),
            const SizedBox(height: 14),
            _gameTile(
              context,
              icon: Icons.timer_outlined,
              label: 'لعبة تحديد الوقت',
              subtitle: 'حاول توقف الوقت في أقرب نقطة من الهدف',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TimingGameScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
          ],
        ),
      ),
    );
  }
}

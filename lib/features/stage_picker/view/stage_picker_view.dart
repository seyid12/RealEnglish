import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/theme/color_palette.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/command_center_state.dart';
import '../../crossword_arena/view/crossword_arena_view.dart';
import '../../control_panel/view/control_panel_view.dart';
import '../../vocabulary_studio/view/vocabulary_studio_view.dart';


const _kAccent = ColorPalette.primary;
const _kText = ColorPalette.textPrimary;
const _kSubtext = ColorPalette.textSecondary;

class StagePickerView extends ConsumerWidget {
  const StagePickerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(commandCenterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by AnimatedBackground
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeInDown(
          child: const Text('RealEnglish',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 2)),
        ),
        actions: [
          // Aktif AI motoru göstergesi
          FadeInRight(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                backgroundColor: _kAccent.withValues(alpha: 0.2),
                side: BorderSide(color: _kAccent.withValues(alpha: 0.5)),
                avatar: const Icon(
                  Icons.phone_android,
                  color: _kAccent,
                  size: 16,
                ),
                label: const Text(
                  'Ollama',
                  style: TextStyle(color: _kAccent, fontSize: 12),
                ),
              ),
            ),
          ),
          // Kelimelerim
          FadeInRight(
            delay: const Duration(milliseconds: 100),
            child: IconButton(
              icon: const Icon(Icons.book, color: _kText),
              tooltip: 'Kelimelerim 📝',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocabularyStudioView()),
              ),
            ),
          ),
          // Ayarlar
          FadeInRight(
            delay: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(Icons.settings, color: _kText),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ControlPanelView()),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / İkon
                  ZoomIn(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _kAccent.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                        gradient: RadialGradient(
                          colors: [_kAccent.withValues(alpha: 0.6), Colors.transparent],
                          stops: const [0.3, 1.0],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.grid_view_rounded, size: 64, color: _kAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: const Text('İngilizce Seviyeni Seç',
                        style: TextStyle(color: _kText, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: const Text(
                      'AI destekli çengel bulmacayla İngilizce öğren',
                      style: TextStyle(color: _kSubtext, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Gamification Card (XP, Seviye, Streak)
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: SizedBox(
                      width: double.infinity,
                      child: GlassmorphicCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Seviye
                                Row(
                                  children: [
                                    const Icon(Icons.stars, color: Colors.amber, size: 28),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Seviye ${settings.level}',
                                      style: const TextStyle(
                                        color: _kText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                // Günlük Seri (Streak)
                                if (settings.streakCount > 0)
                                  Row(
                                    children: [
                                      Text(
                                        '${settings.streakCount} Gün',
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('🔥', style: TextStyle(fontSize: 22)),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // XP Bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${settings.xp % 100}/100 XP',
                                  style: const TextStyle(color: _kSubtext, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Toplam: ${settings.xp} XP',
                                  style: const TextStyle(color: _kSubtext, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (settings.xp % 100) / 100,
                                backgroundColor: Colors.white10,
                                valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
                                minHeight: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: const _StageButton(
                        level: 'A1',
                        description: 'Başlangıç',
                        emoji: '🌱',
                        color: ColorPalette.success),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: const _StageButton(
                        level: 'A2',
                        description: 'Temel',
                        emoji: '🌿',
                        color: ColorPalette.warning),
                  ),
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    child: const _StageButton(
                        level: 'B1',
                        description: 'Orta',
                        emoji: '🔥',
                        color: ColorPalette.error),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageButton extends StatelessWidget {
  final String level;
  final String description;
  final String emoji;
  final Color color;

  const _StageButton({
    required this.level,
    required this.description,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CrosswordArenaView(level: level),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 74,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            Row(
              children: [
                Text(level,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 16),
                Text(description, style: const TextStyle(fontSize: 18, color: ColorPalette.textSecondary)),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

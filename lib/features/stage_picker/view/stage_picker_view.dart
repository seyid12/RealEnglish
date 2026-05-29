import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/control_panel_provider.dart';
import '../../crossword_arena/view/crossword_arena_view.dart';
import '../../control_panel/view/control_panel_view.dart';
import '../../vocabulary_studio/view/vocabulary_studio_view.dart';

const _kBg = Color(0xFF1A1A2E);
const _kCard = Color(0xFF12122A);
const _kAccent = Color(0xFF4A7FD4);
const _kText = Color(0xFFE0E0FF);
const _kSubtext = Color(0xFF8888AA);

class StagePickerView extends ConsumerWidget {
  const StagePickerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(controlPanelProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        title: const Text('RealEnglish',
            style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          // Aktif AI motoru göstergesi
          Padding(
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
          // Kelimelerim
          IconButton(
            icon: const Icon(Icons.book, color: _kText),
            tooltip: 'Kelimelerim 📝',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VocabularyStudioView()),
            ),
          ),
          // Ayarlar
          IconButton(
            icon: const Icon(Icons.settings, color: _kText),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ControlPanelView()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / İkon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [_kAccent.withValues(alpha: 0.4), _kCard],
                    ),
                  ),
                  child: const Icon(Icons.grid_view_rounded, size: 56, color: _kAccent),
                ),
                const SizedBox(height: 24),
                const Text('İngilizce Seviyeni Seç',
                    style: TextStyle(color: _kText, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'AI destekli çengel bulmacayla İngilizce öğren',
                  style: TextStyle(color: _kSubtext, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Gamification Card (XP, Seviye, Streak)
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _kAccent.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Seviye
                          Row(
                            children: [
                              const Icon(Icons.stars, color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Seviye ${settings.level}',
                                style: const TextStyle(
                                  color: _kText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                                const Text('🔥', style: TextStyle(fontSize: 20)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // XP Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${settings.xp % 100}/100 XP',
                            style: const TextStyle(color: _kSubtext, fontSize: 12),
                          ),
                          Text(
                            'Toplam: ${settings.xp} XP',
                            style: const TextStyle(color: _kSubtext, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (settings.xp % 100) / 100,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(_kAccent),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
                const _StageButton(
                    level: 'A1',
                    description: 'Başlangıç',
                    emoji: '🌱',
                    color: Color(0xFF2D9E6A)),
                const SizedBox(height: 16),
                const _StageButton(
                    level: 'A2',
                    description: 'Temel',
                    emoji: '🌿',
                    color: Color(0xFFD4A017)),
                const SizedBox(height: 16),
                const _StageButton(
                    level: 'B1',
                    description: 'Orta',
                    emoji: '🔥',
                    color: Color(0xFFD44A4A)),
              ],
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
    return SizedBox(
      width: 280,
      height: 68,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.15),
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CrosswordArenaView(level: level),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Row(
              children: [
                Text(level,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 12),
                Text(description, style: const TextStyle(fontSize: 16, color: Color(0xFFCCCCEE))),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

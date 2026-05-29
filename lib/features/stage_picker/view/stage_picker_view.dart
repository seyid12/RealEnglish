import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/neo_brutalist_card.dart';
import '../../../core/widgets/neo_brutalist_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/command_center_state.dart';
import '../../crossword_arena/view/crossword_arena_view.dart';
import '../../control_panel/view/control_panel_view.dart';
import '../../vocabulary_studio/view/vocabulary_studio_view.dart';

class StagePickerView extends ConsumerStatefulWidget {
  const StagePickerView({super.key});

  @override
  ConsumerState<StagePickerView> createState() => _StagePickerViewState();
}

class _StagePickerViewState extends ConsumerState<StagePickerView> {
  final PageController _pageController = PageController(viewportFraction: 0.85);

  final List<Map<String, dynamic>> _stages = [
    {
      'level': 'A1',
      'title': 'BEGINNER',
      'desc': 'Start your journey here.',
      'color': ColorPalette.success,
      'icon': Icons.rocket_launch,
    },
    {
      'level': 'A2',
      'title': 'ELEMENTARY',
      'desc': 'Step up your game.',
      'color': ColorPalette.tertiary,
      'icon': Icons.flash_on,
    },
    {
      'level': 'B1',
      'title': 'INTERMEDIATE',
      'desc': 'Things get heated.',
      'color': ColorPalette.primary,
      'icon': Icons.local_fire_department,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(commandCenterProvider);

    return Scaffold(
      backgroundColor: ColorPalette.background,
      appBar: AppBar(
        backgroundColor: ColorPalette.background,
        elevation: 0,
        title: FadeInDown(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ColorPalette.surface,
              border: Border.all(color: ColorPalette.textDark, width: 3),
              boxShadow: const [
                BoxShadow(color: ColorPalette.textDark, offset: Offset(4, 4))
              ],
            ),
            child: const Text(
              'REAL ENGLISH',
              style: TextStyle(
                color: ColorPalette.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        actions: [
          FadeInRight(
            child: IconButton(
              icon: const Icon(Icons.book, color: ColorPalette.textDark, size: 32),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocabularyStudioView()),
              ),
            ),
          ),
          FadeInRight(
            delay: const Duration(milliseconds: 100),
            child: IconButton(
              icon: const Icon(Icons.settings, color: ColorPalette.textDark, size: 32),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ControlPanelView()),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            // User Stats
            FadeInUp(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: NeoBrutalistCard(
                  color: ColorPalette.secondary,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR STATS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('LVL ${settings.level}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: ColorPalette.surface,
                          border: Border.all(color: ColorPalette.textDark, width: 3),
                        ),
                        child: Text(
                          '${settings.xp} XP',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _stages.length,
                itemBuilder: (context, index) {
                  final stage = _stages[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 200 + (index * 100)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                      child: NeoBrutalistCard(
                        color: stage['color'],
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: ColorPalette.surface,
                                    border: Border.all(color: ColorPalette.textDark, width: 3),
                                  ),
                                  child: Icon(stage['icon'], size: 48, color: ColorPalette.textDark),
                                ),
                                Text(
                                  stage['level'],
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: ColorPalette.textDark,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage['title'],
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: ColorPalette.textDark,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  stage['desc'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorPalette.textDark,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: NeoBrutalistButton(
                                    label: 'PLAY NOW',
                                    backgroundColor: ColorPalette.surface,
                                    foregroundColor: ColorPalette.textDark,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CrosswordArenaView(level: stage['level']),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

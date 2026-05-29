import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/neo_brutalist_card.dart';
import '../../../core/widgets/neo_brutalist_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/word_vault_manager.dart';
import '../providers/ai_lexicon_generator.dart';

const _kBg = ColorPalette.background;
const _kCard = ColorPalette.surface;
const _kAccent = ColorPalette.primary;
const _kSubtext = ColorPalette.textSecondary;
const _kSuccess = ColorPalette.success;
const _kDanger = ColorPalette.error;

class VocabularyStudioView extends ConsumerStatefulWidget {
  const VocabularyStudioView({super.key});

  @override
  ConsumerState<VocabularyStudioView> createState() => _VocabularyStudioViewState();
}

class _VocabularyStudioViewState extends ConsumerState<VocabularyStudioView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _wordController = TextEditingController();
  final _clueController = TextEditingController();
  String _selectedLevel = 'A1';

  final List<String> _levels = ['A1', 'A2', 'B1'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _selectedLevel = _levels[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wordController.dispose();
    _clueController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final vocabRepo = ref.watch(wordVaultManagerProvider);
    final genState = ref.watch(aiLexiconGeneratorProvider);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: FadeInDown(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: ColorPalette.tertiary,
              border: Border.all(color: ColorPalette.textDark, width: 3),
              boxShadow: const [
                BoxShadow(color: ColorPalette.textDark, offset: Offset(4, 4))
              ],
            ),
            child: const Text('KELİMELERİM 📝',
                style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
        leading: FadeInLeft(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorPalette.textDark, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          FadeInRight(
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: NeoBrutalistButton(
                backgroundColor: ColorPalette.secondary,
                foregroundColor: ColorPalette.textDark,
                onPressed: genState.isLoading ? () {} : () => _showAiGenerateSheet(context),
                icon: genState.isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 3, color: ColorPalette.textDark))
                    : const Icon(Icons.auto_awesome, size: 18, color: ColorPalette.textDark),
                label: genState.isLoading ? '...' : 'AI',
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ColorPalette.textDark,
          indicatorWeight: 4,
          labelColor: ColorPalette.textDark,
          unselectedLabelColor: _kSubtext,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          tabs: _levels.map((lvl) {
            final count = vocabRepo.getCustomWords(lvl).length;
            return Tab(text: '$lvl ($count)');
          }).toList(),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: _levels.map((level) {
            final words = vocabRepo.getCustomWords(level);

            if (words.isEmpty) {
              return FadeInUp(child: _buildEmptyState(level));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final item = words[index];
                final word = item['word'].toString();
                final clue = item['clue'].toString();

                return FadeInUp(
                  delay: Duration(milliseconds: 50 * index),
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: NeoBrutalistCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  word.toUpperCase(),
                                  style: const TextStyle(
                                    color: ColorPalette.textDark,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  clue,
                                  style: const TextStyle(
                                    color: ColorPalette.textDark,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: _kDanger, size: 32),
                            onPressed: () async {
                              await vocabRepo.deleteCustomWordByValue(word);
                              _refresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🗑️ "$word" kelimesi silindi.', style: const TextStyle(fontWeight: FontWeight.w900)),
                                    backgroundColor: _kDanger,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
      floatingActionButton: BounceInUp(
        child: FloatingActionButton.extended(
          backgroundColor: _kAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: ColorPalette.textDark, width: 3),
          ),
          elevation: 0,
          onPressed: () => _showAddWordDialog(context),
          icon: const Icon(Icons.add, color: ColorPalette.textDark, size: 28),
          label: const Text('EKLE', style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 18)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String level) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ColorPalette.surface,
                border: Border.all(color: ColorPalette.textDark, width: 4),
                boxShadow: const [BoxShadow(color: ColorPalette.textDark, offset: Offset(6, 6))],
              ),
              child: const Icon(Icons.auto_awesome, size: 64, color: ColorPalette.textDark),
            ),
            const SizedBox(height: 32),
            Text(
              '$level SEVİYESİ BOŞ',
              style: const TextStyle(color: ColorPalette.textDark, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yapay zeka ile hızlıca kelime havuzu oluşturun!',
              textAlign: TextAlign.center,
              style: TextStyle(color: ColorPalette.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            NeoBrutalistButton(
              backgroundColor: ColorPalette.secondary,
              foregroundColor: ColorPalette.textDark,
              icon: const Icon(Icons.auto_awesome, color: ColorPalette.textDark),
              label: 'AI ÜRETİMİ',
              onPressed: () => _showAiGenerateSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiGenerateSheet(BuildContext context) {
    int selectedCount = 20;
    String level = _selectedLevel;
    final topicController = TextEditingController();
    final suggestions = ['Ev Eşyaları', 'Hayvanlar', 'Yiyecekler', 'Meslekler', 'Renkler', 'Seyahat'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: ColorPalette.textDark, width: 4),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24, left: 20, right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: ColorPalette.textDark, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'YAPAY ZEKA',
                          style: TextStyle(color: ColorPalette.textDark, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('SEVİYE', style: TextStyle(color: ColorPalette.textDark, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Row(
                      children: ['A1', 'A2', 'B1'].map((lvl) {
                        final selected = level == lvl;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setSheetState(() => level = lvl),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? _kAccent : _kCard,
                                border: Border.all(color: ColorPalette.textDark, width: 3),
                                boxShadow: selected ? const [BoxShadow(color: ColorPalette.textDark, offset: Offset(4, 4))] : [],
                              ),
                              child: Text(
                                lvl,
                                style: TextStyle(
                                  color: ColorPalette.textDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'KONU (İSTEĞE BAĞLI)',
                      style: TextStyle(color: ColorPalette.textDark, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: _kCard,
                        border: Border.all(color: ColorPalette.textDark, width: 3),
                      ),
                      child: TextField(
                        controller: topicController,
                        style: const TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Örn: Spor, Yemek...',
                          hintStyle: TextStyle(color: Colors.black38),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: suggestions.map((sug) {
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              topicController.text = sug;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: ColorPalette.surface,
                              border: Border.all(color: ColorPalette.textDark, width: 2),
                            ),
                            child: Text(sug.toUpperCase(), style: const TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 14)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    const Text('KELİME SAYISI', style: TextStyle(color: ColorPalette.textDark, fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Row(
                      children: [10, 20, 50].map((count) {
                        final selected = selectedCount == count;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedCount = count),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? ColorPalette.secondary : _kCard,
                                border: Border.all(color: ColorPalette.textDark, width: 3),
                                boxShadow: selected ? const [BoxShadow(color: ColorPalette.textDark, offset: Offset(4, 4))] : [],
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: ColorPalette.textDark,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: NeoBrutalistButton(
                        backgroundColor: ColorPalette.secondary,
                        foregroundColor: ColorPalette.textDark,
                        icon: const Icon(Icons.auto_awesome, color: ColorPalette.textDark),
                        label: 'ÜRET',
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          setState(() => _selectedLevel = level);
                          _tabController.index = _levels.indexOf(level);

                          await ref.read(aiLexiconGeneratorProvider.notifier).generateWords(
                            level: level,
                            count: selectedCount,
                            topic: topicController.text.trim().isEmpty ? null : topicController.text.trim(),
                          );

                          final result = ref.read(aiLexiconGeneratorProvider);
                          if (mounted) {
                            if (result.status == LexiconGenerationStatus.success) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('✅ ${result.generatedCount} KELİME EKLENDİ!', style: const TextStyle(fontWeight: FontWeight.w900)),
                                  backgroundColor: _kSuccess,
                                ),
                              );
                            } else if (result.status == LexiconGenerationStatus.error) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('❌ ${result.error}', style: const TextStyle(fontWeight: FontWeight.w900)),
                                  backgroundColor: _kDanger,
                                ),
                              );
                            }
                            ref.read(aiLexiconGeneratorProvider.notifier).reset();
                            _refresh();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddWordDialog(BuildContext context) {
    _wordController.clear();
    _clueController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: ColorPalette.textDark, width: 4),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YENİ KELİME',
                    style: TextStyle(
                      color: ColorPalette.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('İNGİLİZCE KELİME', style: TextStyle(color: ColorPalette.textDark, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _kCard,
                      border: Border.all(color: ColorPalette.textDark, width: 3),
                    ),
                    child: TextField(
                      controller: _wordController,
                      style: const TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 18),
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'ÖRN: APPLE',
                        hintStyle: TextStyle(color: Colors.black38),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('TÜRKÇE İPUCU', style: TextStyle(color: ColorPalette.textDark, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _kCard,
                      border: Border.all(color: ColorPalette.textDark, width: 3),
                    ),
                    child: TextField(
                      controller: _clueController,
                      style: const TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.bold, fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'ÖRN: KIRMIZI BİR MEYVE',
                        hintStyle: TextStyle(color: Colors.black38),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('SEVİYE', style: TextStyle(color: ColorPalette.textDark, fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kCard,
                      border: Border.all(color: ColorPalette.textDark, width: 3),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLevel,
                        dropdownColor: _kCard,
                        style: const TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 18),
                        icon: const Icon(Icons.arrow_drop_down, color: ColorPalette.textDark, size: 32),
                        isExpanded: true,
                        items: _levels.map((String val) {
                          return DropdownMenuItem<String>(
                            value: val,
                            child: Text(val),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setModalState(() {
                              _selectedLevel = newVal;
                            });
                            setState(() {
                              _selectedLevel = newVal;
                              _tabController.index = _levels.indexOf(newVal);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: NeoBrutalistButton(
                      backgroundColor: _kAccent,
                      foregroundColor: ColorPalette.textDark,
                      label: 'EKLE',
                      onPressed: () async {
                        final word = _wordController.text.trim().toUpperCase();
                        final clue = _clueController.text.trim();

                        if (word.isEmpty || clue.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ BOŞ ALAN BIRAKMAYIN.', style: TextStyle(fontWeight: FontWeight.w900)),
                              backgroundColor: _kDanger,
                            ),
                          );
                          return;
                        }

                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(word)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ SADECE İNGİLİZCE HARF.', style: TextStyle(fontWeight: FontWeight.w900)),
                              backgroundColor: _kDanger,
                            ),
                          );
                          return;
                        }

                        final vocabRepo = ref.read(wordVaultManagerProvider);
                        await vocabRepo.addCustomWord(word, clue, _selectedLevel);

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🎉 "$word" EKLENDİ!', style: const TextStyle(fontWeight: FontWeight.w900)),
                              backgroundColor: _kSuccess,
                            ),
                          );
                        }
                        _refresh();
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

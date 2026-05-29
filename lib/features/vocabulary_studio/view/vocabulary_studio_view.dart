import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/widgets/animated_background.dart';
import '../../../core/widgets/glassmorphic_card.dart';
import '../../../core/theme/color_palette.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/word_vault_manager.dart';
import '../providers/ai_lexicon_generator.dart';

const _kBg = ColorPalette.background;
const _kCard = ColorPalette.surface;
const _kAccent = ColorPalette.primary;
const _kText = ColorPalette.textPrimary;
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
      backgroundColor: Colors.transparent, // Handled by AnimatedBackground
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeInDown(
          child: const Text('Kelimelerim 📝',
              style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        ),
        leading: FadeInLeft(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: _kText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          FadeInRight(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: ColorPalette.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 8,
                  shadowColor: ColorPalette.secondary.withValues(alpha: 0.5),
                ),
                onPressed: genState.isLoading ? null : () => _showAiGenerateSheet(context),
                icon: genState.isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(genState.isLoading ? 'Üretiliyor...' : 'AI ile Üret'),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kAccent,
          labelColor: _kAccent,
          unselectedLabelColor: _kSubtext,
          dividerColor: Colors.white10,
          tabs: _levels.map((lvl) {
            final count = vocabRepo.getCustomWords(lvl).length;
            return Tab(text: '$lvl ($count)');
          }).toList(),
        ),
      ),
      body: AnimatedBackground(
        child: SafeArea(
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
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassmorphicCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    word,
                                    style: const TextStyle(
                                      color: _kText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    clue,
                                    style: const TextStyle(
                                      color: _kSubtext,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: _kDanger),
                              onPressed: () async {
                                await vocabRepo.deleteCustomWordByValue(word);
                                _refresh();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('🗑️ "$word" kelimesi silindi.'),
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
      ),
      floatingActionButton: BounceInUp(
        child: FloatingActionButton.extended(
          backgroundColor: _kAccent,
          onPressed: () => _showAddWordDialog(context),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Kelime Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: _kCard, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, size: 64, color: _kSubtext),
            ),
            const SizedBox(height: 24),
            Text(
              '$level Seviyesinde Kelime Yok',
              style: const TextStyle(color: _kText, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sağ üstteki "AI ile Üret" butonuna basarak yapay zeka ile hızlıca kelime havuzu oluşturun!',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kSubtext, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text('AI ile Kelime Üret', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        Icon(Icons.auto_awesome, color: ColorPalette.secondary, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Yapay Zeka ile Kelime Üret',
                          style: TextStyle(color: _kText, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Seçili seviye için toplu kelime üretilir ve havuzunuza kaydedilir.',
                      style: TextStyle(color: _kSubtext, fontSize: 13),
                    ),
                    const SizedBox(height: 20),

                    const Text('Seviye', style: TextStyle(color: _kSubtext, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: ['A1', 'A2', 'B1'].map((lvl) {
                        final selected = level == lvl;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setSheetState(() => level = lvl),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? _kAccent : _kCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selected ? _kAccent : Colors.white12),
                              ),
                              child: Text(
                                lvl,
                                style: TextStyle(
                                  color: selected ? Colors.white : _kSubtext,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Özel Kategori / Konu (İsteğe Bağlı)',
                      style: TextStyle(color: _kSubtext, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: _kCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ColorPalette.secondary.withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller: topicController,
                        style: const TextStyle(color: _kText),
                        decoration: const InputDecoration(
                          hintText: 'Örn: Ev eşyaları, Mutfak araçları, Spor...',
                          hintStyle: TextStyle(color: Colors.white24),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: suggestions.map((sug) {
                        return ActionChip(
                          backgroundColor: _kCard,
                          side: const BorderSide(color: Colors.white12),
                          label: Text(sug, style: const TextStyle(color: _kSubtext, fontSize: 12)),
                          onPressed: () {
                            setSheetState(() {
                              topicController.text = sug;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    const Text('Üretilecek Kelime Sayısı', style: TextStyle(color: _kSubtext, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [10, 20, 50].map((count) {
                        final selected = selectedCount == count;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setSheetState(() => selectedCount = count),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: selected ? ColorPalette.secondary : _kCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? ColorPalette.secondary : Colors.white12,
                                ),
                              ),
                              child: Text(
                                '$count kelime',
                                style: TextStyle(
                                  color: selected ? Colors.white : _kSubtext,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.auto_awesome, color: Colors.white),
                        label: Text(
                          '$selectedCount Kelime Üret ($level)',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
                                  content: Text('✅ ${result.generatedCount} kelime başarıyla eklendi!'),
                                  backgroundColor: _kSuccess,
                                ),
                              );
                            } else if (result.status == LexiconGenerationStatus.error) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('❌ ${result.error}'),
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
                    const SizedBox(height: 24),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    'Yeni Özel Kelime Ekle',
                    style: TextStyle(
                      color: _kText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text('İngilizce Kelime', style: TextStyle(color: _kSubtext, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _wordController,
                      style: const TextStyle(color: _kText, fontWeight: FontWeight.bold),
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Örn: APPLE',
                        hintStyle: TextStyle(color: Colors.white24),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('Türkçe Çengel Bulmaca İpucu', style: TextStyle(color: _kSubtext, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _clueController,
                      style: const TextStyle(color: _kText),
                      decoration: const InputDecoration(
                        hintText: 'Örn: Kırmızı veya yeşil, tatlı bir meyve',
                        hintStyle: TextStyle(color: Colors.white24),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('İngilizce Seviyesi', style: TextStyle(color: _kSubtext, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLevel,
                        dropdownColor: _kCard,
                        style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 16),
                        icon: const Icon(Icons.arrow_drop_down, color: _kText),
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
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final word = _wordController.text.trim().toUpperCase();
                        final clue = _clueController.text.trim();

                        if (word.isEmpty || clue.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Lütfen kelime ve ipucu alanlarını doldurun.'),
                              backgroundColor: _kDanger,
                            ),
                          );
                          return;
                        }

                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(word)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Kelime sadece İngilizce harflerden oluşmalıdır.'),
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
                              content: Text('🎉 "$word" başarıyla eklendi!'),
                              backgroundColor: _kSuccess,
                            ),
                          );
                        }
                        _refresh();
                      },
                      child: const Text(
                        'Kelimeyi Ekle',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

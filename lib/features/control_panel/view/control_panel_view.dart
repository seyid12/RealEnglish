import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/color_palette.dart';
import '../../../core/widgets/neo_brutalist_card.dart';
import '../../../core/widgets/neo_brutalist_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/command_center_state.dart';
import '../../../core/services/word_vault_manager.dart';
import '../../vocabulary_studio/view/vocabulary_studio_view.dart';

const _kBg = ColorPalette.background;
const _kAccent = ColorPalette.primary;

class ControlPanelView extends ConsumerStatefulWidget {
  const ControlPanelView({super.key});

  @override
  ConsumerState<ControlPanelView> createState() => _ControlPanelViewState();
}

class _ControlPanelViewState extends ConsumerState<ControlPanelView> {
  final _ollamaUrlController = TextEditingController();
  final _ollamaModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(commandCenterProvider);
      _ollamaUrlController.text = settings.ollamaUrl;
      _ollamaModelController.text = settings.ollamaModel;
    });
  }

  @override
  void dispose() {
    _ollamaUrlController.dispose();
    _ollamaModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(commandCenterProvider);
    final notifier = ref.read(commandCenterProvider.notifier);

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
            child: const Text('AYARLAR',
                style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
        leading: FadeInLeft(
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: ColorPalette.textDark, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: const _SectionHeader('OLLAMA SUNUCU AYARLARI'),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: const Text(
                'Ollama\'yı bilgisayarınızda çalıştırın. Telefon aynı Wi-Fi\'ye bağlı olmalı.',
                style: TextStyle(color: ColorPalette.textDark, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: NeoBrutalistCard(
                color: ColorPalette.surface,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _InputField(
                      label: 'SUNUCU ADRESİ',
                      controller: _ollamaUrlController,
                      hint: 'http://192.168.1.100:11434',
                    ),
                    const SizedBox(height: 24),
                    _InputField(
                      label: 'MODEL ADI',
                      controller: _ollamaModelController,
                      hint: 'llama3 / mistral / gemma3',
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: NeoBrutalistButton(
                        backgroundColor: _kAccent,
                        foregroundColor: ColorPalette.surface,
                        icon: const Icon(Icons.save, color: ColorPalette.surface),
                        label: 'AYARLARI KAYDET',
                        onPressed: () async {
                          await notifier.setOllamaConfig(
                            url: _ollamaUrlController.text.trim(),
                            model: _ollamaModelController.text.trim(),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ OLLAMA AYARLARI KAYDEDİLDİ', style: TextStyle(fontWeight: FontWeight.w900)),
                                backgroundColor: ColorPalette.success,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // ─── Mevcut Durum ────────────────────────────────────────────────
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              child: const _SectionHeader('MEVCUT DURUM'),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: NeoBrutalistCard(
                color: ColorPalette.surface,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.dns,
                      color: ColorPalette.textDark,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OLLAMA AKTİF',
                            style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                          Text(
                            '${settings.ollamaUrl} — ${settings.ollamaModel}',
                            style: const TextStyle(color: ColorPalette.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            FadeInUp(
              duration: const Duration(milliseconds: 900),
              child: const _SectionHeader('İLERLEME VE VERİ'),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: NeoBrutalistCard(
                color: ColorPalette.surface,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ÖZEL KELİMELERİM 📝',
                      style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bulmacaya kendiniz özel kelimeler ve ipuçları ekleyebilir, silebilir veya düzenleyebilirsiniz.',
                      style: TextStyle(color: ColorPalette.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: NeoBrutalistButton(
                        backgroundColor: ColorPalette.secondary,
                        foregroundColor: ColorPalette.textDark,
                        icon: const Icon(Icons.edit_note, color: ColorPalette.textDark),
                        label: 'DÜZENLE',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VocabularyStudioView()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(height: 3, color: ColorPalette.textDark),
                    const SizedBox(height: 32),
                    const Text(
                      'ÖĞRENİLMİŞ KELİMELER 🧠',
                      style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daha önce doğru bildiğiniz kelimelerin listesini sıfırlayarak aynı kelimelerin tekrar karşınıza çıkmasını sağlayabilirsiniz.',
                      style: TextStyle(color: ColorPalette.textDark, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: NeoBrutalistButton(
                        backgroundColor: ColorPalette.error,
                        foregroundColor: ColorPalette.surface,
                        icon: const Icon(Icons.delete_sweep, color: ColorPalette.surface),
                        label: 'VERİLERİ SIFIRLA',
                        onPressed: () => _showResetConfirmation(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _kBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: ColorPalette.textDark, width: 4),
        ),
        title: const Text('VERİLERİ SIFIRLA', style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900)),
        content: const Text(
          'Daha önce öğrendiğiniz tüm kelimeler sıfırlanacaktır. Bu işlem geri alınamaz. Emin misiniz?',
          style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL', style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final vocabRepo = ref.read(wordVaultManagerProvider);
              await vocabRepo.clearAllWords();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ TÜM VERİLER SIFIRLANDI!', style: TextStyle(fontWeight: FontWeight.w900)),
                    backgroundColor: ColorPalette.success,
                  ),
                );
              }
            },
            child: const Text('EVET, SIFIRLA', style: TextStyle(color: ColorPalette.error, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ColorPalette.textDark,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: ColorPalette.surface,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}


class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _InputField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: ColorPalette.textDark, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorPalette.surface,
            border: Border.all(color: ColorPalette.textDark, width: 3),
            boxShadow: const [BoxShadow(color: ColorPalette.textDark, offset: Offset(4, 4))],
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black38),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/control_panel_provider.dart';
import '../../../core/services/vocabulary_repository.dart';
import '../../vocabulary_studio/view/vocabulary_studio_view.dart';

const _kBg = Color(0xFF1A1A2E);
const _kCard = Color(0xFF12122A);
const _kAccent = Color(0xFF4A7FD4);
const _kText = Color(0xFFE0E0FF);
const _kSubtext = Color(0xFF8888AA);

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
      final settings = ref.read(controlPanelProvider);
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
    final settings = ref.watch(controlPanelProvider);
    final notifier = ref.read(controlPanelProvider.notifier);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        title: const Text('Ayarlar', style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

              const SizedBox(height: 24),
              _SectionHeader('Ollama Sunucu Ayarları'),
              const SizedBox(height: 8),
              const Text(
                'Ollama\'yı bilgisayarınızda veya yerel ağınızda çalıştırın. Telefon aynı Wi-Fi\'ye bağlı olmalı.',
                style: TextStyle(color: _kSubtext, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Sunucu Adresi',
                controller: _ollamaUrlController,
                hint: 'http://192.168.1.100:11434',
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Model Adı',
                controller: _ollamaModelController,
                hint: 'llama3 / mistral / gemma3',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Ollama Ayarlarını Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
                  onPressed: () async {
                    await notifier.setOllamaConfig(
                      url: _ollamaUrlController.text.trim(),
                      model: _ollamaModelController.text.trim(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Ollama ayarları kaydedildi'),
                          backgroundColor: Color(0xFF2D6A4F),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),

            // ─── Mevcut Durum ────────────────────────────────────────────────
            _SectionHeader('Mevcut Durum'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.dns,
                    color: _kAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ollama aktif',
                          style: TextStyle(color: _kText, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${settings.ollamaUrl} — ${settings.ollamaModel}',
                          style: const TextStyle(color: _kSubtext, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader('İlerleme ve Veri'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Özel Kelimelerim 📝',
                    style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bulmacaya kendiniz özel kelimeler ve ipuçları ekleyebilir, silebilir veya düzenleyebilirsiniz.',
                    style: TextStyle(color: _kSubtext, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_note, color: Colors.white),
                      label: const Text('Özel Kelimeleri Düzenle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VocabularyStudioView()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Öğrenilmiş Kelimeler 🧠',
                    style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daha önce doğru bildiğiniz kelimelerin listesini sıfırlayarak aynı kelimelerin tekrar karşınıza çıkmasını sağlayabilirsiniz.',
                    style: TextStyle(color: _kSubtext, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Öğrenilen Kelimeleri Sıfırla'),
                      onPressed: () => _showResetConfirmation(context, ref),
                    ),
                  ),
                ],
              ),
            ),
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
        title: const Text('Verileri Sıfırla', style: TextStyle(color: _kText)),
        content: const Text(
          'Daha önce öğrendiğiniz tüm kelimeler sıfırlanacaktır. Bu işlem geri alınamaz. Emin misiniz?',
          style: TextStyle(color: _kSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: _kSubtext)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final vocabRepo = ref.read(vocabularyRepositoryProvider);
              await vocabRepo.clearAllWords();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Tüm kelime verileri başarıyla sıfırlandı!'),
                    backgroundColor: Color(0xFF2D6A4F),
                  ),
                );
              }
            },
            child: const Text('Evet, Sıfırla', style: TextStyle(color: Colors.redAccent)),
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
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: _kAccent,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
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
        Text(label, style: const TextStyle(color: _kSubtext, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: _kText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _kSubtext),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

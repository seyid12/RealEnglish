import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/vocabulary_repository.dart';
import '../../custom_words/view/custom_words_screen.dart';
import '../../game_board/providers/game_provider.dart';

const _kBg = Color(0xFF1A1A2E);
const _kCard = Color(0xFF12122A);
const _kAccent = Color(0xFF4A7FD4);
const _kText = Color(0xFFE0E0FF);
const _kSubtext = Color(0xFF8888AA);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _ollamaUrlController = TextEditingController();
  final _ollamaModelController = TextEditingController();
  bool _obscureKey = true;

  // Yerel Gemma İndirme Durum Değişkenleri
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadError;
  bool _isModelDownloaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _apiKeyController.text = settings.geminiApiKey;
      _ollamaUrlController.text = settings.ollamaUrl;
      _ollamaModelController.text = settings.ollamaModel;
      _checkModelStatus();
    });
  }

  Future<void> _checkModelStatus() async {
    final downloader = ref.read(modelDownloaderProvider);
    final isDownloaded = await downloader.isModelDownloaded();
    if (mounted) {
      setState(() {
        _isModelDownloaded = isDownloaded;
      });
    }
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _downloadError = null;
      _downloadProgress = 0.0;
    });

    final downloader = ref.read(modelDownloaderProvider);
    downloader.downloadModel(
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      },
      onCompleted: () {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isModelDownloaded = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Yerel Gemma modeli başarıyla indirildi!'),
              backgroundColor: Color(0xFF2D6A4F),
            ),
          );
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _downloadError = err;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _ollamaUrlController.dispose();
    _ollamaModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

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
          // ─── AI Backend Seçimi ───────────────────────────────────────────
          _SectionHeader('Kelime Üretim Motoru'),
          const SizedBox(height: 8),
          Text(
            'Seçtiğiniz motor "Kelimelerim" ekranından kelime havuzu doldurmak için kullanılır. Oyun her zaman yerel havuzdan çalışır.',
            style: const TextStyle(color: _kSubtext, fontSize: 13),
          ),
          const SizedBox(height: 12),

          _BackendCard(
            icon: Icons.cloud,
            title: 'Gemini API',
            subtitle: 'Google\'ın bulut AI\'ı. Hızlı ve güçlü. API anahtarı gerektirir.',
            isSelected: settings.backend == AiBackend.geminiApi,
            onTap: () => notifier.setBackend(AiBackend.geminiApi),
          ),

          const SizedBox(height: 12),

          _BackendCard(
            icon: Icons.dns,
            title: 'Ollama (Yerel Sunucu)',
            subtitle: 'Yerel ağınızdaki Ollama sunucusuna bağlanır. İnternet gerektirmez.',
            isSelected: settings.backend == AiBackend.ollamaApi,
            onTap: () => notifier.setBackend(AiBackend.ollamaApi),
          ),

          const SizedBox(height: 12),

          _BackendCard(
            icon: Icons.offline_bolt,
            title: 'Yerel Gemma (Cihaz İçi AI)',
            subtitle: 'Tamamen cihazınızda çalışan yapay zeka. 1.4 GB model indirme gerektirir.',
            isSelected: settings.backend == AiBackend.localGemma,
            onTap: () => notifier.setBackend(AiBackend.localGemma),
          ),

          // ─── Yerel Gemma Modeli (1.4 GB) ─────────────────────────────────
          if (settings.backend == AiBackend.localGemma) ...[
            const SizedBox(height: 24),
            _SectionHeader('Yerel Gemma Modeli (1.4 GB)'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isModelDownloaded) ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF2D6A4F), size: 24),
                        const SizedBox(width: 8),
                        Text('Gemma Modeli Hazır', style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Yerel Gemma modeli cihazınızda yüklü. İnternetsiz kelime üretimi aktif!',
                      style: TextStyle(color: _kSubtext, fontSize: 13),
                    ),
                  ] else if (_isDownloading) ...[
                    Text('Model İndiriliyor...', style: TextStyle(color: _kText, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: Colors.white10,
                      color: _kAccent,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('%${(_downloadProgress * 100).toStringAsFixed(1)}', style: const TextStyle(color: _kSubtext, fontSize: 13)),
                        const Text('Lütfen uygulamayı kapatmayın', style: TextStyle(color: _kSubtext, fontSize: 11)),
                      ],
                    ),
                  ] else ...[
                    if (_downloadError != null) ...[
                      Text('❌ $_downloadError', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                      const SizedBox(height: 8),
                    ],
                    const Text(
                      'Yerel kelime üretmek için 1.4 GB boyutundaki Gemma-2 2B modelini indirmeniz gerekir.',
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
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Gemma Modelini İndir (1.4 GB)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: _startDownload,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ─── Gemini API Anahtarı ─────────────────────────────────────────
          if (settings.backend == AiBackend.geminiApi) ...[
            const SizedBox(height: 24),
            _SectionHeader('Gemini API Anahtarı'),
            const SizedBox(height: 8),
            Text(
              'Google AI Studio\'dan ücretsiz alabilirsin: aistudio.google.com',
              style: const TextStyle(color: _kSubtext, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _apiKeyController,
                obscureText: _obscureKey,
                style: const TextStyle(color: _kText, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  hintStyle: const TextStyle(color: _kSubtext),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility : Icons.visibility_off,
                      color: _kSubtext,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
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
                label: const Text('Anahtarı Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: () async {
                  await notifier.setGeminiApiKey(_apiKeyController.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ API anahtarı kaydedildi'),
                        backgroundColor: Color(0xFF2D6A4F),
                      ),
                    );
                  }
                },
              ),
            ),
          ],

          // ─── Ollama Ayarları ─────────────────────────────────────────────
          if (settings.backend == AiBackend.ollamaApi) ...[
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
          ],

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
                Icon(
                  settings.backend == AiBackend.geminiApi
                      ? Icons.cloud_done
                      : settings.backend == AiBackend.ollamaApi
                          ? Icons.dns
                          : Icons.offline_bolt,
                  color: _kAccent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.backend == AiBackend.geminiApi
                            ? 'Gemini API aktif'
                            : settings.backend == AiBackend.ollamaApi
                                ? 'Ollama aktif'
                                : 'Yerel Gemma aktif',
                        style: const TextStyle(color: _kText, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        settings.backend == AiBackend.geminiApi
                            ? (settings.geminiApiKey.isEmpty
                                ? '⚠️ API anahtarı girilmedi'
                                : '✅ Anahtar mevcut')
                            : settings.backend == AiBackend.ollamaApi
                                ? '${settings.ollamaUrl} — ${settings.ollamaModel}'
                                : (_isModelDownloaded
                                    ? '✅ Model hazır, çevrimdışı üretilebilir'
                                    : '⚠️ Model indirilmedi, kelime üretilemez'),
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
                      MaterialPageRoute(builder: (_) => const CustomWordsScreen()),
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

class _BackendCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackendCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _kAccent.withValues(alpha: 0.15) : _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kAccent : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? _kAccent.withValues(alpha: 0.2) : Colors.white10,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? _kAccent : _kSubtext, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: isSelected ? _kText : _kSubtext,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(color: _kSubtext, fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _kAccent, size: 22),
          ],
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

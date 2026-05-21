import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/vocabulary_repository.dart';
import '../../custom_words/view/custom_words_screen.dart';

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
  final _gemmaModelPathController = TextEditingController();
  bool _obscureKey = true;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      _apiKeyController.text = settings.geminiApiKey;
      _ollamaUrlController.text = settings.ollamaUrl;
      _ollamaModelController.text = settings.ollamaModel;
      _gemmaModelPathController.text = settings.gemmaModelPath;
    });
  }


  @override
  void dispose() {
    _apiKeyController.dispose();
    _ollamaUrlController.dispose();
    _ollamaModelController.dispose();
    _gemmaModelPathController.dispose();
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
             title: 'Gemma 4 Yerel (LiteRT-LM)',
             subtitle: 'Tamamen yerel dil modeli. İnternet bağlantısı veya harici sunucu gerektirmez.',
             isSelected: settings.backend == AiBackend.gemmaLocal,
             onTap: () => notifier.setBackend(AiBackend.gemmaLocal),
          ),



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

          // ─── Gemma Yerel Model Ayarları ──────────────────────────────────
          if (settings.backend == AiBackend.gemmaLocal) ...[
            const SizedBox(height: 24),
            _SectionHeader('Gemma Yerel Model Ayarları'),
            const SizedBox(height: 8),
            const Text(
              'Gemma 4 modelinin cihazınızda tamamen internetsiz çalışması için ".litertlm" dosya yolunu belirtin.',
              style: TextStyle(color: _kSubtext, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _InputField(
              label: 'Model Dosya Yolu (.litertlm)',
              controller: _gemmaModelPathController,
              hint: '/storage/emulated/0/Download/gemma-4-E2B-it.litertlm',
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open, color: _kAccent),
                onPressed: () async {
                  final result = await FilePicker.pickFiles(
                    dialogTitle: 'Gemma 4 (.litertlm) Modelini Seçin',
                    type: FileType.any,
                  );
                  if (result != null && result.files.single.path != null) {
                    final path = result.files.single.path!;
                    setState(() {
                      _gemmaModelPathController.text = path;
                    });
                    
                    // Otomatik kaydet ve başlat
                    await notifier.setGemmaModelPath(path);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Model yolu seçildi ve başlatılıyor... Lütfen bekleyin.'),
                          backgroundColor: Color(0xFF2D6A4F),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            
            // Donanım Hızlandırıcı Seçimi
            const Text('Donanım Hızlandırıcı', style: TextStyle(color: _kSubtext, fontSize: 13)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildHardwareOption(context, ref, 'CPU', 'cpu', settings.gemmaBackend),
                const SizedBox(width: 8),
                _buildHardwareOption(context, ref, 'GPU (Önerilen)', 'gpu', settings.gemmaBackend),
                const SizedBox(width: 8),
                _buildHardwareOption(context, ref, 'NPU', 'npu', settings.gemmaBackend),
              ],
            ),
            const SizedBox(height: 16),
            
            // Model Durum Göstergesi
            _buildGemmaStatusCard(settings),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Modeli Kaydet ve Başlat', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await notifier.setGemmaModelPath(_gemmaModelPathController.text.trim());
                  if (context.mounted && settings.gemmaError == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Model yolu kaydedildi ve başlatılıyor...'),
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
                      : (settings.backend == AiBackend.ollamaApi
                          ? Icons.dns
                          : Icons.offline_bolt),
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
                            : (settings.backend == AiBackend.ollamaApi
                                ? 'Ollama aktif'
                                : 'Gemma Local aktif'),
                        style: const TextStyle(color: _kText, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        settings.backend == AiBackend.geminiApi
                            ? (settings.geminiApiKey.isEmpty
                                ? '⚠️ API anahtarı girilmedi'
                                : '✅ Anahtar mevcut')
                            : (settings.backend == AiBackend.ollamaApi
                                ? '${settings.ollamaUrl} — ${settings.ollamaModel}'
                                : (settings.gemmaStatus == 'ready'
                                    ? '✅ Model kullanıma hazır (Hızlandırıcı: ${settings.gemmaBackend.toUpperCase()})'
                                    : '⚠️ Model hazır değil (Durum: ${settings.gemmaStatus.toUpperCase()})')),
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

  Widget _buildHardwareOption(BuildContext context, WidgetRef ref, String label, String value, String currentValue) {
    final isSelected = currentValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(settingsProvider.notifier).setGemmaBackend(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _kAccent.withValues(alpha: 0.2) : _kCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? _kAccent : Colors.white12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _kText : _kSubtext,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGemmaStatusCard(AppSettings settings) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    String statusText = 'Durum Bilinmiyor';
    String subText = '';

    switch (settings.gemmaStatus) {
      case 'loading':
        statusColor = Colors.amber;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Model Yükleniyor...';
        subText = 'Büyük model dosyası belleğe alınıyor. Lütfen bekleyin.';
        break;
      case 'ready':
        statusColor = const Color(0xFF2D6A4F);
        statusIcon = Icons.check_circle_outline;
        statusText = 'Model Hazır ✅';
        subText = 'Cihazınızda çevrimdışı çalışmaya hazır.';
        break;
      case 'error':
        statusColor = Colors.redAccent;
        statusIcon = Icons.error_outline;
        statusText = 'Yükleme Hatası ❌';
        subText = settings.gemmaError ?? 'Bilinmeyen bir hata oluştu.';
        break;
      case 'idle':
      default:
        statusColor = _kSubtext;
        statusIcon = Icons.info_outline;
        statusText = 'Model Yüklenmedi ⚠️';
        subText = 'Lütfen geçerli bir dosya yolu girip başlatın.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.gemmaStatus == 'loading')
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            )
          else
            Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (subText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subText,
                    style: const TextStyle(color: _kSubtext, fontSize: 12),
                  ),
                ],
              ],
            ),
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
  final Widget? suffixIcon;

  const _InputField({
    required this.label,
    required this.controller,
    required this.hint,
    this.suffixIcon,
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
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

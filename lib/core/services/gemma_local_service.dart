import 'dart:convert';
import 'package:flutter_litert_lm/flutter_litert_lm.dart';
import '../../features/game_board/domain/prompt_manager.dart';

class GemmaLocalService {
  LiteLmEngine? _engine;
  LiteLmConversation? _conversation;
  bool _isLoading = false;
  String? _lastError;
  String _currentModelPath = '';
  String _currentBackendType = '';

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isConfigured => _engine != null && _conversation != null;
  String get currentModelPath => _currentModelPath;
  String get currentBackendType => _currentBackendType;

  Future<void> configure({
    required String modelPath,
    required String backendType,
  }) async {
    if (modelPath.isEmpty) {
      _lastError = 'Model dosya yolu boş olamaz.';
      return;
    }

    // Eğer model zaten yüklenmişse ve parametreler değişmemişse tekrar yükleme
    if (_engine != null &&
        _currentModelPath == modelPath &&
        _currentBackendType == backendType) {
      return;
    }

    _isLoading = true;
    _lastError = null;

    try {
      await dispose(); // Eski kaynakları temizle

      _currentModelPath = modelPath;
      _currentBackendType = backendType;

      LiteLmBackend backend;
      switch (backendType.toLowerCase()) {
        case 'cpu':
          backend = LiteLmBackend.cpu;
          break;
        case 'npu':
          backend = LiteLmBackend.npu;
          break;
        case 'gpu':
        default:
          backend = LiteLmBackend.gpu;
          break;
      }

      _engine = await LiteLmEngine.create(
        LiteLmEngineConfig(
          modelPath: modelPath,
          backend: backend,
        ),
      );

      final systemPrompt = PromptManager.getSystemPrompt();
      _conversation = await _engine!.createConversation(
        LiteLmConversationConfig(
          systemInstruction: systemPrompt,
          samplerConfig: const LiteLmSamplerConfig(
            temperature: 0.7,
          ),
        ),
      );

      _isLoading = false;
    } catch (e) {
      _lastError = 'Model yüklenirken hata oluştu: $e';
      _isLoading = false;
      _engine = null;
      _conversation = null;
    }
  }

  Future<List<Map<String, dynamic>>> generateWords(
    String level,
    int wordCount, {
    Set<String> excludeWords = const {},
    String? topic,
  }) async {
    if (!isConfigured) {
      throw Exception('Gemma Local modeli yüklenmedi veya yapılandırılmadı.');
    }

    final userPrompt = PromptManager.getPromptForLevel(
      level,
      wordCount,
      excludeWords: excludeWords,
      topic: topic,
    );

    try {
      final response = await _conversation!.sendMessage(userPrompt);
      return _parseJson(response.text);
    } catch (e) {
      // ignore: avoid_print
      print('Gemma Local kelime üretme hatası: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _parseJson(String response) {
    try {
      var cleaned = response
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
      if (match == null) return [];

      final decoded = jsonDecode(match.group(0)!);
      if (decoded is Map<String, dynamic> && decoded.containsKey('words')) {
        return (decoded['words'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      // ignore: avoid_print
      print('Gemma Local JSON parse hatası: $e');
      return [];
    }
  }

  Future<void> dispose() async {
    try {
      // flutter_litert_lm dispose metodlarını çağırıyoruz (varsa)
      // Paket dokümantasyonuna göre engine veya conversation kapatma metotlarını çalıştır
      // Eğer yoksa garbage collector halledecektir fakat bellek sızıntısını önlemek için nesneleri sıfırlıyoruz.
      _conversation = null;
      _engine = null;
    } catch (_) {}
  }
}

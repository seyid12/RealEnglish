import 'dart:convert';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../../features/game_board/domain/prompt_manager.dart';

class GemmaLocalService {
  InferenceModel? _model;
  InferenceChat? _conversation;
  bool _isLoading = false;
  String? _lastError;
  String _currentModelPath = '';
  String _currentBackendType = '';

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get isConfigured => _model != null && _conversation != null;
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

    if (_model != null &&
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

      PreferredBackend backend;
      switch (backendType.toLowerCase()) {
        case 'cpu':
          backend = PreferredBackend.cpu;
          break;
        case 'npu':
          // flutter_gemma NPU'yu da destekliyorsa; yoksa GPU fallback yapılır
          backend = PreferredBackend.cpu; 
          break;
        case 'gpu':
        default:
          backend = PreferredBackend.gpu;
          break;
      }

      // Modeli yükle/install et
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromFile(modelPath)
          .install();

      // Aktif modeli al
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: backend,
      );

      // Chat oturumu oluştur
      _conversation = await _model!.createChat();
      
      // Sistem promptunu en başa ekleyelim
      final systemPrompt = PromptManager.getSystemPrompt();
      await _conversation!.addQueryChunk(Message.text(text: systemPrompt, isUser: true));
      // Aslında sistem rolü de destekleniyorsa Message.system() kullanılabilir ama garanti olması için isUser: true yaptık,
      // veya generateChatResponse() çağırarak modeli hazırlayabiliriz.

      _isLoading = false;
    } catch (e) {
      _lastError = 'Model yüklenirken hata oluştu: $e';
      _isLoading = false;
      _model = null;
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
      await _conversation!.addQueryChunk(Message.text(text: userPrompt, isUser: true));
      final response = await _conversation!.generateChatResponse();
      String responseText = '';
      if (response is TextResponse) {
        responseText = response.token;
      }
      return _parseJson(responseText);
    } catch (e) {
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
      print('Gemma Local JSON parse hatası: $e');
      return [];
    }
  }

  Future<void> dispose() async {
    try {
      _conversation = null;
      _model = null;
    } catch (_) {}
  }
}

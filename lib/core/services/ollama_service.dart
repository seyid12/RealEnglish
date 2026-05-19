import 'dart:convert';
import 'package:dio/dio.dart';
import '../../features/game_board/domain/prompt_manager.dart';

class OllamaService {
  final Dio _dio;
  String _baseUrl = '';
  String _model;

  OllamaService({
    String baseUrl = 'http://localhost:11434',
    String model = 'llama3',
  })  : _model = model,
        _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10))) {
    _baseUrl = _cleanUrl(baseUrl);
  }

  void configure({required String baseUrl, required String model}) {
    _baseUrl = _cleanUrl(baseUrl);
    _model = model;
    _dio.options.baseUrl = '';
  }

  String _cleanUrl(String url) {
    var cleaned = url.trim();
    if (cleaned.isEmpty) return cleaned;
    
    // http:// veya https:// şeması yoksa otomatik olarak http:// ekle
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    
    if (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    
    try {
      final uri = Uri.parse(cleaned);
      var result = '${uri.scheme}://${uri.host}';
      if (uri.hasPort) {
        result += ':${uri.port}';
      }
      return result;
    } catch (_) {
      return cleaned;
    }
  }

  bool get isConfigured => _baseUrl.isNotEmpty && _model.isNotEmpty;

  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('$_baseUrl/api/tags');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> generateWords(
    String level,
    int wordCount, {
    Set<String> excludeWords = const {},
    String? topic,
  }) async {
    if (!isConfigured) throw Exception('Ollama ayarlanmadı.');

    final systemPrompt = PromptManager.getSystemPrompt();
    final userPrompt = PromptManager.getPromptForLevel(
      level,
      wordCount,
      excludeWords: excludeWords,
      topic: topic,
    );

    final response = await _dio.post(
      '$_baseUrl/api/chat',
      data: {
        'model': _model,
        'stream': false,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'options': {
          'temperature': 0.7,
          'num_predict': 2048,
        },
      },
    );

    final text =
        (response.data['message']?['content'] as String?) ?? '';
    return _parseJson(text);
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
      print('Ollama JSON parse hatası: $e');
      return [];
    }
  }
}

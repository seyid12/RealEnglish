import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:aienglish_cengel_bulmaca/features/game_board/domain/prompt_manager.dart';

class GeminiService {
  GenerativeModel? _model;
  String? _apiKey;

  void configure(String apiKey) {
    _apiKey = apiKey;
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );
  }

  bool get isConfigured => _model != null && _apiKey != null && _apiKey!.isNotEmpty;

  Future<List<Map<String, dynamic>>> generateWords(
      String level, int wordCount,
      {Set<String> excludeWords = const {}, String? topic}) async {
    if (!isConfigured) throw Exception('Gemini API anahtarı girilmedi.');

    final systemPrompt = PromptManager.getSystemPrompt();
    final userPrompt = PromptManager.getPromptForLevel(level, wordCount,
        excludeWords: excludeWords, topic: topic);

    final content = [
      Content.text('$systemPrompt\n\n$userPrompt'),
    ];

    final response = await _model!.generateContent(content);
    final text = response.text ?? '';

    return _parseJson(text);
  }

  List<Map<String, dynamic>> _parseJson(String response) {
    try {
      // Markdown code block temizle
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
      print('Gemini JSON parse hatası: $e');
      return [];
    }
  }
}

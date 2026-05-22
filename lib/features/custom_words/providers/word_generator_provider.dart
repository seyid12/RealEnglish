import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/vocabulary_repository.dart';

// ─── State ───────────────────────────────────────────────────────────────────

enum GenerationStatus { idle, loading, success, error }

class WordGeneratorState {
  final GenerationStatus status;
  final int generatedCount;
  final int requestedCount;
  final String? error;

  const WordGeneratorState({
    this.status = GenerationStatus.idle,
    this.generatedCount = 0,
    this.requestedCount = 0,
    this.error,
  });

  bool get isLoading => status == GenerationStatus.loading;

  WordGeneratorState copyWith({
    GenerationStatus? status,
    int? generatedCount,
    int? requestedCount,
    String? error,
  }) {
    return WordGeneratorState(
      status: status ?? this.status,
      generatedCount: generatedCount ?? this.generatedCount,
      requestedCount: requestedCount ?? this.requestedCount,
      error: error,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class WordGeneratorNotifier extends Notifier<WordGeneratorState> {
  @override
  WordGeneratorState build() => const WordGeneratorState();

  /// Yapay zeka ile toplu kelime üretir ve doğrudan customWordsBox'a kaydeder.
  Future<void> generateWords({
    required String level,
    required int count,
    String? topic,
  }) async {
    debugPrint('[AI Word Generator] Başlatıldı. Seviye: $level, Sayı: $count, Konu: $topic');
    state = WordGeneratorState(
      status: GenerationStatus.loading,
      requestedCount: count,
      generatedCount: 0,
    );

    try {
      final settings = ref.read(settingsProvider);
      final vocabRepo = ref.read(vocabularyRepositoryProvider);

      debugPrint('[AI Word Generator] Seçili Backend: ${settings.backend}');

      // Zaten havuzda olan kelimeleri al → AI'ya tekrar ürettirme
      final existingWords = vocabRepo.getCustomWords(level)
          .map((w) => w['word'].toString())
          .toSet();
      debugPrint('[AI Word Generator] Havuzdaki mevcut kelimeler (hariç tutulacak): $existingWords');

      List<Map<String, dynamic>> results = [];

      if (settings.backend == AiBackend.geminiApi) {
        final gemini = ref.read(geminiServiceProvider);
        if (!gemini.isConfigured) {
          debugPrint('[AI Word Generator] Hata: Gemini API anahtarı yapılandırılmamış!');
          state = state.copyWith(
            status: GenerationStatus.error,
            error: 'Gemini API anahtarı girilmedi.\nAyarlar > Gemini API Anahtarı alanını doldurun.',
          );
          return;
        }
        debugPrint('[AI Word Generator] Gemini API çağrısı yapılıyor...');
        results = await gemini.generateWords(level, count, excludeWords: existingWords, topic: topic);
      } else if (settings.backend == AiBackend.ollamaApi) {
        final ollama = ref.read(ollamaServiceProvider);
        if (!ollama.isConfigured) {
          debugPrint('[AI Word Generator] Hata: Ollama yapılandırılmamış!');
          state = state.copyWith(
            status: GenerationStatus.error,
            error: 'Ollama ayarlanmadı.\nAyarlar > Ollama adresini kontrol edin.',
          );
          return;
        }
        debugPrint('[AI Word Generator] Ollama API çağrısı yapılıyor (${settings.ollamaUrl} - ${settings.ollamaModel})...');
        results = await ollama.generateWords(level, count, excludeWords: existingWords, topic: topic);
      }

      debugPrint('[AI Word Generator] Yapay zekadan gelen ham kelime sayısı: ${results.length}');
      debugPrint('[AI Word Generator] Yapay zekadan gelen sonuçlar: $results');

      if (results.isEmpty) {
        debugPrint('[AI Word Generator] Hata: AI boş sonuç döndü veya JSON parse edilemedi!');
        state = state.copyWith(
          status: GenerationStatus.error,
          error: 'Yapay zeka kelime üretemedi. Lütfen tekrar deneyin.',
        );
        return;
      }

      // Üretilen kelimeleri kaydet
      int saved = 0;
      for (final item in results) {
        final word = (item['word'] as String?)?.trim().toUpperCase() ?? '';
        final clue = (item['clue'] as String?)?.trim() ?? '';
        if (word.isEmpty || clue.isEmpty) {
          debugPrint('[AI Word Generator] Geçersiz kelime veya ipucu atlandı: word="$word", clue="$clue"');
          continue;
        }
        // Sadece İngilizce harfler ve boşluklara izin verelim
        if (!RegExp(r'^[A-Z\s]+$').hasMatch(word)) {
          debugPrint('[AI Word Generator] Regex uyuşmazlığı nedeniyle kelime atlandı (sadece A-Z ve boşluk olmalı): "$word"');
          continue;
        }
        await vocabRepo.addCustomWord(word, clue, level);
        debugPrint('[AI Word Generator] Kelime eklendi: "$word" -> "$clue"');
        saved++;
      }

      debugPrint('[AI Word Generator] Başarıyla kaydedilen kelime sayısı: $saved');
      state = state.copyWith(
        status: GenerationStatus.success,
        generatedCount: saved,
      );
    } catch (e) {
      debugPrint('[AI Word Generator] Beklenmeyen Hata: $e');
      state = state.copyWith(
        status: GenerationStatus.error,
        error: 'Hata oluştu: $e',
      );
    }
  }

  void reset() {
    state = const WordGeneratorState();
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final wordGeneratorProvider =
    NotifierProvider<WordGeneratorNotifier, WordGeneratorState>(
  () => WordGeneratorNotifier(),
);

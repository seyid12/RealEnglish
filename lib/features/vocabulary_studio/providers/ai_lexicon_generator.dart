import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/control_panel_provider.dart';
import '../../../core/services/vocabulary_repository.dart';

enum LexiconGenerationStatus { idle, loading, success, error }

class LexiconGeneratorState {
  final LexiconGenerationStatus status;
  final int generatedCount;
  final int requestedCount;
  final String? error;

  const LexiconGeneratorState({
    this.status = LexiconGenerationStatus.idle,
    this.generatedCount = 0,
    this.requestedCount = 0,
    this.error,
  });

  bool get isLoading => status == LexiconGenerationStatus.loading;

  LexiconGeneratorState copyWith({
    LexiconGenerationStatus? status,
    int? generatedCount,
    int? requestedCount,
    String? error,
  }) {
    return LexiconGeneratorState(
      status: status ?? this.status,
      generatedCount: generatedCount ?? this.generatedCount,
      requestedCount: requestedCount ?? this.requestedCount,
      error: error,
    );
  }
}

class LexiconGeneratorNotifier extends Notifier<LexiconGeneratorState> {
  @override
  LexiconGeneratorState build() => const LexiconGeneratorState();

  Future<void> generateWords({
    required String level,
    required int count,
    String? topic,
  }) async {
    debugPrint('[AI Lexicon Generator] Başlatıldı. Seviye: $level, Sayı: $count, Konu: $topic');
    state = LexiconGeneratorState(
      status: LexiconGenerationStatus.loading,
      requestedCount: count,
      generatedCount: 0,
    );

    try {
      final settings = ref.read(controlPanelProvider);
      final vocabRepo = ref.read(vocabularyRepositoryProvider);

      final existingWords = vocabRepo.getCustomWords(level)
          .map((w) => w['word'].toString())
          .toSet();
      debugPrint('[AI Lexicon Generator] Havuzdaki mevcut kelimeler (hariç tutulacak): $existingWords');

      List<Map<String, dynamic>> results = [];

      final ollama = ref.read(ollamaServiceProvider);
      if (!ollama.isConfigured) {
        debugPrint('[AI Lexicon Generator] Hata: Ollama yapılandırılmamış!');
        state = state.copyWith(
          status: LexiconGenerationStatus.error,
          error: 'Ollama ayarlanmadı.\nAyarlar > Ollama adresini kontrol edin.',
        );
        return;
      }
      debugPrint('[AI Lexicon Generator] Ollama API çağrısı yapılıyor (${settings.ollamaUrl} - ${settings.ollamaModel})...');
      results = await ollama.generateWords(level, count, excludeWords: existingWords, topic: topic);

      debugPrint('[AI Lexicon Generator] Yapay zekadan gelen ham kelime sayısı: ${results.length}');
      debugPrint('[AI Lexicon Generator] Yapay zekadan gelen sonuçlar: $results');

      if (results.isEmpty) {
        debugPrint('[AI Lexicon Generator] Hata: AI boş sonuç döndü veya JSON parse edilemedi!');
        state = state.copyWith(
          status: LexiconGenerationStatus.error,
          error: 'Yapay zeka kelime üretemedi. Lütfen tekrar deneyin.',
        );
        return;
      }

      int saved = 0;
      for (final item in results) {
        final word = (item['word'] as String?)?.trim().toUpperCase() ?? '';
        final clue = (item['clue'] as String?)?.trim() ?? '';
        if (word.isEmpty || clue.isEmpty) {
          debugPrint('[AI Lexicon Generator] Geçersiz kelime veya ipucu atlandı: word="$word", clue="$clue"');
          continue;
        }
        if (!RegExp(r'^[A-Z\s]+$').hasMatch(word)) {
          debugPrint('[AI Lexicon Generator] Regex uyuşmazlığı nedeniyle kelime atlandı (sadece A-Z ve boşluk olmalı): "$word"');
          continue;
        }
        await vocabRepo.addCustomWord(word, clue, level);
        debugPrint('[AI Lexicon Generator] Kelime eklendi: "$word" -> "$clue"');
        saved++;
      }

      debugPrint('[AI Lexicon Generator] Başarıyla kaydedilen kelime sayısı: $saved');
      state = state.copyWith(
        status: LexiconGenerationStatus.success,
        generatedCount: saved,
      );
    } catch (e) {
      debugPrint('[AI Lexicon Generator] Beklenmeyen Hata: $e');
      state = state.copyWith(
        status: LexiconGenerationStatus.error,
        error: 'Hata oluştu: $e',
      );
    }
  }

  void reset() {
    state = const LexiconGeneratorState();
  }
}

final aiLexiconGeneratorProvider =
    NotifierProvider<LexiconGeneratorNotifier, LexiconGeneratorState>(
  () => LexiconGeneratorNotifier(),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../domain/models.dart';
import '../domain/prompt_manager.dart';
import '../domain/crossword_generator.dart';
import '../../../core/services/vocabulary_repository.dart';
import '../../../core/services/tts_service.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class GameState {
  final String currentLevel;
  final bool isDownloading;
  final double downloadProgress;
  final bool isThinking;
  final String? error;
  final List<List<CrosswordCell>>? grid;
  final List<Map<String, dynamic>>? words;
  final List<WordPlacement> placements;
  final Map<String, String> userInput;   // "${x}_${y}" -> char
  final int? selectedPlacementIndex;
  final int cursorPosition;
  final Set<int> correctPlacements;      // doğru tamamlanan placement indeksleri
  final bool isComplete;

  const GameState({
    this.currentLevel = 'A1',
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.isThinking = false,
    this.error,
    this.grid,
    this.words,
    this.placements = const [],
    this.userInput = const {},
    this.selectedPlacementIndex,
    this.cursorPosition = 0,
    this.correctPlacements = const {},
    this.isComplete = false,
  });

  String userCharAt(int x, int y) => userInput['${x}_$y'] ?? '';

  bool isCellCorrect(int x, int y) {
    // Hücre, tamamlanmış doğru kelimenin parçasıysa doğrudur
    for (final idx in correctPlacements) {
      if (idx < placements.length && placements[idx].containsCell(x, y)) {
        return true;
      }
    }
    return false;
  }

  GameState copyWith({
    String? currentLevel,
    bool? isDownloading,
    double? downloadProgress,
    bool? isThinking,
    String? error,
    List<List<CrosswordCell>>? grid,
    List<Map<String, dynamic>>? words,
    List<WordPlacement>? placements,
    Map<String, String>? userInput,
    int? selectedPlacementIndex,
    bool clearSelectedPlacement = false,
    int? cursorPosition,
    Set<int>? correctPlacements,
    bool? isComplete,
  }) {
    return GameState(
      currentLevel: currentLevel ?? this.currentLevel,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isThinking: isThinking ?? this.isThinking,
      error: error,
      grid: grid ?? this.grid,
      words: words ?? this.words,
      placements: placements ?? this.placements,
      userInput: userInput ?? this.userInput,
      selectedPlacementIndex: clearSelectedPlacement
          ? null
          : (selectedPlacementIndex ?? this.selectedPlacementIndex),
      cursorPosition: cursorPosition ?? this.cursorPosition,
      correctPlacements: correctPlacements ?? this.correctPlacements,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

// ─── Notifier ───────────────────────────────────────────────────────────────

class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() => const GameState();

  // ── Oyun başlatma ─────────────────────────────────────────────────────────

  Future<void> startGame(String level) async {
    state = state.copyWith(isThinking: true, error: null, currentLevel: level);
    await _generatePuzzle(level);
  }

  Future<void> _generatePuzzle(String level) async {
    try {
      const int targetCount = 5;
      final vocabRepo = ref.read(vocabularyRepositoryProvider);

      // Yerel kelime havuzundan çek
      final allWords = vocabRepo.getCustomWords(level);

      if (allWords.length < targetCount) {
        state = state.copyWith(
          isThinking: false,
          error: 'insufficient_words:$level', // GameBoardScreen bu kodu yakalar
        );
        return;
      }

      // Spaced Repetition (SM-2): Tekrar zamanı gelmiş (due) olan kelimelere öncelik ver
      final now = DateTime.now();

      // Tekrarı gelenler veya yeni eklenenler (nextReviewDate <= now)
      final dueWords = allWords.where((w) {
        final nextReviewStr = w['nextReviewDate'];
        if (nextReviewStr == null) return true; // Hiç oynanmamış/yeni kelimeler due sayılır
        final nextReview = DateTime.tryParse(nextReviewStr);
        return nextReview == null || nextReview.isBefore(now);
      }).toList();

      // Gelecekte tekrar edilecek olanlar (nextReviewDate > now)
      final futureWords = allWords.where((w) {
        final nextReviewStr = w['nextReviewDate'];
        if (nextReviewStr == null) return false;
        final nextReview = DateTime.tryParse(nextReviewStr);
        return nextReview != null && nextReview.isAfter(now);
      }).toList();

      dueWords.shuffle();
      futureWords.shuffle();

      final pool = [...dueWords, ...futureWords];
      final selected = pool.take(targetCount).toList();

      final result = CrosswordGenerator.generate(selected, 10);
      state = state.copyWith(
        isThinking: false,
        grid: result.grid,
        words: selected,
        placements: result.placements,
        userInput: {},
        correctPlacements: {},
        isComplete: false,
      );
    } catch (e) {
      state = state.copyWith(isThinking: false, error: 'Hata: $e');

    }
  }

  // ── Oyun mekaniği ─────────────────────────────────────────────────────────

  /// Hücreye dokunulduğunda kelimeyi seç
  void selectCell(int x, int y) {
    final placements = state.placements;
    final matching = placements
        .asMap()
        .entries
        .where((e) => e.value.containsCell(x, y))
        .toList();
    if (matching.isEmpty) return;

    int newIndex;
    if (matching.length == 1) {
      newIndex = matching.first.key;
    } else {
      // Kesişim noktasında: aynı hücreye tekrar basınca yönü değiştir
      final current = state.selectedPlacementIndex;
      final isAlreadyH = current != null &&
          placements[current].horizontal &&
          placements[current].containsCell(x, y);
      final hEntry =
          matching.firstWhere((e) => e.value.horizontal, orElse: () => matching.first);
      final vEntry =
          matching.firstWhere((e) => !e.value.horizontal, orElse: () => matching.first);
      newIndex = isAlreadyH ? vEntry.key : hEntry.key;
    }

    // Cursoru ilk boş hücreye getir
    final placement = placements[newIndex];
    int cursor = 0;
    for (int i = 0; i < placement.cells.length; i++) {
      final c = placement.cells[i];
      if (state.userCharAt(c.x, c.y).isEmpty) {
        cursor = i;
        break;
      }
      if (i == placement.cells.length - 1) cursor = i;
    }

    state = state.copyWith(
        selectedPlacementIndex: newIndex, cursorPosition: cursor);

    // Eğer seçilen kelime zaten doğru çözülmüşse, İngilizce seslendir
    if (state.correctPlacements.contains(newIndex)) {
      ref.read(ttsServiceProvider).speak(placement.word);
    }
  }

  /// Harf gir
  void enterLetter(String letter) {
    final idx = state.selectedPlacementIndex;
    if (idx == null || idx >= state.placements.length) return;

    final placement = state.placements[idx];
    int cursor = state.cursorPosition;
    if (cursor >= placement.cells.length) return;

    final cell = placement.cells[cursor];
    final newInput = Map<String, String>.from(state.userInput);
    newInput['${cell.x}_${cell.y}'] = letter.toUpperCase();

    // Cursor ilerlet
    final nextCursor =
        cursor + 1 < placement.cells.length ? cursor + 1 : cursor;

    state = state.copyWith(userInput: newInput, cursorPosition: nextCursor);
    _checkWordCompletion(idx, newInput);
  }

  /// Harf sil
  void deleteLetter() {
    final idx = state.selectedPlacementIndex;
    if (idx == null || idx >= state.placements.length) return;

    final placement = state.placements[idx];
    int cursor = state.cursorPosition;
    final newInput = Map<String, String>.from(state.userInput);

    final currentCell = placement.cells[cursor];
    final currentKey = '${currentCell.x}_${currentCell.y}';

    if (newInput.containsKey(currentKey)) {
      newInput.remove(currentKey);
    } else if (cursor > 0) {
      cursor--;
      final prevCell = placement.cells[cursor];
      newInput.remove('${prevCell.x}_${prevCell.y}');
    }

    state = state.copyWith(userInput: newInput, cursorPosition: cursor);
  }

  void _checkWordCompletion(int placementIdx, Map<String, String> input) {
    final placement = state.placements[placementIdx];
    final cells = placement.cells;

    // Kelime dolu mu?
    if (!cells.every((c) => (input['${c.x}_${c.y}'] ?? '').isNotEmpty)) return;

    // Doğru mu?
    final allCorrect = List.generate(cells.length,
        (i) => input['${cells[i].x}_${cells[i].y}'] == placement.word[i]).every((b) => b);

    if (allCorrect) {
      // Kelimeyi otomatik olarak İngilizce seslendir
      ref.read(ttsServiceProvider).speak(placement.word);

      // SM-2 Aralıklı Tekrar verisini güncelle
      final vocabRepo = ref.read(vocabularyRepositoryProvider);
      vocabRepo.updateWordSM2(placement.word, true);

      // Oyunlaştırma: Doğru kelime için +10 XP
      ref.read(settingsProvider.notifier).addXp(10);

      final newCorrect = Set<int>.from(state.correctPlacements)..add(placementIdx);
      final isComplete = newCorrect.length == state.placements.length;
      
      // EĞER OYUN BİTTİYSE KELİMELERİ KAYDET
      if (isComplete && state.words != null) {
        // Oyunlaştırma: Bulmaca bitirme bonusu için +50 XP
        ref.read(settingsProvider.notifier).addXp(50);

        final vocabRepo = ref.read(vocabularyRepositoryProvider);
        final currentWords = state.words!.map((w) => w['word'].toString()).toList();
        
        // Asenkron olarak arkaplanda kaydet
        vocabRepo.saveWords(currentWords, state.currentLevel); 
      }

      state = state.copyWith(
        correctPlacements: newCorrect,
        isComplete: isComplete,
        clearSelectedPlacement: true,
        cursorPosition: 0,
      );
    }
  }

  // ── Mock veri ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _getMockWords(String level) {
    final data = {
      'A1': [
        {'word': 'APPLE', 'clue': 'Kırmızı veya yeşil, tatlı bir meyve'},
        {'word': 'BOOK', 'clue': 'İçinde sayfalar olan, okuyabileceğin şey'},
        {'word': 'CAT', 'clue': 'Miyav diyen evcil hayvan'},
        {'word': 'DOG', 'clue': 'İnsanın en iyi dostu'},
        {'word': 'EGG', 'clue': 'Tavukların yumurtladığı şey'},
      ],
      'A2': [
        {'word': 'BRIDGE', 'clue': 'İki kıyıyı birbirine bağlayan yapı'},
        {'word': 'GARDEN', 'clue': 'Çiçek ve sebzelerin yetiştirildiği alan'},
        {'word': 'RIVER', 'clue': 'Denize doğru akan su yolu'},
        {'word': 'WINDOW', 'clue': 'Işık geçiren, camdan yapılmış açıklık'},
        {'word': 'ISLAND', 'clue': 'Her tarafı suyla çevrili arazi'},
      ],
      'B1': [
        {'word': 'JOURNEY', 'clue': 'Uzun bir yolculuk veya seyahat'},
        {'word': 'FREEDOM', 'clue': 'Kısıtlama olmaksızın hareket edebilme hali'},
        {'word': 'CULTURE', 'clue': 'Bir toplumun örf, adet ve sanatı'},
        {'word': 'CLIMATE', 'clue': 'Bir bölgenin uzun süreli hava koşulları'},
        {'word': 'ANCIENT', 'clue': 'Çok eski zamanlara ait'},
      ],
    };
    return data[level] ?? data['A1']!;
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────


final gameProvider = NotifierProvider<GameNotifier, GameState>(() {
  return GameNotifier();
});

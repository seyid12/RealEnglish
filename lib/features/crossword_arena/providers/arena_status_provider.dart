import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/command_center_state.dart';
import '../domain/arena_models.dart';
import '../domain/crossword_compiler.dart';
import '../../../core/services/word_vault_manager.dart';
import '../../../core/services/tts_service.dart';

class ArenaStatusState {
  final String currentLevel;
  final bool isDownloading;
  final double downloadProgress;
  final bool isThinking;
  final String? error;
  final List<List<ArenaCell>>? grid;
  final List<Map<String, dynamic>>? words;
  final List<WordPlacement> placements;
  final Map<String, String> userInput;
  final int? selectedPlacementIndex;
  final int cursorPosition;
  final Set<int> correctPlacements;
  final bool isComplete;

  const ArenaStatusState({
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
    for (final idx in correctPlacements) {
      if (idx < placements.length && placements[idx].containsCell(x, y)) {
        return true;
      }
    }
    return false;
  }

  ArenaStatusState copyWith({
    String? currentLevel,
    bool? isDownloading,
    double? downloadProgress,
    bool? isThinking,
    String? error,
    List<List<ArenaCell>>? grid,
    List<Map<String, dynamic>>? words,
    List<WordPlacement>? placements,
    Map<String, String>? userInput,
    int? selectedPlacementIndex,
    bool clearSelectedPlacement = false,
    int? cursorPosition,
    Set<int>? correctPlacements,
    bool? isComplete,
  }) {
    return ArenaStatusState(
      currentLevel: currentLevel ?? this.currentLevel,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isThinking: isThinking ?? this.isThinking,
      error: error,
      grid: grid ?? this.grid,
      words: words ?? this.words,
      placements: placements ?? this.placements,
      userInput: userInput ?? this.userInput,
      selectedPlacementIndex: clearSelectedPlacement ? null : (selectedPlacementIndex ?? this.selectedPlacementIndex),
      cursorPosition: cursorPosition ?? this.cursorPosition,
      correctPlacements: correctPlacements ?? this.correctPlacements,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class ArenaStatusNotifier extends Notifier<ArenaStatusState> {
  @override
  ArenaStatusState build() => const ArenaStatusState();

  Future<void> startGame(String level) async {
    state = state.copyWith(isThinking: true, error: null, currentLevel: level);
    await _generatePuzzle(level);
  }

  Future<void> _generatePuzzle(String level) async {
    try {
      const int targetCount = 5;
      final vocabRepo = ref.read(wordVaultManagerProvider);

      final allWords = vocabRepo.getCustomWords(level);

      if (allWords.length < targetCount) {
        state = state.copyWith(
          isThinking: false,
          error: 'insufficient_words:$level',
        );
        return;
      }

      final now = DateTime.now();

      final dueWords = allWords.where((w) {
        final nextReviewStr = w['nextReviewDate'];
        if (nextReviewStr == null) return true;
        final nextReview = DateTime.tryParse(nextReviewStr);
        return nextReview == null || nextReview.isBefore(now);
      }).toList();

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

      final result = CrosswordCompiler.generate(selected, 10);
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
      final current = state.selectedPlacementIndex;
      final isAlreadyH = current != null &&
          placements[current].horizontal &&
          placements[current].containsCell(x, y);
      final hEntry = matching.firstWhere((e) => e.value.horizontal, orElse: () => matching.first);
      final vEntry = matching.firstWhere((e) => !e.value.horizontal, orElse: () => matching.first);
      newIndex = isAlreadyH ? vEntry.key : hEntry.key;
    }

    final placement = placements[newIndex];
    int cursor = 0;
    for (int i = 0; i < placement.cells.length; i++) {
      final c = placement.cells[i];
      if (!state.isCellCorrect(c.x, c.y)) {
        cursor = i;
        break;
      }
      if (i == placement.cells.length - 1) cursor = i;
    }

    state = state.copyWith(selectedPlacementIndex: newIndex, cursorPosition: cursor);

    if (state.correctPlacements.contains(newIndex)) {
      ref.read(ttsServiceProvider).speak(placement.word);
    }
  }

  void enterLetter(String letter) {
    final idx = state.selectedPlacementIndex;
    if (idx == null || idx >= state.placements.length) return;

    final placement = state.placements[idx];
    int cursor = state.cursorPosition;
    if (cursor >= placement.cells.length) return;

    final cell = placement.cells[cursor];
    final newInput = Map<String, String>.from(state.userInput);
    newInput['${cell.x}_${cell.y}'] = letter.toUpperCase();

    int nextCursor = cursor + 1;
    while (nextCursor < placement.cells.length) {
      final nextCell = placement.cells[nextCursor];
      if (state.isCellCorrect(nextCell.x, nextCell.y)) {
        nextCursor++;
      } else {
        break;
      }
    }

    if (nextCursor >= placement.cells.length) {
      nextCursor = placement.cells.length - 1;
    }

    state = state.copyWith(userInput: newInput, cursorPosition: nextCursor);
    _checkWordCompletion(idx, newInput);
  }

  void deleteLetter() {
    final idx = state.selectedPlacementIndex;
    if (idx == null || idx >= state.placements.length) return;

    final placement = state.placements[idx];
    int cursor = state.cursorPosition;
    final newInput = Map<String, String>.from(state.userInput);

    final currentCell = placement.cells[cursor];
    final currentKey = '${currentCell.x}_${currentCell.y}';

    if (newInput.containsKey(currentKey) && !state.isCellCorrect(currentCell.x, currentCell.y)) {
      newInput.remove(currentKey);
    } else if (cursor > 0) {
      int nextCursor = cursor - 1;
      while (nextCursor >= 0 && state.isCellCorrect(placement.cells[nextCursor].x, placement.cells[nextCursor].y)) {
        nextCursor--;
      }
      
      if (nextCursor >= 0) {
        cursor = nextCursor;
        final prevCell = placement.cells[cursor];
        newInput.remove('${prevCell.x}_${prevCell.y}');
      }
    }

    state = state.copyWith(userInput: newInput, cursorPosition: cursor);
  }

  Future<String?> useRevealLetterHint() async {
    final idx = state.selectedPlacementIndex;
    if (idx == null || idx >= state.placements.length) {
      return 'Lütfen önce bir kelime seçin.';
    }

    final placement = state.placements[idx];
    if (state.correctPlacements.contains(idx)) {
      return 'Bu kelime zaten çözülmüş.';
    }

    final settingsNotifier = ref.read(commandCenterProvider.notifier);
    final currentXp = ref.read(commandCenterProvider).xp;
    const hintCost = 20;

    if (currentXp < hintCost) {
      return 'Yetersiz XP! Harf ipucu için 20 XP gerekiyor.';
    }

    final unsolvedCells = <({int index, int x, int y, String correctChar})>[];
    for (int i = 0; i < placement.cells.length; i++) {
      final cell = placement.cells[i];
      final isCorrect = state.isCellCorrect(cell.x, cell.y);
      final userChar = state.userCharAt(cell.x, cell.y);
      final correctChar = placement.word[i];

      if (!isCorrect || userChar != correctChar) {
        unsolvedCells.add((
          index: i,
          x: cell.x,
          y: cell.y,
          correctChar: correctChar,
        ));
      }
    }

    if (unsolvedCells.isEmpty) {
      return 'Tüm harfler zaten doğru.';
    }

    unsolvedCells.shuffle();
    final chosen = unsolvedCells.first;

    await settingsNotifier.spendXp(hintCost);

    final newInput = Map<String, String>.from(state.userInput);
    newInput['${chosen.x}_${chosen.y}'] = chosen.correctChar;

    int scanCursor = 0;
    for (int i = 0; i < placement.cells.length; i++) {
      final c = placement.cells[i];
      final isCorrect = state.isCellCorrect(c.x, c.y);
      final charInInput = newInput['${c.x}_${c.y}'];
      if (!isCorrect && (charInInput == null || charInInput != placement.word[i])) {
        scanCursor = i;
        break;
      }
      if (i == placement.cells.length - 1) scanCursor = i;
    }

    state = state.copyWith(
      userInput: newInput,
      cursorPosition: scanCursor,
    );

    _checkWordCompletion(idx, newInput);
    return null;
  }

  void _checkWordCompletion(int placementIdx, Map<String, String> input) {
    final placement = state.placements[placementIdx];
    final cells = placement.cells;

    if (!cells.every((c) => (input['${c.x}_${c.y}'] ?? '').isNotEmpty)) return;

    final allCorrect = List.generate(cells.length,
        (i) => input['${cells[i].x}_${cells[i].y}'] == placement.word[i]).every((b) => b);

    if (allCorrect) {
      ref.read(ttsServiceProvider).speak(placement.word);

      final vocabRepo = ref.read(wordVaultManagerProvider);
      vocabRepo.updateWordSM2(placement.word, true);

      ref.read(commandCenterProvider.notifier).addXp(10);

      final newCorrect = Set<int>.from(state.correctPlacements)..add(placementIdx);
      final isComplete = newCorrect.length == state.placements.length;
      
      if (isComplete && state.words != null) {
        ref.read(commandCenterProvider.notifier).addXp(50);

        final vocabRepo = ref.read(wordVaultManagerProvider);
        final currentWords = state.words!.map((w) => w['word'].toString()).toList();
        
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
}

final arenaStatusProvider = NotifierProvider<ArenaStatusNotifier, ArenaStatusState>(() {
  return ArenaStatusNotifier();
});

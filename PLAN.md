# Faz A+B+C+D: Tam Oyun Mekaniği

## A+B: Oyun Mekaniği + UI
### models.dart
- `WordPlacement` sınıfı: kelimenin grid koordinatları, yön, hücreler
- `CrosswordResult`: grid + placements tuple

### crossword_generator.dart
- `generate()` → `CrosswordResult` döndürür

### game_provider.dart
- `GameState`: userInput, selectedPlacementIndex, cursorPosition, correctPlacements
- `GameNotifier`: selectCell(), enterLetter(), deleteLetter()

### game_board_screen.dart
- Hücre renkleri: seçili / cursor / doğru / normal
- Seçili kelimenin ipucu altbar
- Custom QWERTY klavye + fiziksel klavye desteği

## C: Android AI
- Mock blok kaldır, llama_cpp_dart NDK ile Android'de çalışır

## D: Faz 3 (Spaced Repetition)
- Hive/Isar ile yanlış kelimeleri kaydet
- Sonraki prompt'a ekle

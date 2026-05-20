import '../domain/models.dart';

class CrosswordGenerator {
  static CrosswordResult generate(
      List<Map<String, dynamic>> wordsJson, int gridSize) {
    if (wordsJson.isEmpty) return CrosswordResult(_emptyGrid(gridSize), []);

    // Kelimeleri büyükten küçüğe sıralayarak yerleşim ihtimalini maksimize et
    final sortedWordsJson = List<Map<String, dynamic>>.from(wordsJson);
    sortedWordsJson.sort((a, b) => b['word'].toString().length.compareTo(a['word'].toString().length));

    final words = sortedWordsJson.map((w) => w['word'].toString().toUpperCase()).toList();
    final clues = sortedWordsJson.map((w) => w['clue'].toString()).toList();

    List<List<String?>> bestChars = List.generate(gridSize, (_) => List.filled(gridSize, null));
    List<_InternalPlacement> bestPlacements = [];

    // Recursive Backtracking (Geri İzleme) Algoritması
    bool backtrack(int wordIndex, List<List<String?>> currentGrid, List<_InternalPlacement> currentPlacements) {
      if (wordIndex == words.length) {
        // Tüm kelimeler başarıyla yerleştirildi!
        bestChars = _copyGrid(currentGrid);
        bestPlacements = List.from(currentPlacements);
        return true;
      }

      final word = words[wordIndex];

      // 1. İlk Kelime: Merkeze dengeli yerleştir
      if (wordIndex == 0) {
        for (final horizontal in [true, false]) {
          final startX = horizontal ? ((gridSize - word.length) / 2).floor() : gridSize ~/ 2;
          final startY = horizontal ? gridSize ~/ 2 : ((gridSize - word.length) / 2).floor();

          if (horizontal) {
            if (_canPlaceH(currentGrid, word, startX, startY, gridSize)) {
              final newGrid = _copyGrid(currentGrid);
              _placeH(newGrid, word, startX, startY);
              final newPlacements = List<_InternalPlacement>.from(currentPlacements)
                ..add(_InternalPlacement(word, startX, startY, true, 1));
              
              if (backtrack(1, newGrid, newPlacements)) return true;
            }
          } else {
            if (_canPlaceV(currentGrid, word, startX, startY, gridSize)) {
              final newGrid = _copyGrid(currentGrid);
              _placeV(newGrid, word, startX, startY);
              final newPlacements = List<_InternalPlacement>.from(currentPlacements)
                ..add(_InternalPlacement(word, startX, startY, false, 1));
              
              if (backtrack(1, newGrid, newPlacements)) return true;
            }
          }
        }
        return false;
      }

      // 2. Kesişim Adaylarını Bul: Yeni kelimeyi sadece mevcut kelimelerle kesişen hücrelerde dene
      final List<_PlacementCandidate> candidates = [];

      for (final p in currentPlacements) {
        for (int ci = 0; ci < p.word.length; ci++) {
          final gridChar = p.word[ci];
          final gridX = p.horizontal ? p.x + ci : p.x;
          final gridY = p.horizontal ? p.y : p.y + ci;

          for (int wi = 0; wi < word.length; wi++) {
            if (word[wi] != gridChar) continue;

            if (p.horizontal) {
              // p yataysa, yeni kelime dikey yerleştirilmeli
              final nx = gridX;
              final ny = gridY - wi;
              if (_canPlaceV(currentGrid, word, nx, ny, gridSize)) {
                candidates.add(_PlacementCandidate(nx, ny, false));
              }
            } else {
              // p dikeyse, yeni kelime yatay yerleştirilmeli
              final nx = gridX - wi;
              final ny = gridY;
              if (_canPlaceH(currentGrid, word, nx, ny, gridSize)) {
                candidates.add(_PlacementCandidate(nx, ny, true));
              }
            }
          }
        }
      }

      // Adayları karıştırarak farklı tasarımlar üretilmesini sağla
      candidates.shuffle();

      for (final cand in candidates) {
        final newGrid = _copyGrid(currentGrid);
        if (cand.horizontal) {
          _placeH(newGrid, word, cand.x, cand.y);
        } else {
          _placeV(newGrid, word, cand.x, cand.y);
        }

        final newPlacements = List<_InternalPlacement>.from(currentPlacements)
          ..add(_InternalPlacement(word, cand.x, cand.y, cand.horizontal, wordIndex + 1));

        if (backtrack(wordIndex + 1, newGrid, newPlacements)) {
          return true;
        }
      }

      // 3. Fallback Floating: Eğer hiçbir kesişen konum bulunamazsa, boş yerlere kesişimsiz yerleştirmeyi son çare dene
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          if (_canPlaceH(currentGrid, word, x, y, gridSize)) {
            final newGrid = _copyGrid(currentGrid);
            _placeH(newGrid, word, x, y);
            final newPlacements = List<_InternalPlacement>.from(currentPlacements)
              ..add(_InternalPlacement(word, x, y, true, wordIndex + 1));
            if (backtrack(wordIndex + 1, newGrid, newPlacements)) return true;
          }
          if (_canPlaceV(currentGrid, word, x, y, gridSize)) {
            final newGrid = _copyGrid(currentGrid);
            _placeV(newGrid, word, x, y);
            final newPlacements = List<_InternalPlacement>.from(currentPlacements)
              ..add(_InternalPlacement(word, x, y, false, wordIndex + 1));
            if (backtrack(wordIndex + 1, newGrid, newPlacements)) return true;
          }
        }
      }

      return false;
    }

    // Algoritmayı çalıştır
    backtrack(0, List.generate(gridSize, (_) => List.filled(gridSize, null)), []);

    // Eğer backtracking tamamen başarısız olduysa, fallback olarak eski sıralı yöntemi kullan
    if (bestPlacements.isEmpty) {
      return _generateSimpleFallback(wordsJson, gridSize);
    }

    // Numaralandırmayı tahtadaki koordinatlarına göre sıralayarak ver (Yukarıdan aşağıya, soldan sağa)
    bestPlacements.sort((a, b) {
      if (a.y != b.y) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });

    final numberedPlacements = <_InternalPlacement>[];
    for (int i = 0; i < bestPlacements.length; i++) {
      final p = bestPlacements[i];
      numberedPlacements.add(_InternalPlacement(p.word, p.x, p.y, p.horizontal, i + 1));
    }

    // Grid hücre yapısını oluştur
    final grid = List.generate(
      gridSize,
      (y) => List.generate(gridSize, (x) {
        final c = bestChars[y][x];
        if (c == null) return CrosswordCell(x: x, y: y);
        int? num;
        for (final p in numberedPlacements) {
          if (p.x == x && p.y == y) { num = p.number; break; }
        }
        return CrosswordCell(x: x, y: y, char: c, isBlank: false, number: num);
      }),
    );

    // Placements listesini üret ve asıl kelime-ipucu listesiyle eşleştir
    final placements = numberedPlacements.map((p) {
      final idx = words.indexOf(p.word);
      final clue = idx >= 0 ? clues[idx] : '';
      return WordPlacement(
        word: p.word,
        clue: clue,
        x: p.x,
        y: p.y,
        horizontal: p.horizontal,
        number: p.number,
      );
    }).toList();

    return CrosswordResult(grid, placements);
  }

  // Grid kopyalama yardımcısı
  static List<List<String?>> _copyGrid(List<List<String?>> source) {
    return source.map((row) => List<String?>.from(row)).toList();
  }

  static bool _canPlaceH(List<List<String?>> g, String w, int x, int y, int gs) {
    if (x < 0 || x + w.length > gs || y < 0 || y >= gs) return false;
    if (x > 0 && g[y][x - 1] != null) return false;
    if (x + w.length < gs && g[y][x + w.length] != null) return false;
    for (int i = 0; i < w.length; i++) {
      final existing = g[y][x + i];
      if (existing != null && existing != w[i]) return false;
      if (existing == null) {
        if (y > 0 && g[y - 1][x + i] != null) return false;
        if (y < g.length - 1 && g[y + 1][x + i] != null) return false;
      }
    }
    return true;
  }

  static void _placeH(List<List<String?>> g, String w, int x, int y) {
    for (int i = 0; i < w.length; i++) {
      g[y][x + i] = w[i];
    }
  }

  static bool _canPlaceV(List<List<String?>> g, String w, int x, int y, int gs) {
    if (y < 0 || y + w.length > gs || x < 0 || x >= gs) return false;
    if (y > 0 && g[y - 1][x] != null) return false;
    if (y + w.length < gs && g[y + w.length][x] != null) return false;
    for (int i = 0; i < w.length; i++) {
      final existing = g[y + i][x];
      if (existing != null && existing != w[i]) return false;
      if (existing == null) {
        if (x > 0 && g[y + i][x - 1] != null) return false;
        if (x < g[0].length - 1 && g[y + i][x + 1] != null) return false;
      }
    }
    return true;
  }

  static void _placeV(List<List<String?>> g, String w, int x, int y) {
    for (int i = 0; i < w.length; i++) {
      g[y + i][x] = w[i];
    }
  }

  // Emniyet Kemeri (Fallback Yöntemi): Hızlı ve basit yerleşim
  static CrosswordResult _generateSimpleFallback(List<Map<String, dynamic>> wordsJson, int gridSize) {
    final words = wordsJson.map((w) => w['word'].toString().toUpperCase()).toList();
    final clues = wordsJson.map((w) => w['clue'].toString()).toList();

    final List<List<String?>> chars = List.generate(gridSize, (_) => List.filled(gridSize, null));
    final List<_InternalPlacement> internals = [];
    int wordNumber = 1;

    final first = words[0];
    final startX = ((gridSize - first.length) / 2).floor();
    final startY = gridSize ~/ 2;
    if (_canPlaceH(chars, first, startX, startY, gridSize)) {
      _placeH(chars, first, startX, startY);
      internals.add(_InternalPlacement(first, startX, startY, true, wordNumber++));
    }

    for (int wi = 1; wi < words.length; wi++) {
      final word = words[wi];
      bool placed = false;

      for (final p in List.from(internals)) {
        if (placed) break;
        for (int ci = 0; ci < p.word.length; ci++) {
          if (placed) break;
          final gridChar = p.word[ci];

          for (int wi2 = 0; wi2 < word.length; wi2++) {
            if (word[wi2] != gridChar) continue;

            if (p.horizontal) {
              final nx = p.x + ci;
              final ny = p.y - wi2;
              if (_canPlaceV(chars, word, nx, ny, gridSize)) {
                _placeV(chars, word, nx, ny);
                internals.add(_InternalPlacement(word, nx, ny, false, wordNumber++));
                placed = true;
                break;
              }
            } else {
              final nx = p.x - wi2;
              final ny = p.y + ci;
              if (_canPlaceH(chars, word, nx, ny, gridSize)) {
                _placeH(chars, word, nx, ny);
                internals.add(_InternalPlacement(word, nx, ny, true, wordNumber++));
                placed = true;
                break;
              }
            }
          }
        }
      }

      if (!placed) {
        // Floating yerleşim
        for (int y = 0; y < gridSize; y++) {
          if (placed) break;
          for (int x = 0; x < gridSize; x++) {
            if (_canPlaceH(chars, word, x, y, gridSize)) {
              _placeH(chars, word, x, y);
              internals.add(_InternalPlacement(word, x, y, true, wordNumber++));
              placed = true;
              break;
            }
          }
        }
      }
    }

    final grid = List.generate(
      gridSize,
      (y) => List.generate(gridSize, (x) {
        final c = chars[y][x];
        if (c == null) return CrosswordCell(x: x, y: y);
        int? num;
        for (final p in internals) {
          if (p.x == x && p.y == y) { num = p.number; break; }
        }
        return CrosswordCell(x: x, y: y, char: c, isBlank: false, number: num);
      }),
    );

    final placements = internals.map((p) {
      final idx = words.indexOf(p.word);
      final clue = idx >= 0 ? clues[idx] : '';
      return WordPlacement(
        word: p.word,
        clue: clue,
        x: p.x,
        y: p.y,
        horizontal: p.horizontal,
        number: p.number,
      );
    }).toList();

    return CrosswordResult(grid, placements);
  }

  static List<List<CrosswordCell>> _emptyGrid(int gs) => List.generate(
      gs, (y) => List.generate(gs, (x) => CrosswordCell(x: x, y: y)));
}

class _InternalPlacement {
  final String word;
  final int x, y;
  final bool horizontal;
  final int number;
  _InternalPlacement(this.word, this.x, this.y, this.horizontal, this.number);
}

class _PlacementCandidate {
  final int x, y;
  final bool horizontal;
  _PlacementCandidate(this.x, this.y, this.horizontal);
}

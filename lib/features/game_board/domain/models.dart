class CrosswordCell {
  final int x, y;
  final String char; // Doğru cevap
  final bool isBlank;
  final int? number;

  const CrosswordCell({
    required this.x,
    required this.y,
    this.char = '',
    this.isBlank = true,
    this.number,
  });
}

/// Bir kelimenin grid üzerindeki konumunu ve hücrelerini tanımlar.
class WordPlacement {
  final String word;
  final String clue;
  final int x, y;
  final bool horizontal;
  final int number;

  const WordPlacement({
    required this.word,
    required this.clue,
    required this.x,
    required this.y,
    required this.horizontal,
    required this.number,
  });

  /// Kelimenin kapladığı tüm (x, y) koordinatları
  List<({int x, int y})> get cells => List.generate(
        word.length,
        (i) => horizontal
            ? (x: x + i, y: y)
            : (x: x, y: y + i),
      );

  bool containsCell(int cx, int cy) =>
      cells.any((c) => c.x == cx && c.y == cy);

  int cellIndex(int cx, int cy) {
    final list = cells;
    for (int i = 0; i < list.length; i++) {
      if (list[i].x == cx && list[i].y == cy) return i;
    }
    return -1;
  }
}

/// CrosswordGenerator'ın döndürdüğü sonuç
class CrosswordResult {
  final List<List<CrosswordCell>> grid;
  final List<WordPlacement> placements;
  const CrosswordResult(this.grid, this.placements);
}

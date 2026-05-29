class ArenaCell {
  final int x, y;
  final String char;
  final bool isBlank;
  final int? number;

  const ArenaCell({
    required this.x,
    required this.y,
    this.char = '',
    this.isBlank = true,
    this.number,
  });
}

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

  List<({int x, int y})> get cells => List.generate(
        word.length,
        (i) => horizontal ? (x: x + i, y: y) : (x: x, y: y + i),
      );

  bool containsCell(int cx, int cy) => cells.any((c) => c.x == cx && c.y == cy);

  int cellIndex(int cx, int cy) {
    final list = cells;
    for (int i = 0; i < list.length; i++) {
      if (list[i].x == cx && list[i].y == cy) return i;
    }
    return -1;
  }
}

class CompilationResult {
  final List<List<ArenaCell>> grid;
  final List<WordPlacement> placements;
  const CompilationResult(this.grid, this.placements);
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../providers/game_provider.dart';
import '../../custom_words/view/custom_words_screen.dart';
import '../../../core/services/tts_service.dart';

// ─── Renkler ────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF1A1A2E);
const _kCellNormal = Color(0xFF2D2D44);
const _kCellSelected = Color(0xFF3A4A6B);
const _kCellCursor = Color(0xFF4A7FD4);
const _kCellCorrect = Color(0xFF2D6A4F);
const _kTextNormal = Color(0xFFE0E0FF);
const _kTextCorrect = Color(0xFF74C69D);
const _kAccent = Color(0xFF4A7FD4);
const _kKeyBg = Color(0xFF252540);
const _kKeyPressed = Color(0xFF4A7FD4);

// ─── Ekran ──────────────────────────────────────────────────────────────────

class GameBoardScreen extends ConsumerStatefulWidget {
  final String level;
  const GameBoardScreen({super.key, required this.level});

  @override
  ConsumerState<GameBoardScreen> createState() => _GameBoardScreenState();
}

class _GameBoardScreenState extends ConsumerState<GameBoardScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameProvider.notifier).startGame(widget.level);
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final notifier = ref.read(gameProvider.notifier);
        if (event.logicalKey == LogicalKeyboardKey.backspace) {
          notifier.deleteLetter();
        } else {
          final char = event.character;
          if (char != null && RegExp(r'[a-zA-Z]').hasMatch(char)) {
            notifier.enterLetter(char);
          }
        }
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: const Color(0xFF12122A),
          title: Text('${widget.level} Seviyesi',
              style: const TextStyle(color: _kTextNormal, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _kTextNormal),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (gameState.isComplete)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.star, color: Colors.amber, size: 28),
              ),
          ],
        ),
        body: SafeArea(
          child: _buildBody(gameState),
        ),
      ),
    );
  }

  Widget _buildBody(GameState state) {
    if (state.error != null) return _buildError(state);
    if (state.isDownloading) return _buildDownloading(state);
    if (state.isThinking) return _buildThinking();
    if (state.grid == null) return const SizedBox();
    return _buildGame(state);
  }

  // ── Yükleme ekranları ──────────────────────────────────────────────────────

  Widget _buildError(GameState state) {
    final isInsufficient = state.error!.startsWith('insufficient_words:');

    if (isInsufficient) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF12122A),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kAccent.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.book_outlined, color: _kAccent, size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'Kelime Havuzu Boş!',
                style: TextStyle(color: _kTextNormal, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.level} seviyesinde en az 5 kelime olmalı.\n"Kelimelerim" ekranından yapay zeka ile toplu kelime üretin!',
                style: const TextStyle(color: Colors.white54, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  label: const Text('Kelimelerim\'e Git', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomWordsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 20),
            Text(state.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextNormal, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: _kAccent),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              onPressed: () =>
                  ref.read(gameProvider.notifier).startGame(widget.level),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloading(GameState state) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download, size: 72, color: _kAccent),
            const SizedBox(height: 24),
            const Text('Gemma 4 E2B Modeli İndiriliyor...',
                style: TextStyle(
                    color: _kTextNormal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
                width: 260,
                child: LinearProgressIndicator(
                    value: state.downloadProgress,
                    backgroundColor: _kKeyBg,
                    color: _kAccent)),
            const SizedBox(height: 12),
            Text('%${(state.downloadProgress * 100).toStringAsFixed(1)}',
                style:
                    const TextStyle(color: _kTextNormal, fontSize: 16)),
          ],
        ),
      );

  Widget _buildThinking() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _kAccent),
            SizedBox(height: 24),
            Text('Yapay Zeka Bulmaca Üretiyor...',
                style: TextStyle(
                    color: _kTextNormal,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );

  // ── Oyun alanı ─────────────────────────────────────────────────────────────

  Widget _buildGame(GameState state) {
    return Column(
      children: [
        // Tamamlanma banner
        if (state.isComplete) _buildCompleteBanner(),

        // Grid
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: const EdgeInsets.all(80),
            minScale: 0.4,
            maxScale: 2.5,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(10, (y) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(10, (x) {
                    final cell = state.grid![y][x];
                    return _CellWidget(
                      cell: cell,
                      gameState: state,
                      onTap: () => ref.read(gameProvider.notifier).selectCell(x, y),
                    );
                  }),
                )),
              ),
            ),
          ),
        ),

        // İpucu çubuğu + Klavye
        _buildBottomPanel(state),
      ],
    );
  }

  Widget _buildCompleteBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: _kCellCorrect,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Tebrikler! Bulmacayı Tamamladın! 🎉',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      );

  Widget _buildBottomPanel(GameState state) {
    final sel = state.selectedPlacementIndex;
    final placement = sel != null && sel < state.placements.length
        ? state.placements[sel]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // İpucu çubuğu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF12122A),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: placement != null
                    ? RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${placement.number}. ',
                              style: const TextStyle(
                                  color: _kAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            TextSpan(
                              text: placement.clue,
                              style: const TextStyle(
                                  color: _kTextNormal, fontSize: 15),
                            ),
                            TextSpan(
                              text: '  (${placement.word.length} harf)',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : const Text('Bir kelimeye dokunun',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 15)),
              ),
              if (placement != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.lightbulb, color: Colors.amber, size: 22),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final error = await ref.read(gameProvider.notifier).useRevealLetterHint();
                    if (error != null) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  tooltip: 'Harf İpucu (-20 XP) 💡',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white70, size: 22),
                  onPressed: () {
                    ref.read(ttsServiceProvider).speak(placement.word);
                  },
                  tooltip: 'Telaffuz Dinle 🔊',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ),

        // Klavye
        if (placement != null && !state.isComplete)
          _KeyboardWidget(
            onLetter: (l) => ref.read(gameProvider.notifier).enterLetter(l),
            onDelete: () => ref.read(gameProvider.notifier).deleteLetter(),
          ),
      ],
    );
  }
}

// ─── Hücre Widget ───────────────────────────────────────────────────────────

class _CellWidget extends StatelessWidget {
  final CrosswordCell cell;
  final GameState gameState;
  final VoidCallback onTap;

  const _CellWidget(
      {required this.cell, required this.gameState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (cell.isBlank) {
      return const SizedBox(width: 40, height: 40);
    }

    // Durumu belirle
    final sel = gameState.selectedPlacementIndex;
    final placement = sel != null && sel < gameState.placements.length
        ? gameState.placements[sel]
        : null;

    final isInSelectedWord = placement?.containsCell(cell.x, cell.y) ?? false;

    bool isCursor = false;
    if (isInSelectedWord && placement != null) {
      if (gameState.cursorPosition >= 0 && gameState.cursorPosition < placement.cells.length) {
        final cursorCell = placement.cells[gameState.cursorPosition];
        isCursor = cursorCell.x == cell.x && cursorCell.y == cell.y;
      }
    }

    final isCorrect = gameState.isCellCorrect(cell.x, cell.y);
    final userChar = gameState.userCharAt(cell.x, cell.y);

    Color bgColor;
    Color borderColor;
    if (isCorrect) {
      bgColor = _kCellCorrect;
      borderColor = _kTextCorrect;
    } else if (isCursor) {
      bgColor = _kCellCursor;
      borderColor = Colors.white;
    } else if (isInSelectedWord) {
      bgColor = _kCellSelected;
      borderColor = _kAccent.withValues(alpha: 0.6);
    } else {
      bgColor = _kCellNormal;
      borderColor = Colors.white12;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isCursor ? 2 : 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            if (cell.number != null)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  '${cell.number}',
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white54,
                      fontWeight: FontWeight.bold),
                ),
              ),
            Center(
              child: Text(
                userChar.isNotEmpty ? userChar : '',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? _kTextCorrect : _kTextNormal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Klavye Widget ──────────────────────────────────────────────────────────

class _KeyboardWidget extends StatelessWidget {
  final void Function(String) onLetter;
  final VoidCallback onDelete;

  const _KeyboardWidget({required this.onLetter, required this.onDelete});

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      color: const Color(0xFF0F0F20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row
                      .map((key) => _KeyButton(
                          label: key, onPressed: () => onLetter(key)))
                      .toList(),
                ),
              )),
          // Sil tuşu
          _KeyButton(
            label: '⌫',
            onPressed: onDelete,
            width: 80,
            color: const Color(0xFF3A2A2A),
          ),
        ],
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final Color? color;

  const _KeyButton({
    required this.label,
    required this.onPressed,
    this.width = 34,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: color ?? _kKeyBg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          splashColor: _kKeyPressed.withValues(alpha: 0.4),
          child: Container(
            width: width,
            height: 42,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: _kTextNormal,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

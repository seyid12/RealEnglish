import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/theme/color_palette.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/arena_models.dart';
import '../providers/arena_status_provider.dart';
import '../../vocabulary_studio/view/vocabulary_studio_view.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/widgets/neo_brutalist_button.dart';
const _kCellNormal = ColorPalette.cellNormal;
const _kCellSelected = ColorPalette.cellSelected;
const _kCellCursor = ColorPalette.cellCursor;
const _kCellCorrect = ColorPalette.cellCorrect;
const _kTextNormal = ColorPalette.textPrimary;
const _kAccent = ColorPalette.primary;
const _kKeyBg = ColorPalette.surface;

class CrosswordArenaView extends ConsumerStatefulWidget {
  final String level;
  const CrosswordArenaView({super.key, required this.level});

  @override
  ConsumerState<CrosswordArenaView> createState() => _CrosswordArenaViewState();
}

class _CrosswordArenaViewState extends ConsumerState<CrosswordArenaView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(arenaStatusProvider.notifier).startGame(widget.level);
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
    final gameState = ref.watch(arenaStatusProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final notifier = ref.read(arenaStatusProvider.notifier);
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
        backgroundColor: ColorPalette.background,
        appBar: AppBar(
          backgroundColor: ColorPalette.background,
          elevation: 0,
          title: FadeInDown(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: ColorPalette.surface,
                border: Border.all(color: ColorPalette.textDark, width: 3),
              ),
              child: Text('${widget.level} SEVİYESİ',
                  style: const TextStyle(color: _kTextNormal, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          ),
          leading: FadeInLeft(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: _kTextNormal, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          actions: [
            if (gameState.isComplete)
              ZoomIn(
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.star, color: Colors.amber, size: 36),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: _buildBody(gameState),
        ),
      ),
    );
  }

  Widget _buildBody(ArenaStatusState state) {
    if (state.error != null) return _buildError(state);
    if (state.isDownloading) return _buildDownloading(state);
    if (state.isThinking) return _buildThinking();
    if (state.grid == null) return const SizedBox();
    return _buildGame(state);
  }

  Widget _buildError(ArenaStatusState state) {
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
                  color: ColorPalette.surface,
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: NeoBrutalistButton(
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  label: 'Kelimelerim\'e Git', 
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const VocabularyStudioView()),
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
            NeoBrutalistButton(
              backgroundColor: _kAccent,
              foregroundColor: ColorPalette.surface,
              icon: const Icon(Icons.refresh),
              label: 'TEKRAR DENE',
              onPressed: () => ref.read(arenaStatusProvider.notifier).startGame(widget.level),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloading(ArenaStatusState state) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_download, size: 72, color: _kAccent),
            const SizedBox(height: 24),
            const Text('Gemma 4 E2B Modeli İndiriliyor...',
                style: TextStyle(color: _kTextNormal, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
                width: 260,
                child: LinearProgressIndicator(
                    value: state.downloadProgress,
                    backgroundColor: _kKeyBg,
                    color: _kAccent)),
            const SizedBox(height: 12),
            Text('%${(state.downloadProgress * 100).toStringAsFixed(1)}',
                style: const TextStyle(color: _kTextNormal, fontSize: 16)),
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
                style: TextStyle(color: _kTextNormal, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _buildGame(ArenaStatusState state) {
    return Column(
      children: [
        if (state.isComplete) _buildCompleteBanner(),
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
                    return _ArenaCellWidget(
                      cell: cell,
                      gameState: state,
                      onTap: () => ref.read(arenaStatusProvider.notifier).selectCell(x, y),
                    );
                  }),
                )),
              ),
            ),
          ),
        ),
        _buildBottomPanel(state),
      ],
    );
  }

  Widget _buildCompleteBanner() => FadeInDown(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: const BoxDecoration(
            color: _kCellCorrect,
            border: Border.symmetric(horizontal: BorderSide(color: ColorPalette.textDark, width: 4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 32),
              SizedBox(width: 8),
              Text('TEBRİKLER! BULMACAYI TAMAMLADIN! 🎉',
                  style: TextStyle(color: ColorPalette.textDark, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
        ),
      );

  Widget _buildBottomPanel(ArenaStatusState state) {
    final sel = state.selectedPlacementIndex;
    final placement = sel != null && sel < state.placements.length ? state.placements[sel] : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: ColorPalette.surface,
            border: Border.symmetric(horizontal: BorderSide(color: ColorPalette.textDark, width: 3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: placement != null
                    ? RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${placement.number}. ',
                              style: const TextStyle(color: _kAccent, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            TextSpan(
                              text: placement.clue.toUpperCase(),
                              style: const TextStyle(color: _kTextNormal, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            TextSpan(
                              text: '  (${placement.word.length} HARF)',
                              style: const TextStyle(color: ColorPalette.textSecondary, fontWeight: FontWeight.w900, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : const Text('Bir kelimeye dokunun', style: TextStyle(color: Colors.white38, fontSize: 15)),
              ),
              if (placement != null) ...[
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.lightbulb, color: Colors.amber, size: 22),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final error = await ref.read(arenaStatusProvider.notifier).useRevealLetterHint();
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
        if (placement != null && !state.isComplete)
          _ArenaKeyboardWidget(
            onLetter: (l) => ref.read(arenaStatusProvider.notifier).enterLetter(l),
            onDelete: () => ref.read(arenaStatusProvider.notifier).deleteLetter(),
          ),
      ],
    );
  }
}

class _ArenaCellWidget extends StatelessWidget {
  final ArenaCell cell;
  final ArenaStatusState gameState;
  final VoidCallback onTap;

  const _ArenaCellWidget({required this.cell, required this.gameState, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (cell.isBlank) {
      return const SizedBox(width: 40, height: 40);
    }

    final sel = gameState.selectedPlacementIndex;
    final placement = sel != null && sel < gameState.placements.length ? gameState.placements[sel] : null;

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

    if (isCorrect) {
      bgColor = _kCellCorrect;
    } else if (isCursor) {
      bgColor = _kCellCursor;
    } else if (isInSelectedWord) {
      bgColor = _kCellSelected;
    } else {
      bgColor = _kCellNormal;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: ColorPalette.textDark, width: 3),
          boxShadow: const [
            BoxShadow(
              color: ColorPalette.textDark,
              offset: Offset(3, 3),
            )
          ],
        ),
        child: Stack(
          children: [
            if (cell.number != null)
              Positioned(
                top: 2,
                left: 4,
                child: Text(
                  '${cell.number}',
                  style: const TextStyle(fontSize: 10, color: ColorPalette.textDark, fontWeight: FontWeight.w900),
                ),
              ),
            Center(
              child: Text(
                userChar.isNotEmpty ? userChar.toUpperCase() : '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: ColorPalette.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaKeyboardWidget extends StatelessWidget {
  final void Function(String) onLetter;
  final VoidCallback onDelete;

  const _ArenaKeyboardWidget({required this.onLetter, required this.onDelete});

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      color: ColorPalette.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._rows.map((row) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: row
                      .map((key) => _ArenaKeyButton(label: key, onPressed: () => onLetter(key)))
                      .toList(),
                ),
              )),
          _ArenaKeyButton(
            label: '⌫',
            onPressed: onDelete,
            width: 80,
            color: ColorPalette.surfaceLighter,
          ),
        ],
      ),
    );
  }
}

class _ArenaKeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double width;
  final Color? color;

  const _ArenaKeyButton({
    required this.label,
    required this.onPressed,
    this.width = 34,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: width,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color ?? _kKeyBg,
            border: Border.all(color: ColorPalette.textDark, width: 2),
            boxShadow: const [
              BoxShadow(
                color: ColorPalette.textDark,
                offset: Offset(2, 2),
              )
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: ColorPalette.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

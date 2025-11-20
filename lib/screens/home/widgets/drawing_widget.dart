import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/game_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

// REMOVED: Unused import 'dart:math'

class DrawingWidget extends StatefulWidget {
  const DrawingWidget({super.key});

  @override
  State<DrawingWidget> createState() => _DrawingWidgetState();
}

class _DrawingWidgetState extends State<DrawingWidget> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  
  bool _showFeedback = false;
  bool _isCorrect = false;
  double _scrollOffset = 0.0;
  final double _virtualWidth = 2000.0; 

  void _clearDrawing() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
      _showFeedback = false;
      _isCorrect = false;
      _scrollOffset = 0.0;
    });
  }

  void _showValidationDialog() {
      final l10n = AppLocalizations.of(context)!;
      final gameProvider = context.read<GameProvider>();
      if (gameProvider.currentWord == null) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.validate),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.drawingValidationQuestion(gameProvider.currentWord!.prompt)),
              const SizedBox(height: 8),
              Text('${l10n.answer} : ${gameProvider.currentWord!.answer}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () {Navigator.pop(context); _handleValidation(false);}, child: Text(l10n.noWrong)),
            ElevatedButton(onPressed: () {Navigator.pop(context); _handleValidation(true);}, child: Text(l10n.yesCorrect)),
          ],
        ),
      );
  }

  void _handleValidation(bool isCorrect) {
    final gameProvider = context.read<GameProvider>();
    setState(() { _showFeedback = true; _isCorrect = isCorrect; });

    if (isCorrect) {
      if (gameProvider.currentWord != null) gameProvider.currentWord!.removed = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _clearDrawing();
          gameProvider.resetCurrentWord();
          if (gameProvider.remainingWords > 0) gameProvider.spinWheel();
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _clearDrawing();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gameProvider = context.watch<GameProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strokeColor = isDark ? Colors.white : Colors.black;
    
    final screenHeight = MediaQuery.of(context).size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double visibleWidth = constraints.maxWidth;
        
        final double maxHeightAvailable = screenHeight * 0.40; 
        final double canvasHeight = (visibleWidth * 0.75).clamp(200.0, maxHeightAvailable);
        
        final double maxScroll = (_virtualWidth - visibleWidth).clamp(0.0, double.infinity);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Feedback animé
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _showFeedback ? 40 : 0,
                child: _showFeedback
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCorrect ? Icons.check_circle : Icons.cancel,
                            color: _isCorrect ? AppColors.success : AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isCorrect ? l10n.correct : l10n.tryAgain,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isCorrect ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(),
              ),

              if (_showFeedback) const SizedBox(height: 8),

              // Canvas de dessin
              Container(
                height: canvasHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _showFeedback
                        ? (_isCorrect ? AppColors.success : AppColors.error)
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: RawGestureDetector(
                    gestures: {
                      EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<EagerPanGestureRecognizer>(
                        () => EagerPanGestureRecognizer(),
                        (EagerPanGestureRecognizer instance) {
                          instance.onStart = (details) {
                            if (!_showFeedback && gameProvider.currentWord != null) {
                              setState(() {
                                final absolutePoint = Offset(details.localPosition.dx + _scrollOffset, details.localPosition.dy);
                                _currentStroke = [absolutePoint];
                              });
                            }
                          };
                          instance.onUpdate = (details) {
                            if (!_showFeedback && gameProvider.currentWord != null) {
                              setState(() {
                                final absolutePoint = Offset(details.localPosition.dx + _scrollOffset, details.localPosition.dy);
                                _currentStroke.add(absolutePoint);
                              });
                            }
                          };
                          instance.onEnd = (details) {
                            if (!_showFeedback && gameProvider.currentWord != null) {
                              setState(() {
                                _strokes.add(List.from(_currentStroke));
                                _currentStroke = [];
                              });
                            }
                          };
                        },
                      ),
                    },
                    child: CustomPaint(
                      painter: _DrawingPainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                        color: strokeColor,
                        scrollOffset: _scrollOffset,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),

              // Slider
              if (maxScroll > 0)
                SizedBox(
                  height: 30, 
                  child: Row(
                    children: [
                      const Icon(Icons.keyboard_arrow_left, color: Colors.grey, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                          ),
                          child: Slider(
                            value: _scrollOffset,
                            min: 0.0,
                            max: maxScroll,
                            onChanged: (value) => setState(() => _scrollOffset = value),
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_right, color: Colors.grey, size: 20),
                    ],
                  ),
                ),

              SizedBox(height: maxScroll > 0 ? 8 : 16),

              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: gameProvider.currentWord != null && !_showFeedback ? _clearDrawing : null,
                      icon: const Icon(Icons.clear, size: 20),
                      label: Text(l10n.clear, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: gameProvider.currentWord != null && !_showFeedback && _strokes.isNotEmpty ? _showValidationDialog : null,
                      icon: const Icon(Icons.check, size: 20),
                      label: Text(l10n.validate, overflow: TextOverflow.ellipsis),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                         visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),

              // Bouton Skip
              TextButton(
                onPressed: gameProvider.currentWord != null && !_showFeedback
                    ? () {
                        _clearDrawing();
                        gameProvider.resetCurrentWord();
                        if (gameProvider.remainingWords > 0) gameProvider.spinWheel();
                      }
                    : null,
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text(l10n.skip, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color color;
  final double scrollOffset;

  _DrawingPainter({required this.strokes, required this.currentStroke, required this.color, required this.scrollOffset});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-scrollOffset, 0);
    final paint = Paint()..color = color..strokeWidth = 4.0..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    // FIXED: Enclosed statements in block
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    if (currentStroke.isNotEmpty) _drawStroke(canvas, currentStroke, paint);
    canvas.restore();
  }

  void _drawStroke(Canvas canvas, List<Offset> stroke, Paint paint) {
    if (stroke.length < 2) {
      if (stroke.isNotEmpty) canvas.drawPoints(ui.PointMode.points, stroke, paint);
      return;
    }
    final path = Path();
    path.moveTo(stroke[0].dx, stroke[0].dy);
    for (int i = 1; i < stroke.length; i++) {
      final p0 = stroke[i - 1];
      final p1 = stroke[i];
      path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    path.lineTo(stroke.last.dx, stroke.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => oldDelegate.strokes != strokes || oldDelegate.currentStroke != currentStroke || oldDelegate.color != color || oldDelegate.scrollOffset != scrollOffset;
}

class EagerPanGestureRecognizer extends PanGestureRecognizer {
  EagerPanGestureRecognizer() : super();
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
  @override
  String get debugDescription => 'eager pan';
}
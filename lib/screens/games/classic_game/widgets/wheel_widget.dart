import 'dart:math';
import 'package:flutter/material.dart';
import 'package:language_learning_app/data/models/word.dart';
import 'package:language_learning_app/core/theme/app_colors.dart';
import 'package:language_learning_app/l10n/app_localizations.dart';

class WheelWidget extends StatefulWidget {
  final List<Word> words;
  final bool isSpinning;
  final Word? selectedWord;
  final VoidCallback onSpin;

  const WheelWidget({
    super.key,
    required this.words,
    required this.isSpinning,
    required this.selectedWord,
    required this.onSpin,
  });

  @override
  State<WheelWidget> createState() => _WheelWidgetState();
}

class _WheelWidgetState extends State<WheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WheelWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !oldWidget.isSpinning) {
      _spinWheel();
    }
  }

  void _spinWheel() {
    final random = Random();
    final extraRotations = 5 + random.nextDouble() * 3;
    final finalRotation = _currentRotation + (extraRotations * 2 * pi);

    _animation = Tween<double>(
      begin: _currentRotation,
      end: finalRotation,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.reset();
    _controller.forward().then((_) {
      setState(() {
        _currentRotation = finalRotation % (2 * pi);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // CORRECTION : Suppression du LayoutBuilder.
    // On utilise MediaQuery pour obtenir la largeur de l'écran.
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calcule le diamètre pour s'adapter à l'écran mobile
    // Max 340px pour ne pas prendre toute la place sur les grands téléphones
    // On enlève un peu de marge (padding du GameScreen est de 32 au total)
    final double availableWidth = screenWidth - 32; 
    final double wheelDiameter = min(availableWidth * 0.9, 340.0);
    final double arrowSize = wheelDiameter * 0.15;

    if (widget.words.isEmpty) {
      return _buildEmptyWheel(context, wheelDiameter);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Flèche au-dessus
          Icon(
            Icons.arrow_drop_down,
            size: arrowSize,
            color: AppColors.error,
          ),
    
          // La roue
          SizedBox(
            width: wheelDiameter,
            height: wheelDiameter,
            child: GestureDetector(
              onTap: widget.isSpinning ? null : widget.onSpin,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animation.value,
                      child: CustomPaint(
                        size: Size(wheelDiameter, wheelDiameter),
                        painter: _WheelPainter(
                          words: widget.words,
                          selectedWord: widget.selectedWord,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
    
          SizedBox(height: wheelDiameter * 0.1),
    
          // Bouton
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250),
            child: ElevatedButton.icon(
              onPressed: widget.isSpinning ? null : widget.onSpin,
              icon: Icon(
                widget.isSpinning ? Icons.hourglass_empty : Icons.casino,
                size: 20,
              ),
              label: Text(
                widget.isSpinning ? l10n.spinning : l10n.spinWheel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWheel(BuildContext context, double size) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              l10n.noWordsAvailable,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// Le Painter ne change pas
class _WheelPainter extends CustomPainter {
  final List<Word> words;
  final Word? selectedWord;

  _WheelPainter({
    required this.words,
    required this.selectedWord,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (words.isEmpty) return;

    final sweepAngle = (2 * pi) / words.length;

    final strokeWidthOuter = radius * 0.015;
    final strokeWidthCenter = radius * 0.03; 

    for (int i = 0; i < words.length; i++) {
      final startAngle = i * sweepAngle - pi / 2;

      final paint = Paint()
        ..color = AppColors.wheelColors[i % AppColors.wheelColors.length]
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
        )
        ..close();

      canvas.drawPath(path, paint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidthOuter;

      canvas.drawPath(path, borderPaint);
    }

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.15, centerPaint);

    final centerBorderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthCenter;

    canvas.drawCircle(center, radius * 0.15, centerBorderPaint);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) {
    return oldDelegate.words != words ||
           oldDelegate.selectedWord != selectedWord;
  }
}
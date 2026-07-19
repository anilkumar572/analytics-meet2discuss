import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color progressColor;
  final double progressPercent;

  /// Real month-over-month percent change, when available (see
  /// [GrowthTrend.monthOverMonthChange]). Null hides the trend pill rather
  /// than showing a made-up number.
  final double? trendPercent;

  /// Real historical values (e.g. the 6-month growth series) rendered as an
  /// inline sparkline in place of the progress bar. Null falls back to the
  /// plain progress bar — never fabricated data.
  final List<double>? sparklineData;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.progressColor = AppColors.primary,
    this.progressPercent = 0.7,
    this.trendPercent,
    this.sparklineData,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _isHovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (_isHovered ? widget.iconColor : Colors.black)
                  .withOpacity(_isHovered ? 0.20 : 0.16),
              blurRadius: _isHovered ? 26 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.surfaceHover : AppColors.surface,
              border: Border.all(
                color: _isHovered
                    ? widget.iconColor.withOpacity(0.5)
                    : AppColors.border,
                width: 1.2,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand-colored accent rail — a lightweight "which metric
                  // is this" cue used across every card in the grid.
                  Container(width: 4, color: widget.iconColor.withOpacity(0.85)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: widget.iconColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(widget.icon,
                                    color: widget.iconColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.cardLabel,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(widget.value,
                                        style: AppTextStyles.statValue),
                                  ],
                                ),
                              ),
                              if (widget.trendPercent != null)
                                _trendPill(widget.trendPercent!),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (widget.sparklineData != null &&
                              widget.sparklineData!.length >= 2)
                            SizedBox(
                              height: 32,
                              width: double.infinity,
                              child: CustomPaint(
                                painter: _SparklinePainter(
                                  widget.sparklineData!,
                                  widget.progressColor,
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: widget.progressPercent.clamp(0.0, 1.0),
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    widget.progressColor),
                                minHeight: 4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _trendPill(double percent) {
    final isUp = percent >= 0;
    final color = isUp ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '${percent.abs().toStringAsFixed(0)}%',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight dependency-free sparkline — a filled trend line through real
/// historical values, used inline in [StatCard] instead of pulling in a
/// second charting widget for a handful of pixels.
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparklinePainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final stepX = size.width / (values.length - 1);

    final points = List.generate(values.length, (i) {
      final x = i * stepX;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      return Offset(x, y);
    });

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [color.withOpacity(0.28), color.withOpacity(0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(points.last, 2.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

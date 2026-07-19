import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants.dart';
import '../models/dashboard_stats.dart';

class GrowthChart extends StatelessWidget {
  final String title;
  final List<GrowthDataPoint> dataPoints;
  final Color lineColor;
  final List<Color> gradientColors;

  const GrowthChart({
    super.key,
    required this.title,
    required this.dataPoints,
    required this.lineColor,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty || dataPoints.every((p) => p.value == 0)) {
      return _shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle.copyWith(fontSize: 15)),
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart_rounded,
                        color: AppColors.textMuted, size: 32),
                    SizedBox(height: 10),
                    Text('No data available yet',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        height: 300,
      );
    }

    final values = dataPoints.map((p) => p.value).toList();
    double maxVal = values.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 10;
    final double yLimit = (maxVal * 1.25).ceilToDouble();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final trend = dataPoints.monthOverMonthChange;
    final current = dataPoints.last.value;

    return _shell(
      gradientColors: gradientColors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.sectionTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          current.toInt().toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('this month',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trend != null) _trendPill(trend),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: LineChart(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOutCubic,
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border.withOpacity(0.6),
                    strokeWidth: 1,
                    dashArray: const [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < dataPoints.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              dataPoints[idx].label,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (dataPoints.length - 1).toDouble(),
                minY: 0,
                maxY: yLimit,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: avg,
                      color: AppColors.textMuted.withOpacity(0.5),
                      strokeWidth: 1,
                      dashArray: const [3, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(bottom: 4, right: 4),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        labelResolver: (_) => 'avg ${avg.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: dataPoints.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.value);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.32,
                    gradient: LinearGradient(colors: gradientColors),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: index == dataPoints.length - 1 ? 5 : 3.5,
                        color: lineColor,
                        strokeWidth: 2,
                        strokeColor: AppColors.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          gradientColors.first.withOpacity(0.28),
                          gradientColors.last.withOpacity(0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppColors.surfaceElevated,
                    tooltipRoundedRadius: 10,
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            s.y.toInt().toString(),
                            GoogleFonts.inter(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((_) {
                      return TouchedSpotIndicatorData(
                        FlLine(color: lineColor.withOpacity(0.4), strokeWidth: 2),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                            radius: 6,
                            color: lineColor,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shell({required Widget child, List<Color>? gradientColors, double? height}) {
    final accentBar = gradientColors == null
        ? const SizedBox(height: 20)
        : Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 3,
                width: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                ),
              ),
            ),
          );

    // The empty-state variant needs a fixed height + Expanded content;
    // the populated variant sizes to its (already height-bound) chart.
    final body = height != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [accentBar, Expanded(child: child)],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [accentBar, child],
          );

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: body,
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
            '${percent.abs().toStringAsFixed(0)}% MoM',
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

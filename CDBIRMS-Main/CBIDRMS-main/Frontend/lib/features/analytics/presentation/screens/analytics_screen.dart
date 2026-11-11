import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer_sidebar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/trend_model.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).fetchTrends();
    });
  }

  bool _canAccessAnalytics(String? role) {
    final norm = (role ?? '').toUpperCase();
    return ['SUPER_ADMIN', 'COMPANY_ADMIN', 'PROJECT_MANAGER'].contains(norm);
  }

  bool _canAccessRevenue(String? role) {
    final norm = (role ?? '').toUpperCase();
    return ['SUPER_ADMIN', 'COMPANY_ADMIN'].contains(norm);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authNotifierProvider).user;
    final userRole = currentUser?.role ?? 'COMPANY_ADMIN';

    final analyticsState = ref.watch(analyticsProvider);
    final notifier = ref.read(analyticsProvider.notifier);

    final hasAccess = _canAccessAnalytics(userRole);
    final canSeeRevenue = _canAccessRevenue(userRole);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Analytics & Trends', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => notifier.fetchTrends(),
          ),
        ],
      ),
      drawer: const AppDrawerSidebar(currentRoute: '/analytics'),
      body: !hasAccess
          ? _buildRoleRestrictedView(userRole)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Range Selector Header
                  _buildRangeSelectorHeader(context, analyticsState, notifier),
                  const SizedBox(height: 24),

                  if (analyticsState.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    )
                  else if (analyticsState.errorMessage != null)
                    _buildErrorCard(analyticsState.errorMessage!)
                  else ...[
                    // Summary Metric Chips
                    _buildSummaryBar(analyticsState, canSeeRevenue),
                    const SizedBox(height: 24),

                    // Chart Cards
                    if (canSeeRevenue) ...[
                      _buildRevenueChartCard(analyticsState),
                      const SizedBox(height: 24),
                    ],

                    _buildActiveProjectsChartCard(analyticsState),
                    const SizedBox(height: 24),

                    _buildTeamActivityChartCard(analyticsState),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildRoleRestrictedView(String role) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text(
                  'Analytics Unavailable for Role',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Executive trend analytics (FC-015) is scoped for leadership and Project Managers.\nRole: ${role.replaceAll('_', ' ')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSelectorHeader(BuildContext context, AnalyticsState state, AnalyticsNotifier notifier) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TIME RANGE & AGGREGATION', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('${state.fromDate}  →  ${state.toDate}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('7 Days', '7_DAYS', state.selectedRangePreset, () => notifier.setPreset('7_DAYS')),
                _buildPresetChip('30 Days', '30_DAYS', state.selectedRangePreset, () => notifier.setPreset('30_DAYS')),
                _buildPresetChip('90 Days', '90_DAYS', state.selectedRangePreset, () => notifier.setPreset('90_DAYS')),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.date_range_rounded, size: 16),
                  label: const Text('Custom', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface),
                        ),
                        child: child!,
                      ),
                    );
                    if (range != null) {
                      final from = range.start.toIso8601String().split('T')[0];
                      final to = range.end.toIso8601String().split('T')[0];
                      notifier.setCustomRange(from, to);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String presetKey, String currentPreset, VoidCallback onTap) {
    final isSelected = currentPreset == presetKey;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.show_chart_rounded, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(AnalyticsState state, bool canSeeRevenue) {
    double totalRevenue = 0;
    double maxActiveProjects = 0;
    double totalActivity = 0;

    for (final series in state.seriesList) {
      if (series.metric == 'REVENUE') {
        totalRevenue = series.points.fold(0, (sum, p) => sum + p.value);
      } else if (series.metric == 'ACTIVE_PROJECTS') {
        maxActiveProjects = series.points.isNotEmpty ? series.points.last.value : 0;
      } else if (series.metric == 'TEAM_ACTIVITY') {
        totalActivity = series.points.fold(0, (sum, p) => sum + p.value);
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isMobile ? 1 : (canSeeRevenue ? 3 : 2),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 2.8 : 2.2,
        children: [
          if (canSeeRevenue)
            _buildStatBox('Period Realized Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.monetization_on_outlined, AppColors.success),
          _buildStatBox('Active Projects', maxActiveProjects.toInt().toString(), Icons.folder_special_outlined, AppColors.primary),
          _buildStatBox('Team Updates & Tasks', totalActivity.toInt().toString(), Icons.bolt_outlined, AppColors.secondary),
        ],
      );
    });
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChartCard(AnalyticsState state) {
    final series = state.seriesList.firstWhere(
      (s) => s.metric == 'REVENUE',
      orElse: () => TrendSeriesModel(metric: 'REVENUE', points: []),
    );

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.show_chart_rounded, color: AppColors.success, size: 22),
                SizedBox(width: 10),
                Text('Realized Revenue Trend (₹)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Realized client payments over selected timeframe', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: _LineChartCanvas(points: series.points, lineColor: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveProjectsChartCard(AnalyticsState state) {
    final series = state.seriesList.firstWhere(
      (s) => s.metric == 'ACTIVE_PROJECTS',
      orElse: () => TrendSeriesModel(metric: 'ACTIVE_PROJECTS', points: []),
    );

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline_rounded, color: AppColors.primary, size: 22),
                SizedBox(width: 10),
                Text('Active Projects Trend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Active project pipeline volume over time', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: _LineChartCanvas(points: series.points, lineColor: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamActivityChartCard(AnalyticsState state) {
    final series = state.seriesList.firstWhere(
      (s) => s.metric == 'TEAM_ACTIVITY',
      orElse: () => TrendSeriesModel(metric: 'TEAM_ACTIVITY', points: []),
    );

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: AppColors.secondary, size: 22),
                SizedBox(width: 10),
                Text('Team Activity & Task Output', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Site updates posted + tasks completed per date bucket', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: _BarChartCanvas(points: series.points, barColor: AppColors.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Line Chart Canvas Widget
class _LineChartCanvas extends StatelessWidget {
  final List<TrendPointModel> points;
  final Color lineColor;

  const _LineChartCanvas({required this.points, required this.lineColor});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No point data for selected range', style: TextStyle(color: AppColors.textMuted, fontSize: 12)));
    }

    final maxValue = points.fold<double>(0, (max, p) => p.value > max ? p.value : max);
    final effectiveMax = maxValue == 0 ? 10.0 : maxValue * 1.2;

    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(points: points, maxValue: effectiveMax, lineColor: lineColor),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<TrendPointModel> points;
  final double maxValue;
  final Color lineColor;

  _LineChartPainter({required this.points, required this.maxValue, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const paddingBottom = 24.0;
    const paddingTop = 12.0;
    const paddingLeft = 36.0;
    const paddingRight = 12.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Draw horizontal grid lines
    const gridRows = 3;
    for (int i = 0; i <= gridRows; i++) {
      final y = paddingTop + (chartHeight / gridRows) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    final path = Path();
    final fillPath = Path();

    final stepX = points.length > 1 ? chartWidth / (points.length - 1) : chartWidth;

    fillPath.moveTo(paddingLeft, paddingTop + chartHeight);

    for (int i = 0; i < points.length; i++) {
      final x = paddingLeft + (stepX * i);
      final normalizedY = points[i].value / maxValue;
      final y = paddingTop + chartHeight - (normalizedY * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      // Draw point dot
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = lineColor);
    }

    fillPath.lineTo(paddingLeft + chartWidth, paddingTop + chartHeight);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

/// Custom Bar Chart Canvas Widget
class _BarChartCanvas extends StatelessWidget {
  final List<TrendPointModel> points;
  final Color barColor;

  const _BarChartCanvas({required this.points, required this.barColor});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('No activity data for selected range', style: TextStyle(color: AppColors.textMuted, fontSize: 12)));
    }

    final maxValue = points.fold<double>(0, (max, p) => p.value > max ? p.value : max);
    final effectiveMax = maxValue == 0 ? 5.0 : maxValue * 1.25;

    return CustomPaint(
      size: Size.infinite,
      painter: _BarChartPainter(points: points, maxValue: effectiveMax, barColor: barColor),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<TrendPointModel> points;
  final double maxValue;
  final Color barColor;

  _BarChartPainter({required this.points, required this.maxValue, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    const paddingBottom = 24.0;
    const paddingTop = 12.0;
    const paddingLeft = 36.0;
    const paddingRight = 12.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Draw horizontal grid lines
    const gridRows = 3;
    for (int i = 0; i <= gridRows; i++) {
      final y = paddingTop + (chartHeight / gridRows) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
    }

    final totalBars = points.length;
    final barWidth = (chartWidth / totalBars) * 0.6;
    final gap = chartWidth / totalBars;

    for (int i = 0; i < totalBars; i++) {
      final x = paddingLeft + (gap * i) + (gap - barWidth) / 2;
      final normalizedY = points[i].value / maxValue;
      final h = normalizedY * chartHeight;
      final y = paddingTop + chartHeight - h;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, h.clamp(2.0, chartHeight)),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) => true;
}

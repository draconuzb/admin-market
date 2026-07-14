import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../models/admin.dart';
import '../../../shared/widgets/async_views.dart';
import '../factory_providers.dart';

class FactoryStatsScreen extends ConsumerWidget {
  const FactoryStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(factoryStatsProvider);
    final analytics = ref.watch(factoryAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text('factory.stats_title'.tr())),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(factoryStatsProvider);
          ref.invalidate(factoryAnalyticsProvider);
        },
        child: stats.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(factoryStatsProvider),
          ),
          data: (s) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(child: _miniStat('factory.revenue_month'.tr(),
                    formatPrice(s.revenueThisMonth), Icons.payments, AppTheme.success)),
                const SizedBox(width: 12),
                Expanded(child: _miniStat('factory.pending'.tr(),
                    '${s.pendingOrders}', Icons.hourglass_top, AppTheme.warning)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _miniStat('factory.orders_total'.tr(),
                    '${s.ordersTotal}', Icons.receipt_long, AppTheme.accent)),
                const SizedBox(width: 12),
                Expanded(child: _miniStat('factory.commission_month'.tr(),
                    formatPrice(s.commissionThisMonth), Icons.percent, AppTheme.purple)),
              ]),
              const SizedBox(height: 20),
              analytics.when(
                loading: () => const SizedBox(height: 200, child: LoadingView()),
                error: (e, _) => const SizedBox(),
                data: (a) => Column(
                  children: [
                    _RevenueChart(daily: a.daily),
                    const SizedBox(height: 20),
                    _TopProducts(items: a.topProducts),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      );
}

/// Abbreviates large so'm amounts for chart axes (e.g. 1 200 000 -> 1.2M).
String _abbrev(num v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toStringAsFixed(0);
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.daily});
  final List<DailyPoint> daily;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = daily.fold<double>(0, (m, d) => d.revenue > m ? d.revenue.toDouble() : m);
    final maxY = maxRevenue <= 0 ? 1.0 : maxRevenue * 1.2;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('factory.revenue_14d'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceBetween,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.textPrimary,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      formatPrice(daily[group.x].revenue),
                      const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 3,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppTheme.separator, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: maxY / 3,
                      getTitlesWidget: (v, _) => Text(_abbrev(v),
                          style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        // Show every 3rd day label to avoid clutter.
                        if (i % 3 != 0 || i >= daily.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(daily[i].date.substring(5).replaceAll('-', '.'),
                              style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < daily.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: daily[i].revenue.toDouble(),
                        color: AppTheme.accent,
                        width: 7,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.items});
  final List<TopProduct> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('factory.top_products'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            Row(
              children: [
                Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(items[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                Text('${items[i].quantity} ${'product.units'.tr()}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyReport {
  final DateTime date;
  final int totalOrders;
  final int totalRevenue;

  const DailyReport({required this.date, required this.totalOrders, required this.totalRevenue});
}

class MonthlyReport {
  final String month;
  final int totalOrders;
  final int totalRevenue;

  const MonthlyReport({required this.month, required this.totalOrders, required this.totalRevenue});
}

class ReportController extends AsyncNotifier<List<DailyReport>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<DailyReport>> build() async {
    return _getDailyReports();
  }

  Future<List<DailyReport>> _getDailyReports() async {
    final data = await _supabase
        .from('orders')
        .select('created_at, total_amount, payment_status')
        .eq('payment_status', 'paid')
        .order('created_at', ascending: false);

    final Map<String, DailyReport> grouped = {};

    for (final row in data) {
      final dateStr = (row['created_at'] as String).substring(0, 10);
      if (grouped.containsKey(dateStr)) {
        final existing = grouped[dateStr]!;
        grouped[dateStr] = DailyReport(
          date: existing.date,
          totalOrders: existing.totalOrders + 1,
          totalRevenue: existing.totalRevenue + ((row['total_amount'] as num).toInt()),
        );
      } else {
        grouped[dateStr] = DailyReport(
          date: DateTime.parse(row['created_at'] as String),
          totalOrders: 1,
          totalRevenue: (row['total_amount'] as num).toInt(),
        );
      }
    }

    return grouped.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<MonthlyReport>> getMonthlyReports() async {
    final daily = await _getDailyReports();
    final Map<String, MonthlyReport> grouped = {};

    for (final d in daily) {
      final monthKey = '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}';
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final monthLabel = '${monthNames[d.date.month - 1]} ${d.date.year}';

      if (grouped.containsKey(monthKey)) {
        final existing = grouped[monthKey]!;
        grouped[monthKey] = MonthlyReport(
          month: existing.month,
          totalOrders: existing.totalOrders + d.totalOrders,
          totalRevenue: existing.totalRevenue + d.totalRevenue,
        );
      } else {
        grouped[monthKey] = MonthlyReport(
          month: monthLabel,
          totalOrders: d.totalOrders,
          totalRevenue: d.totalRevenue,
        );
      }
    }

    return grouped.values.toList()..sort((a, b) => b.month.compareTo(a.month));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _getDailyReports());
  }
}

final reportProvider = AsyncNotifierProvider<ReportController, List<DailyReport>>(ReportController.new);
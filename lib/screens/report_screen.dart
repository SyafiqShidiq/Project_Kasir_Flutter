import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_file_dialog/flutter_file_dialog.dart'; // <-- TAMBAHKAN INI
import '../main.dart';
import '../providers/report_provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/smart_cashier_theme.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cashier'),
        ),
        title: const Text('Laporan Penjualan'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color.fromARGB(255, 243, 3, 3),
          labelColor: const Color.fromARGB(255, 243, 3, 3),
          unselectedLabelColor: const Color.fromARGB(255, 243, 3, 3),
          tabs: const [
            Tab(text: 'Harian', icon: Icon(Icons.calendar_today, size: 18)),
            Tab(text: 'Bulanan', icon: Icon(Icons.calendar_month, size: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            onPressed: () {
              print('TOMBOL EXPORT DIPENCET!');
              _exportPDF();
            },
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DailyReportTab(),
          _MonthlyReportTab(),
        ],
      ),
    );
  }

  Future<void> _exportPDF() async {
    try {
      print('===== START EXPORT PDF =====');
      
      final reportController = ref.read(reportProvider.notifier);
      final daily = await reportController.build();
      final monthly = await reportController.getMonthlyReports();

      final pdf = pw.Document();
      final font = pw.Font.times();
      final fontBold = pw.Font.timesBold();

      final totalRevenue = daily.fold<int>(0, (sum, d) => sum + d.totalRevenue);
      final totalOrders = daily.fold<int>(0, (sum, d) => sum + d.totalOrders);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Laporan Penjualan SmartCashier', style: pw.TextStyle(font: fontBold, fontSize: 20)),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Total Revenue: Rp${_format(totalRevenue)}', style: pw.TextStyle(font: font)),
            pw.Text('Total Orders: $totalOrders', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 16),
            pw.Header(level: 1, text: 'Laporan Harian'),
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Orders', 'Revenue'],
              data: daily.map((d) => [
                '${d.date.day}/${d.date.month}/${d.date.year}',
                '${d.totalOrders}',
                'Rp${_format(d.totalRevenue)}',
              ]).toList(),
              headerStyle: pw.TextStyle(font: fontBold),
              cellStyle: pw.TextStyle(font: font),
            ),
            pw.SizedBox(height: 16),
            pw.Header(level: 1, text: 'Laporan Bulanan'),
            pw.TableHelper.fromTextArray(
              headers: ['Bulan', 'Orders', 'Revenue'],
              data: monthly.map((m) => [m.month, '${m.totalOrders}', 'Rp${_format(m.totalRevenue)}']).toList(),
              headerStyle: pw.TextStyle(font: fontBold),
              cellStyle: pw.TextStyle(font: font),
            ),
          ],
        ),
      );

      // ===== PERBAIKAN: Gunakan flutter_file_dialog =====
      final bytes = await pdf.save();
      
      final params = SaveFileDialogParams(
        data: bytes,
        fileName: 'laporan_penjualan_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      final filePath = await FlutterFileDialog.saveFile(params: params);
      
      if (filePath != null) {
        print("✅ PDF berhasil disimpan di: $filePath");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ PDF berhasil disimpan!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print("❌ Penyimpanan dibatalkan pengguna.");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⏹️ Penyimpanan dibatalkan'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      print('===== EXPORT PDF SELESAI =====');
      
    } catch (e, stackTrace) {
      print('===== ERROR EXPORT PDF =====');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal export PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _format(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

class _DailyReportTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportProvider);

    return reportAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (reports) {
        if (reports.isEmpty) return const Center(child: Text('Belum ada data penjualan'));

        final total = reports.fold<int>(0, (sum, r) => sum + r.totalRevenue);

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: SmartCashierTheme.primary.withValues(alpha: 0.1),
              child: Column(children: [
                Text('Total Revenue', style: TextStyle(color: SmartCashierTheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Rp${_formatStatic(total)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: SmartCashierTheme.primaryDark)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: SmartCashierTheme.primary.withValues(alpha: 0.1),
                      child: Text('${report.date.day}', style: TextStyle(color: SmartCashierTheme.primary, fontWeight: FontWeight.w800)),
                    ),
                    title: Text('${report.date.day}/${report.date.month}/${report.date.year}'),
                    subtitle: Text('${report.totalOrders} pesanan'),
                    trailing: Text('Rp${_formatStatic(report.totalRevenue)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatStatic(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}

class _MonthlyReportTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<MonthlyReport>>(
      future: ref.read(reportProvider.notifier).getMonthlyReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Belum ada data penjualan'));
        }

        final reports = snapshot.data!;
        final total = reports.fold<int>(0, (sum, r) => sum + r.totalRevenue);

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: SmartCashierTheme.primary.withValues(alpha: 0.1),
              child: Column(children: [
                Text('Total Revenue', style: TextStyle(color: SmartCashierTheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Rp${_formatStatic(total)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: SmartCashierTheme.primaryDark)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: SmartCashierTheme.primary.withValues(alpha: 0.1),
                      child: Icon(Icons.calendar_month, color: SmartCashierTheme.primary, size: 20),
                    ),
                    title: Text(report.month),
                    subtitle: Text('${report.totalOrders} pesanan'),
                    trailing: Text('Rp${_formatStatic(report.totalRevenue)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatStatic(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
}
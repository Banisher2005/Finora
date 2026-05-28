import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/report_provider.dart';
import '../providers/theme_provider.dart';
import '../models/monthly_report.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';
import '../utils/pdf_generator.dart';

class SavedReportsScreen extends StatelessWidget {
  const SavedReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;
    final reports = reportProvider.reports;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Text(
                'Saved Reports',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
            Expanded(
              child: reports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 60,
                            color: isDark ? Colors.white24 : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No saved reports yet',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondary : Colors.grey[500],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reports are auto-generated at month end',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return _ReportCard(
                          report: report,
                          currency: currency,
                          isDark: isDark,
                          onExport: () => _exportPdf(context, report, currency),
                        )
                            .animate()
                            .fadeIn(
                                duration: 300.ms,
                                delay: (index * 60).ms)
                            .slideY(begin: 0.1);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(
      BuildContext context, MonthlyReport report, String currency) async {
    try {
      final file = await PdfGenerator.generateReport(report, currency);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Finora Report - ${AppDateUtils.formatMonthYear(report.month, report.year)}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

class _ReportCard extends StatelessWidget {
  final MonthlyReport report;
  final String currency;
  final bool isDark;
  final VoidCallback onExport;

  const _ReportCard({
    required this.report,
    required this.currency,
    required this.isDark,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final savingsPositive = report.savings >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDateUtils.formatMonthYear(report.month, report.year),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  Text(
                    'Generated ${AppDateUtils.formatDate(report.generatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onExport,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    color: AppColors.accentBlue,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: isDark ? Colors.white10 : Colors.grey[100]),
          const SizedBox(height: 16),
          Row(
            children: [
              _ReportStat(
                label: 'Income',
                value: CurrencyFormatter.format(report.totalIncome, currency),
                color: AppColors.incomeGreen,
                isDark: isDark,
              ),
              _ReportStat(
                label: 'Expense',
                value: CurrencyFormatter.format(report.totalExpense, currency),
                color: AppColors.expenseRed,
                isDark: isDark,
              ),
              _ReportStat(
                label: 'Savings',
                value: CurrencyFormatter.format(
                    report.savings.clamp(0, double.infinity), currency),
                color: savingsPositive
                    ? AppColors.savingsBlue
                    : AppColors.expenseRed,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _ReportStat({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textSecondary : Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

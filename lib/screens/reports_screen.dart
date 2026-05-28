import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction.dart';
import '../models/monthly_report.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';
import '../utils/pdf_generator.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currency = themeProvider.currency;
    final now = DateTime.now();

    final expenseBreakdown = txProvider.getExpenseBreakdown();
    final incomeBreakdown = txProvider.getIncomeBreakdown();
    final last6Months = txProvider.getLast6MonthsData();
    final totalIncome = txProvider.currentMonthIncome;
    final totalExpense = txProvider.currentMonthExpense;
    final savings = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        ),
                      ),
                      Text(
                        AppDateUtils.fullMonthName(now.month) + ' ${now.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondary : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showCustomReportSheet(
                        context, txProvider, isDark, currency),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accentPurple.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.date_range_rounded,
                              color: AppColors.accentPurple, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Custom',
                            style: TextStyle(
                              color: AppColors.accentPurple,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms),
            ),

            // ── Summary Cards ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _ReportSummaryCard(
                    label: 'Income',
                    amount: CurrencyFormatter.format(totalIncome, currency),
                    color: AppColors.incomeGreen,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _ReportSummaryCard(
                    label: 'Expense',
                    amount: CurrencyFormatter.format(totalExpense, currency),
                    color: AppColors.expenseRed,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 10),
                  _ReportSummaryCard(
                    label: 'Savings',
                    amount: CurrencyFormatter.format(savings.clamp(0, double.infinity), currency),
                    color: AppColors.savingsBlue,
                    isDark: isDark,
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            ),

            // ── Tab Bar ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.accentBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? Colors.white54 : Colors.grey[500],
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Expenses'),
                    Tab(text: 'Income'),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
            ),

            const SizedBox(height: 16),

            // ── Tab Views ────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Overview (Bar Chart) ─────────────────
                  _buildOverviewTab(last6Months, isDark, currency),

                  // ── Expense Pie Chart ────────────────────
                  _buildPieTab(
                    breakdown: expenseBreakdown,
                    title: 'Expense Breakdown',
                    emptyMessage: 'No expenses this month',
                    isDark: isDark,
                    currency: currency,
                  ),

                  // ── Income Pie Chart ─────────────────────
                  _buildPieTab(
                    breakdown: incomeBreakdown,
                    title: 'Income Breakdown',
                    emptyMessage: 'No income this month',
                    isDark: isDark,
                    currency: currency,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom date range report ─────────────────────────────────────────────
  Future<void> _showCustomReportSheet(
    BuildContext context,
    TransactionProvider txProvider,
    bool isDark,
    String currency,
  ) async {
    DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
    DateTime endDate = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // Calculate stats for range
          final txns = txProvider.transactions.where((t) =>
              !t.date.isBefore(DateTime(startDate.year, startDate.month, startDate.day)) &&
              !t.date.isAfter(DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59))).toList();
          final income = txns.where((t) => t.type == TransactionType.income)
              .fold(0.0, (s, t) => s + t.amount);
          final expense = txns.where((t) => t.type == TransactionType.expense)
              .fold(0.0, (s, t) => s + t.amount);
          final savings = income - expense;

          Future<void> pickStart() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: startDate,
              firstDate: DateTime(2020),
              lastDate: endDate,
            );
            if (picked != null) setS(() => startDate = picked);
          }

          Future<void> pickEnd() async {
            final picked = await showDatePicker(
              context: ctx,
              initialDate: endDate,
              firstDate: startDate,
              lastDate: DateTime.now(),
            );
            if (picked != null) setS(() => endDate = picked);
          }

          Future<void> exportPdf() async {
            try {
              final expBreak = <String, double>{};
              final incBreak = <String, double>{};
              for (final t in txns) {
                if (t.type == TransactionType.expense) {
                  expBreak[t.category] = (expBreak[t.category] ?? 0) + t.amount;
                } else {
                  incBreak[t.source] = (incBreak[t.source] ?? 0) + t.amount;
                }
              }
              final report = MonthlyReport(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                month: startDate.month,
                year: startDate.year,
                totalIncome: income,
                totalExpense: expense,
                savings: savings,
                expenseBreakdown: expBreak,
                incomeBreakdown: incBreak,
                generatedAt: DateTime.now(),
              );
              final file = await PdfGenerator.generateReport(report, currency);
              await Share.shareXFiles(
                [XFile(file.path)],
                text: 'Finora Custom Report: ${AppDateUtils.formatDate(startDate)} – ${AppDateUtils.formatDate(endDate)}',
              );
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            }
          }

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Custom Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    )),
                const SizedBox(height: 4),
                Text('${txns.length} transactions in range',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    )),
                const SizedBox(height: 20),

                // Date pickers
                Row(
                  children: [
                    Expanded(child: _DatePickButton(
                      label: 'From',
                      value: AppDateUtils.formatDateShort(startDate),
                      isDark: isDark,
                      onTap: pickStart,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _DatePickButton(
                      label: 'To',
                      value: AppDateUtils.formatDateShort(endDate),
                      isDark: isDark,
                      onTap: pickEnd,
                    )),
                  ],
                ),
                const SizedBox(height: 20),

                // Stats cards
                Row(children: [
                  _CustomStatCard(
                    label: 'Income', amount: income, currency: currency,
                    color: AppColors.incomeGreen, isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _CustomStatCard(
                    label: 'Expense', amount: expense, currency: currency,
                    color: AppColors.expenseRed, isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _CustomStatCard(
                    label: 'Net', amount: savings.abs(), currency: currency,
                    color: savings >= 0 ? AppColors.savingsBlue : AppColors.expenseRed,
                    isDark: isDark,
                  ),
                ]),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: txns.isEmpty ? null : exportPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Export as PDF',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
    List<Map<String, dynamic>> data,
    bool isDark,
    String currency,
  ) {
    if (data.every((d) => (d['income'] as double) == 0 && (d['expense'] as double) == 0)) {
      return _emptyChart(isDark, 'No data to show yet');
    }

    double maxY = 0;
    for (final d in data) {
      final max = [d['income'] as double, d['expense'] as double].reduce((a, b) => a > b ? a : b);
      if (max > maxY) maxY = max;
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 1000;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Container(
            height: 280,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        isDark ? AppColors.darkCardElevated : Colors.white,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final d = data[group.x];
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${isIncome ? 'Income' : 'Expense'}\n${CurrencyFormatter.formatCompact(rod.toY, currency)}',
                        TextStyle(
                          color: isIncome ? AppColors.incomeGreen : AppColors.expenseRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final d = data[value.toInt()];
                        return Text(
                          AppDateUtils.monthName(d['month'] as int),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: (d['income'] as double),
                        color: AppColors.incomeGreen,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: (d['expense'] as double),
                        color: AppColors.expenseRed,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 600),
              swapAnimationCurve: Curves.easeInOut,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: AppColors.incomeGreen, label: 'Income'),
              const SizedBox(width: 24),
              _Legend(color: AppColors.expenseRed, label: 'Expense'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieTab({
    required Map<String, double> breakdown,
    required String title,
    required String emptyMessage,
    required bool isDark,
    required String currency,
  }) {
    if (breakdown.isEmpty) return _emptyChart(isDark, emptyMessage);

    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          Container(
            height: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 60,
                sections: entries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final isTouched = i == _touchedIndex;
                  final color =
                      AppColors.categoryColors[i % AppColors.categoryColors.length];
                  return PieChartSectionData(
                    color: color,
                    value: e.value,
                    title: isTouched
                        ? '${(e.value / total * 100).toStringAsFixed(1)}%'
                        : '',
                    radius: isTouched ? 70 : 58,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
            ),
          ),
          const SizedBox(height: 16),
          // Legend list
          ...entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final color = AppColors.categoryColors[i % AppColors.categoryColors.length];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                    ),
                  ),
                  Text(
                    '${(e.value / total * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.format(e.value, currency),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _emptyChart(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 60,
            color: isDark ? Colors.white24 : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : Colors.grey[500],
              fontSize: 15,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isDark;

  const _ReportSummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondary : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
      ],
    );
  }
}

// ── Custom report helper widgets ─────────────────────────────────────────────

class _DatePickButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _DatePickButton({
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 16, color: AppColors.accentPurple),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textSecondary : Colors.grey[500],
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomStatCard extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  final bool isDark;

  const _CustomStatCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(CurrencyFormatter.format(amount, currency),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ),
            if (amount >= 1000)
              Text(CurrencyFormatter.wordLabel(amount, currency),
                  style: TextStyle(
                      fontSize: 9,
                      color: color.withOpacity(0.6),
                      fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

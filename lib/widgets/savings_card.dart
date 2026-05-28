import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';

class SavingsCard extends StatelessWidget {
  final double combinedSavings;
  final double accountSavings;
  final String accountName;
  final Color accountColor;
  final String currency;
  final bool isDark;

  const SavingsCard({
    super.key,
    required this.combinedSavings,
    required this.accountSavings,
    required this.accountName,
    required this.accountColor,
    required this.currency,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final combinedPositive = combinedSavings >= 0;
    final accountPositive = accountSavings >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: combinedPositive
              ? (isDark
                  ? [const Color(0xFF0D2818), const Color(0xFF0A1F14)]
                  : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)])
              : (isDark
                  ? [const Color(0xFF2D1212), const Color(0xFF1A0A0A)]
                  : [const Color(0xFFCC3333), const Color(0xFF991111)]),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (combinedPositive
                    ? AppColors.incomeGreen
                    : AppColors.expenseRed)
                .withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Combined row ───────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      combinedPositive
                          ? Icons.savings_rounded
                          : Icons.trending_down_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      combinedPositive ? 'Net Savings' : 'Net Deficit',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'All Accounts',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Combined amount ────────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${combinedPositive ? '' : '−'}${CurrencyFormatter.format(combinedSavings.abs(), currency)}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (combinedSavings.abs() >= 1000)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                CurrencyFormatter.wordLabel(combinedSavings.abs(), currency),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ── Divider ───────────────────────────────────
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 14),

          // ── Account-specific row ──────────────────────
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accountColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  accountPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: accountColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      accountName,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${accountPositive ? '' : '−'}${CurrencyFormatter.formatCompact(accountSavings.abs(), currency)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (accountPositive
                          ? AppColors.incomeGreen
                          : AppColors.expenseRed)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  accountPositive ? 'Profit' : 'Loss',
                  style: TextStyle(
                    color: accountPositive
                        ? AppColors.incomeGreen
                        : AppColors.expenseRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

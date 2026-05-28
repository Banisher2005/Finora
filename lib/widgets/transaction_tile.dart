import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../themes/app_theme.dart';
import '../utils/app_utils.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final String currency;
  final bool isDark;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.currency,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.incomeGreen : AppColors.expenseRed;
    final categoryIcon = _getCategoryIcon(transaction.category, isIncome);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2C2C2E) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Transaction?',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            content: Text(
              'Delete ${isIncome ? transaction.source : transaction.category} '
              '(${isIncome ? "+" : "-"}${CurrencyFormatter.format(transaction.amount, currency)})?'
              '\n\nThis cannot be undone.',
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey[700]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx, true);
                },
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B6B)),
                child: const Text('Delete',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 24),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Category Icon ──────────────────────────
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(categoryIcon, color: color, size: 22),
            ),
            const SizedBox(width: 14),

            // ── Info ───────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIncome ? transaction.source : transaction.category,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction.note.isNotEmpty
                        ? transaction.note
                        : AppDateUtils.formatDate(transaction.date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondary : Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Amount ─────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, currency)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppDateUtils.formatDateShort(transaction.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondary : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category, bool isIncome) {
    if (isIncome) {
      return switch (category.toLowerCase()) {
        'salary' => Icons.work_outline_rounded,
        'business' => Icons.business_center_outlined,
        'freelance' => Icons.laptop_outlined,
        'investments' => Icons.trending_up_rounded,
        'rental' => Icons.home_outlined,
        'previous month savings' => Icons.savings_outlined,
        'gift' => Icons.card_giftcard_outlined,
        _ => Icons.attach_money_rounded,
      };
    }
    return switch (category.toLowerCase()) {
      'food' => Icons.restaurant_outlined,
      'fuel' => Icons.local_gas_station_outlined,
      'rent' => Icons.home_outlined,
      'utilities' => Icons.bolt_outlined,
      'medical' => Icons.medical_services_outlined,
      'shopping' => Icons.shopping_bag_outlined,
      'travel' => Icons.flight_outlined,
      'entertainment' => Icons.movie_outlined,
      'education' => Icons.school_outlined,
      'subscriptions' => Icons.subscriptions_outlined,
      _ => Icons.receipt_outlined,
    };
  }
}

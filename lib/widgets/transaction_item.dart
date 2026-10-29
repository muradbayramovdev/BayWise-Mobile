import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel tx;
  final Future<void> Function()? onDelete;
  final VoidCallback? onEdit;

  const TransactionItem({
    super.key,
    required this.tx,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final locale = context.watch<LocaleProvider>();
    final isIncome = tx.type == 'income';
    final amountColor = isIncome ? AppColors.accentGreen : AppColors.accentRed;
    final sign = isIncome ? '+' : '-';

    DateTime? date;
    try {
      date = DateTime.parse(tx.date);
    } catch (_) {}

    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final iconBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subTextColor = isDark ? AppColors.dark400 : AppColors.light400;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: !isDark ? Border.all(color: AppColors.light600) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(isIncome ? '💰' : '💳', style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isEmpty ? locale.t('no_description') : tx.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${locale.translateCategory(tx.category)}${date != null ? ' · ${formatDate(date)}' : ''}',
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
              ],
            ),
          ),
          Text(
            '$sign ${locale.currencySymbol} ${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );

    if (onDelete == null && onEdit == null) return content;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: (onDelete != null && onEdit != null)
          ? DismissDirection.horizontal
          : (onDelete != null ? DismissDirection.endToStart : DismissDirection.startToEnd),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.accentTeal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 26),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.accentRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          if (onEdit != null) {
            onEdit!();
          }
          return false; // Öğeyi düzenlerken listede tut
        } else {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: cardBg,
              title: Text(locale.t('delete'), style: TextStyle(color: textColor)),
              content: Text(
                '"${tx.description.isEmpty ? 'Bu işlemi' : tx.description}" silmek istediğinize emin misiniz?',
                style: TextStyle(color: subTextColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(locale.t('cancel')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentRed,
                  ),
                  child: Text(locale.t('delete')),
                ),
              ],
            ),
          ) ?? false;
        }
      },
      onDismissed: (dir) {
        if (dir == DismissDirection.endToStart && onDelete != null) {
          onDelete!();
        }
      },
      child: content,
    );
  }
}

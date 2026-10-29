import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction_model.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_toast.dart';

class DailySummaryCard extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String workspaceName;
  final String workspaceEmoji;

  const DailySummaryCard({
    super.key,
    required this.transactions,
    required this.workspaceName,
    required this.workspaceEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<LocaleProvider>();
    final now = DateTime.now();

    // Bugünkü işlemleri filtrele
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final todayTx = transactions.where((t) => t.date == todayStr).toList();

    double todayIncome = 0;
    double todayExpense = 0;

    for (final tx in todayTx) {
      if (tx.type == 'income') {
        todayIncome += tx.amount;
      } else {
        todayExpense += tx.amount;
      }
    }

    final todayNet = todayIncome - todayExpense;

    // Duruma göre motivasyon mesajı ve rozet rengi
    String title = '✨ ${locale.t('summary')}';
    String message = locale.t('summary_empty_msg');
    String emoji = '🌱';
    List<Color> gradientColors = isDark
        ? [const Color(0xFF1E2535), const Color(0xFF161B24)]
        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)];
    Color accent = AppColors.accentPurple;

    if (todayTx.isNotEmpty) {
      if (todayNet > 0) {
        title = locale.t('summary_great_title');
        message = locale.t('summary_great_msg');
        emoji = '💎';
        gradientColors = isDark
            ? [const Color(0xFF0F3E3B), const Color(0xFF161B24)]
            : [const Color(0xFFE0F2FE), const Color(0xFFF0FDF4)];
        accent = AppColors.accentTeal;
      } else if (todayNet < 0) {
        title = locale.t('summary_invest_title');
        message = locale.t('summary_invest_msg');
        emoji = '🛡️';
        gradientColors = isDark
            ? [const Color(0xFF3B1E2E), const Color(0xFF161B24)]
            : [const Color(0xFFFEE2E2), const Color(0xFFFFF1F2)];
        accent = AppColors.accentPurple;
      } else {
        title = locale.t('summary_balance_title');
        message = locale.t('summary_balance_msg');
        emoji = '🎯';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: accent.withOpacity(isDark ? 0.4 : 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üst satır: Başlık ve Kasa rozeti
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 19)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : AppColors.light100,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatDate(now),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.dark400 : AppColors.light400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.dark800 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: accent, width: 1.2),
                        ),
                        child: Text(
                          '$workspaceEmoji $workspaceName',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: isDark ? AppColors.dark200 : AppColors.light200,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Orta: İstatistik Hapları
                  Row(
                    children: [
                      Expanded(
                        child: _StatPill(
                          label: locale.t('today_income'),
                          amount: todayIncome,
                          color: AppColors.accentGreen,
                          icon: Icons.arrow_downward_rounded,
                          symbol: locale.currencySymbol,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _StatPill(
                          label: locale.t('today_expense'),
                          amount: todayExpense,
                          color: AppColors.accentRed,
                          icon: Icons.arrow_upward_rounded,
                          symbol: locale.currencySymbol,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _StatPill(
                          label: locale.t('net_status'),
                          amount: todayNet,
                          color: todayNet >= 0 ? AppColors.accentTeal : AppColors.accentPurple,
                          icon: Icons.account_balance_wallet_rounded,
                          symbol: locale.currencySymbol,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 8),
                  // Alt satır: Paylaş butonu (Oyunlaştırma)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: AppColors.accentAmber, size: 17),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                locale.t('slogan'),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.dark300 : AppColors.light300,
                                  letterSpacing: 0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _shareSummary(context, todayIncome, todayExpense, todayNet, now, locale.currencySymbol),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.accentPurple, AppColors.accentTeal],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPurple.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.share_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                locale.t('share'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _shareSummary(
    BuildContext context,
    double income,
    double expense,
    double net,
    DateTime date,
    String symbol,
  ) {
    final dateStr = formatDate(date);
    final sign = net >= 0 ? '+' : '';
    final text = '''
👑 Baywise ($workspaceEmoji $workspaceName) Günlük Özetim:
📅 Tarih: $dateStr

💵 Bugünkü Gelir: $symbol${income.toStringAsFixed(2)}
🛍️ Bugünkü Gider: $symbol${expense.toStringAsFixed(2)}
💎 Günlük Net Akış: $sign$symbol${net.toStringAsFixed(2)}

🚀 Paranı Anla, Geleceği Planla! Servetimi Baywise ile yönetiyorum.
#Baywise #FinansalÖzgürlük #ServetYönetimi #NakitAkışı''';

    Share.share(text);
    final contextLocale = Provider.of<LocaleProvider>(context, listen: false);
    AppToast.show(context, contextLocale.t('share_ready'));
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final String symbol;

  const _StatPill({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.dark900.withOpacity(0.6) : Colors.white.withOpacity(0.8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.dark400 : AppColors.light400,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$symbol${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

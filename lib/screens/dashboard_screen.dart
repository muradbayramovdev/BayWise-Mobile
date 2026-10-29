import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/firestore_service.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../models/asset_model.dart';
import '../widgets/unified_add_button.dart';
import '../widgets/daily_summary_card.dart';
import '../providers/workspace_provider.dart';
import 'assets_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final uid = auth.user!.uid;
    final month = formatMonth(DateTime.now());
    final firestore = FirestoreService();

    final isDark = context.watch<ThemeProvider>().isDark;
    final locale = context.watch<LocaleProvider>();
    final workspace = context.watch<WorkspaceProvider>();
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: StreamBuilder<List<TransactionModel>>(
        stream: firestore.streamTransactions(uid, month),
        builder: (context, txSnap) {
          final transactions = txSnap.data ?? [];

          final income = transactions
              .where((t) => t.type == 'income')
              .fold(0.0, (s, t) => s + t.amount);
          final expense = transactions
              .where((t) => t.type != 'income')
              .fold(0.0, (s, t) => s + t.amount);

          final byCategory = <String, double>{};
          for (final t in transactions.where((t) => t.type != 'income')) {
            byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      BalanceCard(
                        totalBalance: income - expense,
                        income: income,
                        expense: expense,
                      ),
                      const SizedBox(height: 14),

                      // Varlık & Servet Hızlı Erişim Kartı
                      StreamBuilder<List<AssetModel>>(
                        stream: firestore.streamAssets(uid),
                        builder: (context, assetSnap) {
                          final assets = assetSnap.data ?? [];
                          final totalPos = assets.where((a) => a.category != 'Borç / Kredi (-)').fold(0.0, (s, a) => s + a.totalTlValue);
                          final totalNeg = assets.where((a) => a.category == 'Borç / Kredi (-)').fold(0.0, (s, a) => s + a.totalTlValue);
                          final totalWorth = (income - expense) + totalPos + totalNeg;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssetsScreen()));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E293B), Color(0xFF0F766E)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x330F766E), blurRadius: 8, offset: Offset(0, 3)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text('🏡🚗🥇', style: TextStyle(fontSize: 22)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(locale.t('total_balance').toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${locale.currencySymbol} ${totalWorth.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Income / Expense summary
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryTile(
                              label: locale.t('income'),
                              amount: income,
                              color: AppColors.accentGreen,
                              cardBg: cardBg,
                              subColor: subColor,
                              symbol: locale.currencySymbol,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryTile(
                              label: locale.t('expense'),
                              amount: expense,
                              color: AppColors.accentRed,
                              cardBg: cardBg,
                              subColor: subColor,
                              symbol: locale.currencySymbol,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cashflow mini bar chart
                      if (income > 0 || expense > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.t('cash_flow'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _MiniBarChart(income: income, expense: expense, subColor: subColor, symbol: locale.currencySymbol),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Günün Özeti & Paylaşım Kartı (Adım 2)
                      DailySummaryCard(
                        transactions: transactions,
                        workspaceName: workspace.workspaceName,
                        workspaceEmoji: workspace.workspaceEmoji,
                      ),
                      const SizedBox(height: 16),

                      // By category
                      if (byCategory.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                locale.t('category_expenses'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...byCategory.entries
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final i = entry.key;
                                final e = entry.value;
                                final color = AppColors.chartColors[
                                    i % AppColors.chartColors.length];
                                final pct = expense > 0 ? e.value / expense : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          locale.translateCategory(e.key),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 80,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: isDark ? AppColors.dark700 : AppColors.light700,
                                            valueColor:
                                                AlwaysStoppedAnimation(color),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${locale.currencySymbol} ${e.value.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: subColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Last 5 transactions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Son İşlemler',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          if (transactions.length > 5)
                            Text(
                              locale.t('view_all'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentTeal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (transactions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Henüz işlem bulunmuyor.\nAşağıdaki + butonuna basarak ekleyin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: subColor),
                            ),
                          ),
                        ),
                      ...transactions.take(5).map(
                            (tx) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: TransactionItem(
                                tx: tx,
                                onDelete: () => firestore.deleteTransaction(uid, tx.id),
                                onEdit: () {
                                  firestore.streamAccounts(uid).first.then((accounts) {
                                    if (!context.mounted) return;
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => AddTransactionBottomSheet(
                                        uid: uid,
                                        accounts: accounts,
                                        existingTx: tx,
                                      ),
                                    );
                                  });
                                },
                              ),
                            ),
                          ),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<AccountModel>>(
        stream: firestore.streamAccounts(uid),
        builder: (context, snap) {
          final accounts = snap.data ?? [];
          return UnifiedAddButton(
            label: locale.t('new_transaction'),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTransactionBottomSheet(
                  uid: uid,
                  accounts: accounts,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final Color cardBg;
  final Color subColor;
  final String symbol;

  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.cardBg,
    required this.subColor,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(height: 4),
          Text(
            '$symbol ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBarChart extends StatelessWidget {
  final double income;
  final double expense;
  final Color subColor;
  final String symbol;

  const _MiniBarChart({required this.income, required this.expense, required this.subColor, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final maxVal = income > expense ? income : expense;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Bar(
          label: locale.t('income_short'),
          value: income,
          maxValue: maxVal,
          color: AppColors.accentTeal,
          subColor: subColor,
          symbol: symbol,
        ),
        const SizedBox(width: 16),
        _Bar(
          label: locale.t('expense_short'),
          value: expense,
          maxValue: maxVal,
          color: AppColors.accentRed,
          subColor: subColor,
          symbol: symbol,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final Color subColor;
  final String symbol;

  const _Bar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.subColor,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? value / maxValue : 0.0;
    const maxHeight = 100.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$symbol ${value.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subColor),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: maxHeight * ratio,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor)),
      ],
    );
  }
}

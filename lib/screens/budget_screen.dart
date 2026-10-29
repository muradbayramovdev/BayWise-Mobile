import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/progress_bar.dart';
import '../widgets/unified_add_button.dart';
import '../widgets/app_toast.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _firestore = FirestoreService();
  final Set<String> _warned80 = {};
  final Set<String> _warned100 = {};

  String get _uid => context.read<AppAuthProvider>().user!.uid;
  String get _month => formatMonth(DateTime.now());

  void _checkWarnings(List<BudgetModel> budgets, Map<String, double> byCategory) {
    for (final b in budgets) {
      if (b.limit == 0) continue;
      final spent = byCategory[b.category] ?? 0;
      final pct = (spent / b.limit) * 100;
      final key80 = '${b.id}_80';
      final key100 = '${b.id}_100';

      if (pct >= 100 && !_warned100.contains(key100)) {
        _warned100.add(key100);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppToast.show(context, '${b.category} bütçesi doldu! (%100)',
                isError: true);
          }
        });
      } else if (pct >= 80 && !_warned80.contains(key80)) {
        _warned80.add(key80);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppToast.show(context, '⚠️ ${b.category} bütçesi %80 doldu');
          }
        });
      }
    }
  }

  void _openModal({BudgetModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetModal(
        uid: _uid,
        month: _month,
        firestore: _firestore,
        existing: existing,
      ),
    );
  }

  void _openCategoryDetail(
    BuildContext context,
    String category,
    List<TransactionModel> transactions,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryDetailScreen(
          uid: _uid,
          category: category,
          transactions: transactions,
          firestore: _firestore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final locale = context.watch<LocaleProvider>();
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: StreamBuilder<List<BudgetModel>>(
        stream: _firestore.streamBudgets(_uid, _month),
        builder: (context, budgetSnap) {
          return StreamBuilder<List<TransactionModel>>(
            stream: _firestore.streamTransactions(_uid, _month),
            builder: (context, txSnap) {
              final budgets = budgetSnap.data ?? [];
              final transactions = txSnap.data ?? [];

              final byCategory = <String, double>{};
              final txByCategory = <String, List<TransactionModel>>{};
              for (final t in transactions.where((t) => t.type != 'income')) {
                byCategory[t.category] =
                    (byCategory[t.category] ?? 0) + t.amount;
                txByCategory.putIfAbsent(t.category, () => []).add(t);
              }

              _checkWarnings(budgets, byCategory);

              final totalLimit =
                  budgets.fold(0.0, (s, b) => s + b.limit);
              final totalSpent =
                  byCategory.values.fold(0.0, (s, v) => s + v);
              final remaining = totalLimit - totalSpent;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Kalan bütçe banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: remaining >= 0
                          ? AppColors.accentTeal
                          : AppColors.accentRed,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kalan Bütçe',
                            style: TextStyle(
                                color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          '${locale.currencySymbol} ${remaining.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(locale.t('monthly_category_budgets'),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (budgets.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('📊', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(locale.t('no_budget_set'),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            const SizedBox(height: 4),
                            Text(
                                locale.t('add_budget_hint'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12, color: subColor)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...budgets.map((b) {
                      final spent = byCategory[b.category] ?? 0;
                      final catTx = txByCategory[b.category] ?? [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () =>
                              _openCategoryDetail(context, b.category, catTx),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          kCategoryEmojis[b.category] ?? '📦',
                                          style:
                                              const TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          locale.translateCategory(b.category),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${locale.currencySymbol} ${spent.toStringAsFixed(2)} / ${b.limit.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: subColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton(
                                          onPressed: () =>
                                              _openModal(existing: b),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: Text('Düzenle',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.accentTeal,
                                                fontWeight: FontWeight.bold,
                                              )),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ProgressBar(
                                    current: spent, max: b.limit),
                                if (catTx.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${catTx.length} işlem yapıldı — detayları görüntüle →',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accentTeal,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: UnifiedAddButton(
        label: locale.t('add_budget'),
        onPressed: _openModal,
      ),
    );
  }
}

// ─── Kategori Detay Ekranı ────────────────────────────────────────────────────

class _CategoryDetailScreen extends StatelessWidget {
  final String uid;
  final String category;
  final List<TransactionModel> transactions;
  final FirestoreService firestore;

  const _CategoryDetailScreen({
    required this.uid,
    required this.category,
    required this.transactions,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = kCategoryEmojis[category] ?? '📦';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('$emoji ${locale.translateCategory(category)} ${locale.t('category_details')}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: scaffoldBg,
        elevation: 0,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: firestore.streamTransactions(
            uid, formatMonth(DateTime.now())),
        builder: (context, snap) {
          final allTx = snap.data ?? transactions;
          final catTx = allTx
              .where((t) => t.category == category && t.type != 'income')
              .toList();
          final total =
              catTx.fold(0.0, (s, t) => s + t.amount);

          if (catTx.isEmpty) {
            Center(
              child: Text(
                locale.t('no_expense_in_category'),
                style: TextStyle(color: subColor),
              ),
            );
          }

          return Column(
            children: [
              // Toplam
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Toplam Harcama',
                          style: TextStyle(color: subColor, fontWeight: FontWeight.w600)),
                      Text(
                        '${locale.currencySymbol} ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: catTx.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final tx = catTx[i];
                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white, size: 24),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: cardBg,
                            title: Text(locale.t('delete_tx'), style: TextStyle(color: textColor)),
                            content: Text(
                              '${tx.description.isEmpty ? locale.t('this_expense') : tx.description} ${locale.t('confirm_delete')}',
                              style: TextStyle(color: subColor),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('İptal'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        AppColors.accentRed),
                                child: const Text('Sil'),
                              ),
                            ],
                          ),
                        ) ?? false;
                      },
                      onDismissed: (_) async {
                        await firestore.deleteTransaction(uid, tx.id);
                        if (context.mounted) {
                          AppToast.show(context, 'İşlem silindi');
                        }
                      },
                      child: _TxTile(tx: tx, cardBg: cardBg, textColor: textColor, subColor: subColor),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final TransactionModel tx;
  final Color cardBg;
  final Color textColor;
  final Color subColor;

  const _TxTile({required this.tx, required this.cardBg, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    DateTime? date;
    try { date = DateTime.parse(tx.date); } catch (_) {}
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = context.watch<LocaleProvider>();

    return Container(
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
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.dark700 : AppColors.light700,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
                child: Text('💳', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description.isEmpty ? 'Açıklama girilmedi' : tx.description,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (date != null)
                  Text(
                    formatDate(date),
                    style: TextStyle(
                        fontSize: 12, color: subColor),
                  ),
              ],
            ),
          ),
          Text(
            '- ${locale.currencySymbol} ${tx.amount.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.accentRed),
          ),
        ],
      ),
    );
  }
}

// ─── Bütçe Modal ─────────────────────────────────────────────────────────────

class _BudgetModal extends StatefulWidget {
  final String uid;
  final String month;
  final FirestoreService firestore;
  final BudgetModel? existing;

  const _BudgetModal({
    required this.uid,
    required this.month,
    required this.firestore,
    this.existing,
  });

  @override
  State<_BudgetModal> createState() => _BudgetModalState();
}

class _BudgetModalState extends State<_BudgetModal> {
  late String _category;
  final _limitCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? kExpenseCategories.first;
    if (widget.existing != null) {
      _limitCtrl.text = widget.existing!.limit.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final limit = double.tryParse(_limitCtrl.text.trim());
    if (limit == null || limit <= 0) return;

    setState(() => _isLoading = true);

    try {
      await widget.firestore.setBudget(
          widget.uid, widget.month, _category, {'limit': limit});
      if (!mounted) return;
      AppToast.show(context, 'Bütçe başarıyla kaydedildi ✓');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, 'Hata: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;
    final locale = context.watch<LocaleProvider>();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.dark600 : AppColors.light600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.existing == null ? 'Yeni Bütçe Ekle' : 'Bütçeyi Düzenle',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: cardBg,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Kategori Seçin',
              labelStyle: TextStyle(color: subColor),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            items: kExpenseCategories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) =>
                setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _limitCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Aylık Limit Tutarı (${locale.currencySymbol})',
              hintStyle: TextStyle(color: subColor),
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Bütçeyi Kaydet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

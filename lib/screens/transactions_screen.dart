import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/transaction_item.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/unified_add_button.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _firestore = FirestoreService();
  final _searchCtrl = TextEditingController();

  String _filter = 'Tümü';
  late String _month;

  // Filtre etiketleri → Firestore değerleri
  final List<_FilterChip> _filters = [
    const _FilterChip('all', null),
    const _FilterChip('income', 'income'),
    const _FilterChip('expense', 'expense'),
    const _FilterChip('Yemek', 'Yemek'),
    const _FilterChip('Ulaşım', 'Ulaşım'),
    const _FilterChip('Kira', 'Kira'),
    const _FilterChip('Alışveriş', 'Alışveriş'),
    const _FilterChip('Sağlık', 'Sağlık'),
    const _FilterChip('Faturalar', 'Faturalar'),
    const _FilterChip('Tasarruf', 'Tasarruf'),
    const _FilterChip('Birikim', 'Birikim'),
    const _FilterChip('Varlık / Servet', 'Varlık / Servet'),
    const _FilterChip('Diğer', 'Diğer'),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _uid => context.read<AppAuthProvider>().user!.uid;

  List<TransactionModel> _applyFilter(List<TransactionModel> items) {
    final search = _searchCtrl.text.toLowerCase();
    final chip = _filters.firstWhere((f) => f.label == _filter,
        orElse: () => const _FilterChip('all', null));

    return items.where((t) {
      final bySearch = search.isEmpty ||
          t.description.toLowerCase().contains(search) ||
          t.category.toLowerCase().contains(search);

      final byFilter = chip.value == null
          ? true
          : chip.value == 'income'
              ? t.type == 'income'
              : chip.value == 'expense'
                  ? t.type != 'income'
                  : t.category == chip.value;

      return bySearch && byFilter;
    }).toList();
  }

  void _openAddModal(List<AccountModel> accounts, {TransactionModel? existingTx}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionBottomSheet(
        uid: _uid,
        accounts: accounts,
        existingTx: existingTx,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final locale = context.watch<LocaleProvider>();
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: StreamBuilder<List<TransactionModel>>(
        stream: _firestore.streamTransactions(_uid, _month),
        builder: (context, txSnap) {
          final allItems = txSnap.data ?? [];
          final filtered = _applyFilter(allItems);

          final totalIncome = allItems
              .where((t) => t.type == 'income')
              .fold(0.0, (s, t) => s + t.amount);
          final totalExpense = allItems
              .where((t) => t.type != 'income')
              .fold(0.0, (s, t) => s + t.amount);

          return Column(
            children: [
              // Arama + Ay seçici
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: locale.t('search_tx'),
                        hintStyle: TextStyle(color: subColor),
                        prefixIcon: Icon(Icons.search, color: subColor),
                        filled: true,
                        fillColor: inputBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _MonthTotals(
                            income: totalIncome,
                            expense: totalExpense,
                            cardBg: cardBg,
                            textColor: textColor,
                            subColor: subColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _pickMonth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
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
                                Icon(Icons.calendar_month,
                                    size: 16, color: subColor),
                                const SizedBox(width: 6),
                                Text(
                                  _month,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
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

              const SizedBox(height: 6),

              // Filtre chip'leri
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final chip = _filters[i];
                    final isActive = chip.label == _filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = chip.label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accentPurple
                              : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: isActive ? null : Border.all(color: subColor.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(
                            locale.t(chip.label),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Liste
              Expanded(
                child: txSnap.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🔍',
                                    style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 8),
                                Text(
                                  allItems.isEmpty
                                      ? locale.t('no_tx_month')
                                      : locale.t('no_tx_filter'),
                                  style: TextStyle(color: subColor),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => TransactionItem(
                              tx: filtered[i],
                              onDelete: () => _firestore.deleteTransaction(
                                  _uid, filtered[i].id),
                              onEdit: () {
                                _firestore.streamAccounts(_uid).first.then((accs) {
                                  if (!mounted) return;
                                  _openAddModal(accs, existingTx: filtered[i]);
                                });
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      // Yüzen ekle butonu
      floatingActionButton: StreamBuilder<List<AccountModel>>(
        stream: _firestore.streamAccounts(_uid),
        builder: (context, accSnap) {
          final accounts = accSnap.data ?? [];
          return UnifiedAddButton(
            label: locale.t('add_transaction'),
            onPressed: () => _openAddModal(accounts),
          );
        },
      ),
    );
  }

  Future<void> _pickMonth() async {
    final parts = _month.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    await showDialog<void>(
      context: context,
      builder: (ctx) => _MonthPickerDialog(
        year: year,
        month: month,
        onConfirm: (y, m) {
          setState(() {
            _month = '$y-${m.toString().padLeft(2, '0')}';
          });
        },
      ),
    );
  }
}

// ─── Yardımcı sınıflar ────────────────────────────────────────────────────────

class _FilterChip {
  final String label;
  final String? value;
  const _FilterChip(this.label, this.value);
}

class _MonthTotals extends StatelessWidget {
  final double income;
  final double expense;
  final Color cardBg;
  final Color textColor;
  final Color subColor;

  const _MonthTotals({required this.income, required this.expense, required this.cardBg, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final symbol = locale.currencySymbol;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
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
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${locale.t('income_short')}: +$symbol${income.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                '${locale.t('expense_short')}: -$symbol${expense.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentRed),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${locale.t('net_short')}: $symbol${(income - expense).toStringAsFixed(0)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onConfirm;

  const _MonthPickerDialog({
    required this.year,
    required this.month,
    required this.onConfirm,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
  }

  @override
  Widget build(BuildContext context) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => _year--),
            icon: Icon(Icons.chevron_left, color: textColor),
          ),
          Text('$_year', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: () => setState(() => _year++),
            icon: Icon(Icons.chevron_right, color: textColor),
          ),
        ],
      ),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(12, (i) {
          final isSelected = i + 1 == _month;
          return GestureDetector(
            onTap: () {
              widget.onConfirm(_year, i + 1);
              Navigator.pop(context);
            },
            child: Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentPurple
                    : inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                months[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : textColor,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

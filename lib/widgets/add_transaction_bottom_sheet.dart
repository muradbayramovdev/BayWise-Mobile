import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'app_toast.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final String uid;
  final List<AccountModel> accounts;

  final TransactionModel? existingTx;

  const AddTransactionBottomSheet({
    super.key,
    required this.uid,
    required this.accounts,
    this.existingTx,
  });

  @override
  State<AddTransactionBottomSheet> createState() =>
      _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState
    extends State<AddTransactionBottomSheet> {
  final _firestore = FirestoreService();
  final _categoryService = CategoryService();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  String _type = 'expense';
  String _category = '';
  String _accountId = '';
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingTx != null) {
      final tx = widget.existingTx!;
      _type = tx.type;
      _category = tx.category;
      _accountId = tx.accountId ?? '';
      _amountCtrl.text = tx.amount.toString();
      _descCtrl.text = tx.description;
      try {
        _date = DateTime.parse(tx.date);
      } catch (_) {}
    } else {
      _accountId = widget.accounts.isNotEmpty ? widget.accounts.first.id : '';
      _category = kDefaultExpenseCategories.first;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String get _categoryType => _type == 'income' ? 'income' : 'expense';

  Future<void> _submit() async {
    final locale = context.read<LocaleProvider>();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      AppToast.show(context, locale.t('valid_amount_error'), isError: true);
      return;
    }
    if (_category.isEmpty) {
      AppToast.show(context, locale.t('select_cat_error'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.existingTx != null) {
        if (_accountId.isNotEmpty && widget.existingTx!.accountId == _accountId) {
          final oldDelta = widget.existingTx!.type == 'income' ? widget.existingTx!.amount : -widget.existingTx!.amount;
          final newDelta = _type == 'income' ? amount : -amount;
          final diff = newDelta - oldDelta;
          if (diff != 0) {
            _firestore.adjustAccountBalance(widget.uid, _accountId, diff);
          }
        }
        _firestore.updateTransaction(widget.uid, widget.existingTx!.id, {
          'type': _type,
          'amount': amount,
          'category': _category,
          'description': _descCtrl.text.trim(),
          'date': formatDateInput(_date),
          'month': formatMonth(_date),
          if (_accountId.isNotEmpty) 'accountId': _accountId,
        });
      } else {
        _firestore.addTransaction(widget.uid, {
          'type': _type,
          'amount': amount,
          'category': _category,
          'description': _descCtrl.text.trim(),
          'date': formatDateInput(_date),
          'month': formatMonth(_date),
          if (_accountId.isNotEmpty) 'accountId': _accountId,
        });

        if (_accountId.isNotEmpty) {
          final delta = _type == 'income' ? amount : -amount;
          _firestore.adjustAccountBalance(widget.uid, _accountId, delta);
        }
      }

      final locale = context.read<LocaleProvider>();
      if (!mounted) return;
      AppToast.show(context, widget.existingTx != null ? locale.t('tx_updated') : locale.t('tx_saved'));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppToast.show(context, 'Hata: $e', isError: true);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _openAddCategoryDialog(List<String> existing) {
    final ctrl = TextEditingController();
    String selectedEmoji = '📦';
    final locale = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? AppColors.dark800 : AppColors.light800),
          title: Text(locale.t('new_category')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  '📦','🎯','✈️','🎸','🐾','🏋️','🍕',
                  '☕','🎨','🚗','💈','🔧','🧹','🌿',
                ].map((e) => GestureDetector(
                  onTap: () => setS(() => selectedEmoji = e),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedEmoji == e
                          ? AppColors.accentTeal.withOpacity(0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: selectedEmoji == e
                          ? Border.all(color: AppColors.accentTeal)
                          : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(hintText: locale.t('category_name_hint')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(locale.t('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = ctrl.text.trim();
                if (name.isEmpty) return;
                await _categoryService.addCategory(
                    widget.uid, _categoryType, '$selectedEmoji $name');
                if (mounted) {
                  setState(() => _category = '$selectedEmoji $name');
                  Navigator.pop(ctx);
                }
              },
              child: Text(locale.t('add')),
            ),
          ],
        ),
      ),
    );
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
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
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
            Text(widget.existingTx != null ? locale.t('edit_transaction') : locale.t('add_new_transaction'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 16),

            // Gelir / Gider toggle
            Row(
              children: ['income', 'expense'].map((t) {
                final sel = _type == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: _isLoading ? null : () => setState(() {
                      _type = t;
                      _category = t == 'income'
                          ? kDefaultIncomeCategories.first
                          : kDefaultExpenseCategories.first;
                    }),
                    child: Container(
                      margin: EdgeInsets.only(right: t == 'income' ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.accentPurple : inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t == 'income' ? locale.t('add_income_btn') : locale.t('add_expense_btn'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: sel ? Colors.white : subColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Miktar
            TextField(
              controller: _amountCtrl,
              enabled: !_isLoading,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              decoration: InputDecoration(
                hintText: '${locale.t('amount')} (${locale.currencySymbol})',
                hintStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // Açıklama
            TextField(
              controller: _descCtrl,
              enabled: !_isLoading,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: locale.t('enter_description_optional'),
                hintStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // Kategoriler — Firestore stream
            StreamBuilder<List<String>>(
              stream: _categoryService.streamCategories(widget.uid, _categoryType),
              builder: (context, snap) {
                final cats = snap.data ??
                    (_type == 'income'
                        ? kDefaultIncomeCategories
                        : kDefaultExpenseCategories);
                if (!cats.contains(_category) && cats.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _category = cats.first);
                  });
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(locale.t('select_category'),
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
                        TextButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () => _openAddCategoryDialog(cats),
                          icon: const Icon(Icons.add, size: 14),
                          label: Text(locale.t('new_category'),
                              style: const TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accentTeal,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cats.map((cat) {
                        final sel = _category == cat;
                        final emoji = kCategoryEmojis[cat] ?? '';
                        return GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => setState(() => _category = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.accentTeal
                                  : inputBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              emoji.isNotEmpty ? '$emoji ${locale.translateCategory(cat)}' : locale.translateCategory(cat),
                              style: TextStyle(
                                fontSize: 12,
                                color: sel ? Colors.black : textColor,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Hesap seçici
            if (widget.accounts.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: _accountId.isEmpty ? null : _accountId,
                dropdownColor: cardBg,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: locale.t('select_account'),
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: widget.accounts
                    .map((a) =>
                        DropdownMenuItem(value: a.id, child: Text(a.name)))
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (v) => setState(() => _accountId = v ?? ''),
              ),
              const SizedBox(height: 10),
            ],

            // Tarih
            GestureDetector(
              onTap: _isLoading ? null : _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatDate(_date),
                        style: TextStyle(color: textColor)),
                    Icon(Icons.calendar_today,
                        size: 16, color: subColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Kaydet butonu
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(locale.t('saving'),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Text(widget.existingTx != null ? locale.t('save_changes') : locale.t('save_transaction'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(locale.t('cancel'), style: TextStyle(color: subColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

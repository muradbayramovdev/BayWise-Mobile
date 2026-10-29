import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../models/recurring_payment_model.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_toast.dart';
import '../widgets/transaction_item.dart';
import '../widgets/add_transaction_bottom_sheet.dart';
import '../widgets/unified_add_button.dart';

class RecurringPaymentsScreen extends StatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  State<RecurringPaymentsScreen> createState() =>
      _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen> {
  final _firestore = FirestoreService();
  String _filter = 'Tümü';

  String get _uid => context.read<AppAuthProvider>().user!.uid;

  void _openAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecurringPaymentModal(
        uid: _uid,
        firestore: _firestore,
      ),
    );
  }

  void _openEditModal(RecurringPaymentModel p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecurringPaymentEditModal(
        uid: _uid,
        firestore: _firestore,
        payment: p,
      ),
    );
  }

  void _openTransactionEditModal(TransactionModel tx) async {
    final accounts = await _firestore.streamAccounts(_uid).first;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionBottomSheet(
        uid: _uid,
        accounts: accounts,
        existingTx: tx,
      ),
    );
  }

  Future<void> _toggleActive(RecurringPaymentModel p) async {
    await _firestore.updateRecurringPayment(
        _uid, p.id, {'isActive': !p.isActive});
  }

  Future<void> _processPaymentNow(RecurringPaymentModel p) async {
    final isIncome = p.type == 'income';
    final locale = context.read<LocaleProvider>();
    final sym = locale.currencySymbol;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.dark800 : AppColors.light800,
        title: Text(locale.t(isIncome ? 'income_collect_confirm' : 'expense_pay_confirm'), style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.light100, fontWeight: FontWeight.bold)),
        content: Text(
          locale.t('process_confirm_body')
              .replaceAll('{name}', p.name)
              .replaceAll('{amount}', p.amount.toStringAsFixed(2))
              .replaceAll('{sym}', sym)
              .replaceAll('{date}', formatDate(DateTime.now())),
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.dark300 : AppColors.light400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome ? AppColors.accentGreen : AppColors.accentPurple,
              foregroundColor: Colors.white,
            ),
            icon: Icon(isIncome ? Icons.add_circle_outline : Icons.check_circle_outline, size: 18),
            label: Text(locale.t(isIncome ? 'collect_income' : 'pay_from_safe')),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // 1. İşlemi Transaction olarak kaydet
    await _firestore.addTransaction(_uid, {
      'title': '${p.name} (Düzenli ${isIncome ? "Gelir" : "Ödeme"})',
      'amount': p.amount,
      'type': p.type,
      'category': p.category,
      'date': formatDateInput(DateTime.now()),
      'note': 'Tekrarlayan işlemden otomatik eklendi',
    });

    // 2. Sıradaki periyodu hesapla ve güncelle
    DateTime currentNext;
    try {
      currentNext = DateTime.parse(p.nextDate);
    } catch (_) {
      currentNext = DateTime.now();
    }

    DateTime newNext;
    if (p.frequency == 'monthly') {
      int year = currentNext.year;
      int month = currentNext.month + 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      final lastDay = DateTime(year, month + 1, 0).day;
      final targetDay = currentNext.day > lastDay ? lastDay : currentNext.day;
      newNext = DateTime(year, month, targetDay);
    } else if (p.frequency == 'weekly') {
      newNext = currentNext.add(const Duration(days: 7));
    } else if (p.frequency == 'daily') {
      newNext = currentNext.add(const Duration(days: 1));
    } else {
      newNext = DateTime(currentNext.year + 1, currentNext.month, currentNext.day);
    }

    await _firestore.updateRecurringPayment(_uid, p.id, {
      'nextDate': formatDateInput(newNext),
    });

    if (mounted) {
      AppToast.show(context, locale.t('processed_to_safe_toast').replaceAll('{name}', p.name).replaceAll('{date}', formatDate(newNext)));
    }
  }

  Color _urgencyColor(int days) {
    if (days <= 3) return AppColors.accentRed;
    if (days <= 7) return AppColors.accentAmber;
    return AppColors.accentGreen;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final sym = locale.currencySymbol;
    final isDark = context.watch<ThemeProvider>().isDark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final iconBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('${locale.t('recurring')} & ${locale.t('recurring_payments')}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: scaffoldBg,
        elevation: 0,
      ),
      body: StreamBuilder<List<RecurringPaymentModel>>(
        stream: _firestore.streamRecurringPayments(_uid),
        builder: (context, snap) {
          final payments = snap.data ?? [];

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalIncome = payments.where((p) => p.type == 'income' && p.isActive).fold(0.0, (sum, item) => sum + item.amount);
          final totalExpense = payments.where((p) => p.type != 'income' && p.isActive).fold(0.0, (sum, item) => sum + item.amount);

          final filteredPayments = payments.where((p) {
            if (_filter == locale.t('recurring_income')) return p.type == 'income';
            if (_filter == locale.t('recurring_expense')) return p.type != 'income';
            return true;
          }).toList();

          return Column(
            children: [
              // Özet Banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: !isDark ? Border.all(color: AppColors.light600) : null,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(locale.t('monthly_recurring_income'), style: TextStyle(fontSize: 11, color: subColor)),
                          const SizedBox(height: 4),
                          Text('+ $sym ${totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentGreen)),
                        ],
                      ),
                    ),
                    Container(height: 28, width: 1, color: subColor.withOpacity(0.2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(locale.t('monthly_recurring_expense'), style: TextStyle(fontSize: 11, color: subColor)),
                          const SizedBox(height: 4),
                          Text('- $sym ${totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filtre Chip'leri
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [locale.t('all'), locale.t('recurring_income'), locale.t('recurring_expense')].map((f) {
                    final isActive = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accentPurple : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: isActive ? null : Border.all(color: subColor.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? Colors.white : textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: StreamBuilder<List<TransactionModel>>(
                  stream: _firestore.streamTransactions(_uid, ''),
                  builder: (context, txSnap) {
                    final allTx = txSnap.data ?? [];
                    final recurringTx = allTx.where((t) {
                      final isRecurring = t.note.contains('Tekrarlayan') ||
                          t.note.contains('otomatik eklendi') ||
                          t.title.contains('Düzenli') ||
                          t.title.contains('(Düzenli') ||
                          payments.any((p) => t.title.contains(p.name));
                      if (!isRecurring) return false;
                      if (_filter == locale.t('recurring_income')) return t.type == 'income';
                      if (_filter == locale.t('recurring_expense')) return t.type != 'income';
                      return true;
                    }).toList();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Şablonlar Başlığı
                          Row(
                            children: [
                              Icon(Icons.repeat, color: AppColors.accentPurple, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Düzenli Şablonlar & Aktif Tanımlar (${filteredPayments.length})',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (filteredPayments.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: subColor.withOpacity(0.15)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔄', style: TextStyle(fontSize: 44)),
                                  const SizedBox(height: 12),
                                  Text(
                                    payments.isEmpty ? locale.t('no_recurring_msg') : locale.t('no_tx_filter'),
                                    style: TextStyle(color: subColor, fontSize: 14),
                                  ),
                                  if (payments.isEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      locale.t('recurring_empty_sub'),
                                      style: TextStyle(color: subColor.withOpacity(0.8), fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    GestureDetector(
                                      onTap: _openAddModal,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentPurple,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.add, color: Colors.white, size: 18),
                                            const SizedBox(width: 6),
                                            Text(locale.t('add_new_transaction'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredPayments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final p = filteredPayments[i];
                                final days = p.daysUntilNext();
                                final urgency = _urgencyColor(days);
                                final isIncome = p.type == 'income';
                                final emoji = kCategoryEmojis[p.category] ?? (isIncome ? '💰' : '💳');
                                final amountColor = isIncome ? AppColors.accentGreen : AppColors.accentRed;
                                final sign = isIncome ? '+' : '-';

                                DateTime? targetDate;
                                try {
                                  targetDate = DateTime.parse(p.nextDate);
                                } catch (_) {}

                                String recurrenceDetail = p.frequencyLabel;
                                if (targetDate != null) {
                                  if (p.frequency == 'monthly') {
                                    recurrenceDetail = locale.t('every_month_day').replaceAll('{day}', '${targetDate.day}').replaceAll('{date}', formatDate(targetDate));
                                  } else if (p.frequency == 'weekly') {
                                    recurrenceDetail = '${locale.t('weekly')} (${formatDate(targetDate)})';
                                  } else if (p.frequency == 'daily') {
                                    recurrenceDetail = locale.t('daily');
                                  } else if (p.frequency == 'yearly') {
                                    recurrenceDetail = '${locale.t('yearly')} (${formatDate(targetDate)})';
                                  }
                                }

                                return Dismissible(
                                  key: ValueKey(p.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentRed,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
                                  ),
                                  confirmDismiss: (_) async {
                                    return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: cardBg,
                                        title: Text(locale.t('delete_recurring'), style: TextStyle(color: textColor)),
                                        content: Text('${locale.t('delete_confirm')} "${p.name}"?', style: TextStyle(color: subColor)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text(locale.t('cancel')),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
                                            child: Text(locale.t('delete')),
                                          ),
                                        ],
                                      ),
                                    ) ?? false;
                                  },
                                  onDismissed: (_) async {
                                    await _firestore.deleteRecurringPayment(_uid, p.id);
                                    if (mounted) {
                                      AppToast.show(context, locale.t('deleted_toast'));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border(
                                        left: BorderSide(
                                          color: p.isActive ? (isIncome ? AppColors.accentGreen : urgency) : (isDark ? AppColors.dark600 : AppColors.light600),
                                          width: 4,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            // Emoji
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: iconBg,
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                              child: Center(
                                                child: Text(emoji, style: const TextStyle(fontSize: 22)),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            // Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          p.name,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: p.isActive ? textColor : subColor,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: isIncome ? AppColors.accentGreen.withOpacity(0.15) : AppColors.accentRed.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          isIncome ? locale.t('income_short').toUpperCase() : locale.t('expense_short').toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: amountColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    recurrenceDetail,
                                                    style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (p.isActive)
                                                    Text(
                                                      days == 0
                                                          ? locale.t('due_today')
                                                          : locale.t('days_left_fmt').replaceAll('{days}', '$days').replaceAll('{date}', formatDate(targetDate ?? DateTime.now())),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: days == 0 ? AppColors.accentRed : (isIncome ? AppColors.accentGreen : urgency),
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            // Tutar
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '$sign $sym ${p.amount.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: p.isActive ? amountColor : subColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // Düzenle & Aktif toggle
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () => _openEditModal(p),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.accentPurple.withOpacity(0.15),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: AppColors.accentPurple),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            const Icon(Icons.edit, size: 12, color: AppColors.accentPurple),
                                                            const SizedBox(width: 3),
                                                            Text(locale.t('edit'), style: const TextStyle(fontSize: 11, color: AppColors.accentPurple, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    GestureDetector(
                                                      onTap: () => _toggleActive(p),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: p.isActive
                                                              ? AppColors.accentGreen.withOpacity(0.15)
                                                              : (isDark ? AppColors.dark700 : AppColors.light700),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: p.isActive ? AppColors.accentGreen : (isDark ? AppColors.dark600 : AppColors.light600),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          p.isActive ? locale.t('active_yes') : locale.t('passive'),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: p.isActive ? AppColors.accentGreen : subColor,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        if (p.isActive) ...[
                                          const SizedBox(height: 12),
                                          Divider(height: 1, thickness: 0.8, color: subColor.withOpacity(0.15)),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  isIncome ? locale.t('process_income_btn') : locale.t('process_expense_btn'),
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subColor),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _processPaymentNow(p),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: isIncome ? AppColors.accentGreen : AppColors.accentPurple,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(isIncome ? Icons.add_circle : Icons.check_circle, size: 14, color: Colors.white),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        isIncome ? locale.t('collect_income') : locale.t('pay_from_safe'),
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 24),
                          Divider(height: 1, thickness: 1, color: subColor.withOpacity(0.15)),
                          const SizedBox(height: 18),

                          // 2. Kaydedilen İşlem Geçmişi Başlığı
                          Row(
                            children: [
                              Icon(Icons.history, color: AppColors.accentAmber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${locale.t('recurring_history')} (${recurringTx.length})',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            locale.t('recurring_history_sub'),
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                          const SizedBox(height: 12),

                          if (recurringTx.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: subColor.withOpacity(0.15)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('📋', style: TextStyle(fontSize: 36)),
                                    const SizedBox(height: 8),
                                    Text(
                                      locale.t('no_recurring_tx_found'),
                                      style: TextStyle(color: subColor, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recurringTx.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) => TransactionItem(
                                tx: recurringTx[i],
                                onDelete: () => _firestore.deleteTransaction(_uid, recurringTx[i].id),
                                onEdit: () => _openTransactionEditModal(recurringTx[i]),
                              ),
                            ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: UnifiedAddButton(
        label: locale.t('add_recurring'),
        onPressed: _openAddModal,
      ),
    );
  }
}

// ─── Edit Modal ───────────────────────────────────────────────────────────────

class _RecurringPaymentEditModal extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;
  final RecurringPaymentModel payment;

  const _RecurringPaymentEditModal({
    required this.uid,
    required this.firestore,
    required this.payment,
  });

  @override
  State<_RecurringPaymentEditModal> createState() =>
      _RecurringPaymentEditModalState();
}

class _RecurringPaymentEditModalState extends State<_RecurringPaymentEditModal> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amountCtrl;
  late String _type;
  late String _category;
  late String _frequency;
  late DateTime _nextDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.payment.name);
    _amountCtrl = TextEditingController(text: widget.payment.amount.toString());
    _type = widget.payment.type;
    _category = widget.payment.category;
    _frequency = widget.payment.frequency;
    try {
      _nextDate = DateTime.parse(widget.payment.nextDate);
    } catch (_) {
      _nextDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }

  Future<void> _submit(bool updatePastEntries) async {
    final locale = context.read<LocaleProvider>();
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty) {
      AppToast.show(context, locale.t('error_empty_title'), isError: true);
      return;
    }
    if (amount == null || amount <= 0) {
      AppToast.show(context, locale.t('error_valid_amount'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.firestore.updateRecurringPayment(widget.uid, widget.payment.id, {
        'name': name,
        'amount': amount,
        'type': _type,
        'category': _category,
        'frequency': _frequency,
        'nextDate': formatDateInput(_nextDate),
      }).timeout(const Duration(milliseconds: 1500), onTimeout: () => null);

      if (updatePastEntries) {
        await widget.firestore.updateTransactionsByTitle(
          widget.uid,
          widget.payment.name,
          newTitle: name,
          newAmount: amount,
        ).timeout(const Duration(milliseconds: 2000), onTimeout: () => null);
      }

      if (!mounted) return;
      AppToast.show(context, updatePastEntries ? locale.t('updated_past_future') : locale.t('updated_future_only'));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, locale.t('updated_local'));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;
    final isIncome = _type == 'income';
    final cats = isIncome ? kIncomeCategories : kExpenseCategories;
    if (!cats.contains(_category)) _category = cats.first;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: subColor.withOpacity(0.15)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: subColor.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(locale.t('update_recurring'), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(locale.t('update_recurring_sub'), style: TextStyle(color: subColor, fontSize: 12)),
            const SizedBox(height: 16),

            // Tip (Gelir / Gider)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _type = 'expense'; _category = kExpenseCategories.first; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_type.contains('income') ? AppColors.accentRed : inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(locale.t('expense_minus'), style: TextStyle(color: !_type.contains('income') ? Colors.white : textColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _type = 'income'; _category = kIncomeCategories.first; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == 'income' ? AppColors.accentGreen : inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(locale.t('income_plus'), style: TextStyle(color: _type == 'income' ? Colors.white : textColor, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Ad
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: locale.t('transaction_title'),
                labelStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // Tutar
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: '${locale.t('new_amount')} (${locale.currencySymbol})',
                labelStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // Kategori
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: cardBg,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: locale.t('category'),
                labelStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(locale.translateCategory(c)))).toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 10),

            // Sıklık
            DropdownButtonFormField<String>(
              value: _frequency,
              dropdownColor: cardBg,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: locale.t('recurrence_frequency'),
                labelStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: [
                DropdownMenuItem(value: 'daily', child: Text(locale.t('daily'))),
                DropdownMenuItem(value: 'weekly', child: Text(locale.t('weekly'))),
                DropdownMenuItem(value: 'monthly', child: Text(locale.t('monthly'))),
                DropdownMenuItem(value: 'yearly', child: Text(locale.t('yearly'))),
              ],
              onChanged: (v) => setState(() => _frequency = v ?? _frequency),
            ),
            const SizedBox(height: 14),

            // Ayın Günü Seçimi (Eğer Aylık ise)
            if (_frequency == 'monthly') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(locale.t('monthly_day_info'), style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w600)),
                  Text('${_nextDate.day}. ${locale.t('day')}', style: const TextStyle(fontSize: 13, color: AppColors.accentPurple, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 31,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final day = idx + 1;
                    final isSelected = _nextDate.day == day;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          final now = DateTime.now();
                          int year = now.year;
                          int month = now.month;
                          if (day < now.day) {
                            month += 1;
                            if (month > 12) {
                              month = 1;
                              year += 1;
                            }
                          }
                          final lastDay = DateTime(year, month + 1, 0).day;
                          final safeDay = day > lastDay ? lastDay : day;
                          _nextDate = DateTime(year, month, safeDay);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentPurple : inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? null : Border.all(color: subColor.withOpacity(0.25)),
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Sıradaki tarih özeti ve takvimden manuel seçme
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: subColor.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(locale.t('next_occurrence'), style: TextStyle(fontSize: 11, color: subColor)),
                        const SizedBox(height: 4),
                        Text(
                          '${formatDate(_nextDate)}',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month, size: 20, color: AppColors.accentPurple),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Seçenek 1: Sadece Gelecek Aylar/Dönemler İçin Kaydet
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _submit(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.update, size: 18),
                label: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(locale.t('save_future_only'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 10),

            // Seçenek 2: Eski İşlemler Dahil Tümünü Değiştir
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _submit(true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentAmber,
                  side: const BorderSide(color: AppColors.accentAmber, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.history_toggle_off, size: 18),
                label: Text(locale.t('save_all_including_past'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ─── Modal ────────────────────────────────────────────────────────────────────

class _RecurringPaymentModal extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;

  const _RecurringPaymentModal({
    required this.uid,
    required this.firestore,
  });

  @override
  State<_RecurringPaymentModal> createState() =>
      _RecurringPaymentModalState();
}

class _RecurringPaymentModalState extends State<_RecurringPaymentModal> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _type = 'expense';
  String _category = kExpenseCategories.first;
  String _frequency = 'monthly';
  DateTime _nextDate = DateTime.now();
  bool _isLoading = false;
  bool _addToTransactionsNow = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }

  Future<void> _submit() async {
    final locale = context.read<LocaleProvider>();
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (name.isEmpty) {
      AppToast.show(context, locale.t('error_empty_title'), isError: true);
      return;
    }
    if (amount == null || amount <= 0) {
      AppToast.show(context, locale.t('error_valid_amount'), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.firestore.addRecurringPayment(widget.uid, {
        'name': name,
        'amount': amount,
        'type': _type,
        'category': _category,
        'frequency': _frequency,
        'nextDate': formatDateInput(_nextDate),
        'isActive': true,
      }).timeout(const Duration(milliseconds: 1500), onTimeout: () => null);

      if (_addToTransactionsNow) {
        await widget.firestore.addTransaction(widget.uid, {
          'title': '$name (${locale.t('regular')} ${_type == 'income' ? locale.t('income_short') : locale.t('expense_short')})',
          'amount': amount,
          'type': _type,
          'category': _category,
          'date': formatDateInput(DateTime.now()),
          'note': locale.t('processed_note'),
        }).timeout(const Duration(milliseconds: 1500), onTimeout: () => null);
      }

      if (!mounted) return;
      AppToast.show(context, locale.t('saved_successfully'));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context, locale.t('saved_local'));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    final cats = _type == 'income' ? kIncomeCategories : kExpenseCategories;
    if (!cats.contains(_category)) {
      _category = cats.first;
    }

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
            Text(locale.t('add_recurring_tx'),
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
                      _category = t == 'income' ? kIncomeCategories.first : kExpenseCategories.first;
                    }),
                    child: Container(
                      margin: EdgeInsets.only(right: t == 'income' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? (t == 'income' ? AppColors.accentGreen : AppColors.accentRed) : inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t == 'income' ? locale.t('recurring_income') : locale.t('recurring_expense'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: sel ? Colors.white : subColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Ad
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: locale.t('recurring_name_hint'),
                hintStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // Tutar
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '${locale.t('amount')} (${locale.currencySymbol})',
                hintStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // Kategori
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: cardBg,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: locale.t('select_category'),
                labelStyle: TextStyle(color: subColor),
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              items: cats
                  .map((c) => DropdownMenuItem(value: c, child: Text(locale.translateCategory(c))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 14),

            // Tekrarlama
            Text(locale.t('recurrence_frequency'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subColor)),
            const SizedBox(height: 8),
            Row(
              children: [
                _FreqChip(
                  label: locale.t('daily'),
                  value: 'daily',
                  selected: _frequency == 'daily',
                  onTap: () => setState(() => _frequency = 'daily'),
                ),
                const SizedBox(width: 6),
                _FreqChip(
                  label: locale.t('weekly'),
                  value: 'weekly',
                  selected: _frequency == 'weekly',
                  onTap: () => setState(() => _frequency = 'weekly'),
                ),
                const SizedBox(width: 6),
                _FreqChip(
                  label: locale.t('monthly'),
                  value: 'monthly',
                  selected: _frequency == 'monthly',
                  onTap: () => setState(() => _frequency = 'monthly'),
                ),
                const SizedBox(width: 6),
                _FreqChip(
                  label: locale.t('yearly'),
                  value: 'yearly',
                  selected: _frequency == 'yearly',
                  onTap: () => setState(() => _frequency = 'yearly'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Eğer Aylık (monthly) seçiliyse, 1..31 arası Gün Seçici Göster
            if (_frequency == 'monthly') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ayın Hangi Günü Tekrarlansın?',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accentPurple.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Her ayın ${_nextDate.day}. günü',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentPurple),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 31,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final day = idx + 1;
                    final isSelected = _nextDate.day == day;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          final now = DateTime.now();
                          int year = now.year;
                          int month = now.month;
                          // Eğer seçilen gün bu ay geçtiyse bir sonraki ayın o gününe kur
                          if (day < now.day) {
                            month += 1;
                            if (month > 12) {
                              month = 1;
                              year += 1;
                            }
                          }
                          // Ayın son gününü aşarsa (örn Şubatta 31) o ayın son gününe sabitle
                          final lastDay = DateTime(year, month + 1, 0).day;
                          final safeDay = day > lastDay ? lastDay : day;
                          _nextDate = DateTime(year, month, safeDay);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accentPurple : inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? null : Border.all(color: subColor.withOpacity(0.25)),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.accentPurple.withOpacity(0.35), blurRadius: 6, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Sıradaki tarih özeti ve takvimden manuel seçme
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: subColor.withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(locale.t('first_occurrence_date'),
                            style: TextStyle(fontSize: 11, color: subColor)),
                        const SizedBox(height: 4),
                        Text(
                          '${formatDate(_nextDate)} (${_frequency == 'monthly' ? locale.t('every_month_day').replaceAll('{day}', '${_nextDate.day}').replaceAll('{date}', formatDate(_nextDate)) : locale.t(_frequency)})',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month, size: 20, color: AppColors.accentPurple),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Kasaya / İşlemlere de ekle check widget'ı
            GestureDetector(
              onTap: () => setState(() => _addToTransactionsNow = !_addToTransactionsNow),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _addToTransactionsNow ? AppColors.accentPurple.withOpacity(0.12) : inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _addToTransactionsNow ? AppColors.accentPurple : subColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _addToTransactionsNow ? Icons.check_box : Icons.check_box_outline_blank,
                      color: _addToTransactionsNow ? AppColors.accentPurple : subColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'İlk işlemi şimdi kasanıza (İşlemlere) da ekle',
                        style: TextStyle(
                          color: _addToTransactionsNow ? textColor : subColor,
                          fontWeight: _addToTransactionsNow ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Düzenli İşlemi Kaydet',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreqChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _FreqChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentPurple : inputBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : subColor,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../models/goal_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/progress_bar.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _firestore = FirestoreService();

  String get _uid => context.read<AppAuthProvider>().user!.uid;

  int _daysLeft(String targetDate) {
    if (targetDate.isEmpty) return 0;
    try {
      final target = DateTime.parse(targetDate);
      final diff = target.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }

  void _openNewGoalModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewGoalModal(uid: _uid, firestore: _firestore),
    );
  }

  void _openSavingsModal(GoalModel goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SavingsModal(
        uid: _uid,
        goal: goal,
        firestore: _firestore,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = context.watch<ThemeProvider>().isDark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: StreamBuilder<List<GoalModel>>(
        stream: _firestore.streamGoals(_uid),
        builder: (context, snap) {
          final goals = snap.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...goals.map((g) {
                final daysLeft = _daysLeft(g.targetDate);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${g.emoji} ${g.title}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              daysLeft <= 0 ? locale.t('time_is_up') : '$daysLeft ${locale.t('days_left')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: daysLeft <= 7 ? AppColors.accentAmber : subColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${context.watch<LocaleProvider>().currencySymbol} ${g.saved.toStringAsFixed(2)} / ${context.watch<LocaleProvider>().currencySymbol} ${g.target.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        ProgressBar(
                          current: g.saved,
                          max: g.target,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () => _openSavingsModal(g),
                            icon: const Icon(Icons.add, size: 16),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentTeal,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(0, 38),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            label: Text(locale.t('add_savings'), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              if (goals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.flag_outlined, size: 48, color: AppColors.accentTeal),
                      const SizedBox(height: 12),
                      Text(locale.t('empty_goals'),
                          style: TextStyle(color: subColor, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(locale.t('empty_goals_sub'),
                          style: TextStyle(color: subColor.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openNewGoalModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add),
                label: Text(locale.t('add_new_goal'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── New Goal Modal ───────────────────────────────────────────────────────────

class _NewGoalModal extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;

  const _NewGoalModal({required this.uid, required this.firestore});

  @override
  State<_NewGoalModal> createState() => _NewGoalModalState();
}

class _NewGoalModalState extends State<_NewGoalModal> {
  final _emojiCtrl = TextEditingController(text: '🎯');
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  bool _isLoading = false;

  @override
  void dispose() {
    _emojiCtrl.dispose();
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _submit() async {
    final target = double.tryParse(_targetCtrl.text);
    if (_titleCtrl.text.isEmpty || target == null || target <= 0) return;

    setState(() => _isLoading = true);
    try {
      await widget.firestore.addGoal(widget.uid, {
        'emoji': _emojiCtrl.text.trim(),
        'title': _titleCtrl.text.trim(),
        'target': target,
        'saved': 0,
        'targetDate': formatDateInput(_targetDate),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return _ModalWrapper(
      title: locale.t('new_goal_title'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emojiCtrl,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Emoji (Örn: 🎯, 🚗, ✈️, 🏡)',
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Hedef adı (Örn: Yeni Araba Peşinatı)',
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _targetCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Hedef Tutar (${context.watch<LocaleProvider>().currencySymbol})',
              filled: true,
              fillColor: inputBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hedefe ulaşılacak tarih', style: TextStyle(fontSize: 11, color: subColor)),
                      Text(
                        formatDate(_targetDate),
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Icon(Icons.calendar_month, size: 18, color: subColor),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(locale.t('create_goal'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Savings Modal ────────────────────────────────────────────────────────────

class _SavingsModal extends StatefulWidget {
  final String uid;
  final GoalModel goal;
  final FirestoreService firestore;

  const _SavingsModal({
    required this.uid,
    required this.goal,
    required this.firestore,
  });

  @override
  State<_SavingsModal> createState() => _SavingsModalState();
}

class _SavingsModalState extends State<_SavingsModal> {
  final _amountCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);
    try {
      final newSaved = widget.goal.saved + amount;
      await widget.firestore.updateGoal(widget.uid, widget.goal.id, {
        'saved': newSaved,
      });
      // Also record as a transaction
      await widget.firestore.addTransaction(widget.uid, {
        'type': 'expense',
        'amount': amount,
        'category': 'Birikim',
        'description': 'Hedef katkısı: ${widget.goal.title}',
        'date': formatDateInput(DateTime.now()),
        'month': formatMonth(DateTime.now()),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.dark700 : AppColors.light700;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;
    final subColor = isDark ? AppColors.dark400 : AppColors.light400;

    return _ModalWrapper(
      title: '${locale.t('add_savings')}: ${widget.goal.emoji} ${widget.goal.title}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Yatırılacak Tutar (${context.watch<LocaleProvider>().currencySymbol})',
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
                backgroundColor: AppColors.accentTeal,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black54),
                    )
                  : Text(locale.t('save_savings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Modal Wrapper ─────────────────────────────────────────────────────

class _ModalWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _ModalWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.dark800 : AppColors.light800;
    final textColor = isDark ? AppColors.dark100 : AppColors.light100;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.dark600 : AppColors.light600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

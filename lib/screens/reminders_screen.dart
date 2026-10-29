import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/reminder_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _firestore = FirestoreService();

  String get _uid => context.read<AppAuthProvider>().user!.uid;

  Color _urgencyColor(String dueDate) {
    try {
      final target = DateTime.parse(dueDate);
      final days = target.difference(DateTime.now()).inDays;
      if (days < 7) return AppColors.accentRed;
      if (days < 14) return AppColors.accentAmber;
      return AppColors.accentGreen;
    } catch (_) {
      return AppColors.dark600;
    }
  }

  void _openAddModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddReminderModal(uid: _uid, firestore: _firestore),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark900,
      body: StreamBuilder<List<ReminderModel>>(
        stream: _firestore.streamReminders(_uid),
        builder: (context, snap) {
          final reminders = snap.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ElevatedButton.icon(
                onPressed: _openAddModal,
                icon: const Icon(Icons.add_alarm),
                label: const Text('Hatırlatıcı ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              if (reminders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Henüz hatırlatıcı yok.',
                      style: TextStyle(color: AppColors.dark400),
                    ),
                  ),
                ),

              ...reminders.map((r) {
                final borderColor = _urgencyColor(r.dueDate);
                String formattedDate = r.dueDate;
                try {
                  formattedDate = formatDate(DateTime.parse(r.dueDate));
                } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.dark800,
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(color: borderColor, width: 4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.dark100,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.dark400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: borderColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _AddReminderModal extends StatefulWidget {
  final String uid;
  final FirestoreService firestore;

  const _AddReminderModal({required this.uid, required this.firestore});

  @override
  State<_AddReminderModal> createState() => _AddReminderModalState();
}

class _AddReminderModalState extends State<_AddReminderModal> {
  final _titleCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await widget.firestore.addReminder(widget.uid, {
        'title': _titleCtrl.text.trim(),
        'dueDate': formatDateInput(_dueDate),
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.dark800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: AppColors.dark600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Hatırlatıcı Ekle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(hintText: 'Başlık'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.dark700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDate(_dueDate),
                    style: const TextStyle(color: AppColors.dark100),
                  ),
                  const Icon(Icons.calendar_today, size: 16, color: AppColors.dark400),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentTeal,
              foregroundColor: Colors.black,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

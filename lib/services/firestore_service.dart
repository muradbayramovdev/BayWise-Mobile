import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/account_model.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/reminder_model.dart';
import '../models/recurring_payment_model.dart';
import '../models/asset_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String currentPrefix = '';
  String prefix = currentPrefix;

  void setPrefix(String p) {
    prefix = p;
    currentPrefix = p;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _col(
    String uid,
    String name,
  ) =>
      _db.collection('users').doc(uid).collection('$prefix$name');

  // Stream Controllers for Local + Cloud Dual Sync
  static final Map<String, StreamController<List<RecurringPaymentModel>>> _recurringControllers = {};
  static final Map<String, StreamController<List<TransactionModel>>> _transactionControllers = {};
  static final Map<String, StreamController<List<AccountModel>>> _accountControllers = {};

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ─── Transactions (Dual Sync: Local + Cloud) ───────────────────────────────

  Future<void> addTransaction(
    String uid,
    Map<String, dynamic> payload,
  ) async {
    final now = DateTime.now();
    final dateStr = payload['date'] as String? ?? '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    String monthStr = payload['month'] as String? ?? '';
    if (monthStr.isEmpty && dateStr.length >= 7) {
      monthStr = dateStr.substring(0, 7);
    }
    if (monthStr.isEmpty) {
      monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    }
    final titleStr = payload['title'] as String? ?? payload['category'] as String? ?? 'Düzenli İşlem';
    final descStr = payload['description'] as String? ?? titleStr;

    final completePayload = {
      ...payload,
      'date': dateStr,
      'month': monthStr,
      'title': titleStr,
      'description': descStr,
      'createdAt': now.toIso8601String(),
    };

    final localId = 'loc_${DateTime.now().millisecondsSinceEpoch}';
    await _saveLocalTransaction(uid, TransactionModel.fromMap(localId, completePayload));

    try {
      await _col(uid, 'transactions').add(completePayload).timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
  }

  Future<void> _saveLocalTransaction(String uid, TransactionModel item) async {
    try {
      final prefs = await _prefs;
      final key = 'local_transactions_$uid';
      final listStr = prefs.getString(key);
      List<dynamic> list = listStr != null ? jsonDecode(listStr) : [];
      list.removeWhere((e) => e['id'] == item.id);
      list.insert(0, {'id': item.id, ...item.toMap()});
      await prefs.setString(key, jsonEncode(list));
      _notifyTransactionControllers(uid);
    } catch (_) {}
  }

  Future<void> deleteTransaction(String uid, String transactionId) async {
    try {
      final prefs = await _prefs;
      final key = 'local_transactions_$uid';
      final listStr = prefs.getString(key);
      if (listStr != null) {
        List<dynamic> list = jsonDecode(listStr);
        list.removeWhere((e) => e['id'] == transactionId);
        await prefs.setString(key, jsonEncode(list));
        _notifyTransactionControllers(uid);
      }
    } catch (_) {}

    try {
      await _col(uid, 'transactions').doc(transactionId).delete().timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
  }

  Future<void> updateTransaction(
    String uid,
    String transactionId,
    Map<String, dynamic> payload,
  ) async {
    final Map<String, dynamic> updates = {...payload};
    if (updates.containsKey('date') && !updates.containsKey('month')) {
      try {
        final dateStr = updates['date'] as String;
        if (dateStr.length >= 7) {
          updates['month'] = dateStr.substring(0, 7);
        }
      } catch (_) {}
    }

    try {
      final prefs = await _prefs;
      final key = 'local_transactions_$uid';
      final listStr = prefs.getString(key);
      if (listStr != null) {
        List<dynamic> list = jsonDecode(listStr);
        for (int i = 0; i < list.length; i++) {
          if (list[i]['id'] == transactionId) {
            final Map<String, dynamic> oldMap = Map<String, dynamic>.from(list[i]);
            updates.forEach((k, v) => oldMap[k] = v);
            list[i] = oldMap;
            break;
          }
        }
        await prefs.setString(key, jsonEncode(list));
        _notifyTransactionControllers(uid);
      }
    } catch (_) {}

    try {
      await _col(uid, 'transactions').doc(transactionId).update(updates).timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
  }

  void _notifyTransactionControllers(String uid) async {
    if (_transactionControllers.isEmpty) return;
    try {
      final prefs = await _prefs;
      final key = 'local_transactions_$uid';
      final listStr = prefs.getString(key);
      if (listStr != null) {
        List<dynamic> list = jsonDecode(listStr);
        final items = list.map((e) => TransactionModel.fromMap(e['id'] ?? '', Map<String, dynamic>.from(e))).toList();
        _transactionControllers.forEach((_, ctrl) {
          if (!ctrl.isClosed) ctrl.add(items);
        });
      }
    } catch (_) {}
  }

  Stream<List<TransactionModel>> streamTransactions(
    String uid,
    String month,
  ) {
    final controllerKey = '${uid}_$month';
    if (!_transactionControllers.containsKey(controllerKey) || _transactionControllers[controllerKey]!.isClosed) {
      final ctrl = StreamController<List<TransactionModel>>.broadcast();
      _transactionControllers[controllerKey] = ctrl;

      _prefs.then((prefs) {
        final key = 'local_transactions_$uid';
        final listStr = prefs.getString(key);
        if (listStr != null) {
          List<dynamic> list = jsonDecode(listStr);
          final items = list.map((e) => TransactionModel.fromMap(e['id'] ?? '', Map<String, dynamic>.from(e))).toList();
          final filtered = items.where((t) => t.month == month || t.date.startsWith(month) || (t.month.isEmpty && t.date.isEmpty)).toList()..sort((a, b) => b.date.compareTo(a.date));
          if (!ctrl.isClosed) ctrl.add(filtered);
        }
      });

      _col(uid, 'transactions').snapshots().listen((snap) async {
        final items = snap.docs.map((d) => TransactionModel.fromMap(d.id, d.data())).toList();
        try {
          final prefs = await _prefs;
          final key = 'local_transactions_$uid';
          final listStr = prefs.getString(key);
          Map<String, Map<String, dynamic>> localMap = {};
          if (listStr != null) {
            List<dynamic> list = jsonDecode(listStr);
            for (var e in list) {
              localMap[e['id'] ?? ''] = Map<String, dynamic>.from(e);
            }
          }
          for (var item in items) {
            localMap[item.id] = {'id': item.id, ...item.toMap()};
          }
          await prefs.setString(key, jsonEncode(localMap.values.toList()));
        } catch (_) {}

        final filtered = items.where((t) => t.month == month || t.date.startsWith(month) || (t.month.isEmpty && t.date.isEmpty)).toList()..sort((a, b) => b.date.compareTo(a.date));
        if (!ctrl.isClosed) ctrl.add(filtered);
      }, onError: (_) {});
    }

    return _transactionControllers[controllerKey]!.stream;
  }

  Future<List<TransactionModel>> getTransactions(
    String uid,
    String month, {
    DocumentSnapshot? cursor,
    int pageSize = 15,
  }) async {
    var q = _col(uid, 'transactions')
        .where('month', isEqualTo: month)
        .orderBy('date', descending: true)
        .limit(pageSize);

    if (cursor != null) {
      q = q.startAfterDocument(cursor);
    }

    final snap = await q.get();
    return snap.docs
        .map((d) => TransactionModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getTransactionPage(
    String uid,
    String month, {
    DocumentSnapshot? cursor,
    int pageSize = 15,
  }) async {
    var q = _col(uid, 'transactions')
        .where('month', isEqualTo: month)
        .orderBy('date', descending: true)
        .limit(pageSize);

    if (cursor != null) {
      q = q.startAfterDocument(cursor);
    }

    return q.get();
  }

  // ─── Accounts ─────────────────────────────────────────────────────────────

  Future<void> addAccount(String uid, Map<String, dynamic> payload) {
    return _col(uid, 'accounts').add({
      ...payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> adjustAccountBalance(String uid, String accountId, double delta) async {
    try {
      final docRef = _col(uid, 'accounts').doc(accountId);
      await docRef.update({'balance': FieldValue.increment(delta)});
    } catch (e) {
      final docRef = _col(uid, 'accounts').doc(accountId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (snap.exists) {
          final current = (snap.data()?['balance'] as num?)?.toDouble() ?? 0.0;
          tx.update(docRef, {'balance': current + delta});
        }
      });
    }
  }

  Stream<List<AccountModel>> streamAccounts(String uid) {
    return _col(uid, 'accounts')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AccountModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ─── Budgets ──────────────────────────────────────────────────────────────

  Future<void> setBudget(
    String uid,
    String month,
    String category,
    Map<String, dynamic> payload,
  ) {
    final docId = '${month}_$category';
    return _col(uid, 'budgets').doc(docId).set({
      'month': month,
      'category': category,
      ...payload,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<BudgetModel>> streamBudgets(String uid, String month) {
    return _col(uid, 'budgets')
        .where('month', isEqualTo: month)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BudgetModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ─── Goals ────────────────────────────────────────────────────────────────

  Future<void> addGoal(String uid, Map<String, dynamic> payload) {
    return _col(uid, 'goals').add({
      ...payload,
      'saved': payload['saved'] ?? 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateGoal(
    String uid,
    String goalId,
    Map<String, dynamic> payload,
  ) {
    return _col(uid, 'goals').doc(goalId).update({
      ...payload,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<GoalModel>> streamGoals(String uid) {
    return _col(uid, 'goals')
        .orderBy('targetDate')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GoalModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ─── Reminders ────────────────────────────────────────────────────────────

  Future<void> addReminder(String uid, Map<String, dynamic> payload) {
    return _col(uid, 'reminders').add({
      ...payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Stream<List<ReminderModel>> streamReminders(String uid) {
    return _col(uid, 'reminders')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ReminderModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ─── Recurring Payments (Dual Sync: Local + Cloud) ────────────────────────

  Future<void> addRecurringPayment(
      String uid, Map<String, dynamic> payload) async {
    final completePayload = {
      ...payload,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final localId = 'rec_${DateTime.now().millisecondsSinceEpoch}';
    final model = RecurringPaymentModel.fromMap(localId, completePayload);
    await _saveLocalRecurringPayment(uid, model);

    try {
      await _col(uid, 'recurringPayments').add(completePayload).timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
  }

  Future<void> _saveLocalRecurringPayment(String uid, RecurringPaymentModel item) async {
    try {
      final prefs = await _prefs;
      final key = 'local_recurring_payments_$uid';
      final listStr = prefs.getString(key);
      List<dynamic> list = listStr != null ? jsonDecode(listStr) : [];
      list.removeWhere((e) => e['id'] == item.id);
      list.add({'id': item.id, ...item.toMap()});
      await prefs.setString(key, jsonEncode(list));
      _notifyRecurringControllers(uid);
    } catch (_) {}
  }

  Future<void> updateRecurringPayment(
      String uid, String id, Map<String, dynamic> payload) async {
    try {
      final prefs = await _prefs;
      final key = 'local_recurring_payments_$uid';
      final listStr = prefs.getString(key);
      if (listStr != null) {
        List<dynamic> list = jsonDecode(listStr);
        for (int i = 0; i < list.length; i++) {
          if (list[i]['id'] == id) {
            final Map<String, dynamic> oldMap = Map<String, dynamic>.from(list[i]);
            payload.forEach((k, v) => oldMap[k] = v);
            list[i] = oldMap;
            break;
          }
        }
        await prefs.setString(key, jsonEncode(list));
        _notifyRecurringControllers(uid);
      }
    } catch (_) {}

    try {
      await _col(uid, 'recurringPayments').doc(id).update(payload).timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
  }

  Future<void> deleteRecurringPayment(String uid, String id) async {
    try {
      final prefs = await _prefs;
      final key = 'local_recurring_payments_$uid';
      final listStr = prefs.getString(key);
      if (listStr != null) {
        List<dynamic> list = jsonDecode(listStr);
        list.removeWhere((e) => e['id'] == id);
        await prefs.setString(key, jsonEncode(list));
        _notifyRecurringControllers(uid);
      }
    } catch (_) {}

    try {
      await _col(uid, 'recurringPayments').doc(id).delete().timeout(const Duration(milliseconds: 1500));
    } catch (_) {}
  }

  Future<void> updateTransactionsByTitle(String uid, String oldTitleSubstring, {String? newTitle, double? newAmount}) async {
    try {
      final prefs = await _prefs;
      final key = 'local_transactions_$uid';
      final listStr = prefs.getString(key);
      if (listStr != null) {
        List<dynamic> list = jsonDecode(listStr);
        for (int i = 0; i < list.length; i++) {
          final title = list[i]['title'] as String? ?? '';
          if (title.contains(oldTitleSubstring) || title == oldTitleSubstring) {
            if (newTitle != null && newTitle.isNotEmpty) {
              list[i]['title'] = title.replaceAll(oldTitleSubstring, newTitle);
            }
            if (newAmount != null && newAmount > 0) {
              list[i]['amount'] = newAmount;
            }
          }
        }
        await prefs.setString(key, jsonEncode(list));
        _notifyTransactionControllers(uid);
      }
    } catch (_) {}

    try {
      final snap = await _col(uid, 'transactions').get();
      for (final doc in snap.docs) {
        final title = doc.data()['title'] as String? ?? '';
        if (title.contains(oldTitleSubstring) || title == oldTitleSubstring) {
          final Map<String, dynamic> updates = {};
          if (newTitle != null && newTitle.isNotEmpty) {
            updates['title'] = title.replaceAll(oldTitleSubstring, newTitle);
          }
          if (newAmount != null && newAmount > 0) {
            updates['amount'] = newAmount;
          }
          if (updates.isNotEmpty) {
            await doc.reference.update(updates).timeout(const Duration(milliseconds: 1000));
          }
        }
      }
    } catch (_) {}
  }

  void _notifyRecurringControllers(String uid) async {
    if (_recurringControllers.isEmpty) return;
    try {
      final prefs = await _prefs;
      final key = 'local_recurring_payments_$uid';
      final listStr = prefs.getString(key);
      if (listStr != null) {
        List<dynamic> list = jsonDecode(listStr);
        final items = list.map((e) => RecurringPaymentModel.fromMap(e['id'] ?? '', Map<String, dynamic>.from(e))).toList()..sort((a, b) => a.nextDate.compareTo(b.nextDate));
        _recurringControllers.forEach((_, ctrl) {
          if (!ctrl.isClosed) ctrl.add(items);
        });
      }
    } catch (_) {}
  }

  Stream<List<RecurringPaymentModel>> streamRecurringPayments(String uid) {
    if (!_recurringControllers.containsKey(uid) || _recurringControllers[uid]!.isClosed) {
      final ctrl = StreamController<List<RecurringPaymentModel>>.broadcast();
      _recurringControllers[uid] = ctrl;

      // 1. Önce yerel önbellekteki verileri hemen akışa ver (Sıfır gecikme & Kesin garanti)
      _prefs.then((prefs) {
        final key = 'local_recurring_payments_$uid';
        final listStr = prefs.getString(key);
        if (listStr != null) {
          List<dynamic> list = jsonDecode(listStr);
          final items = list.map((e) => RecurringPaymentModel.fromMap(e['id'] ?? '', Map<String, dynamic>.from(e))).toList()..sort((a, b) => a.nextDate.compareTo(b.nextDate));
          if (!ctrl.isClosed) ctrl.add(items);
        } else {
          if (!ctrl.isClosed) ctrl.add([]);
        }
      });

      // 2. Ardından Firestore'u dinle, veri gelirse önbelleği güncelle ve akışa ver (ağ hatası olsa bile akış bozulmaz)
      _col(uid, 'recurringPayments').snapshots().listen((snap) async {
        final items = snap.docs.map((d) => RecurringPaymentModel.fromMap(d.id, d.data())).toList()..sort((a, b) => a.nextDate.compareTo(b.nextDate));
        try {
          final prefs = await _prefs;
          final key = 'local_recurring_payments_$uid';
          final listStr = prefs.getString(key);
          Map<String, Map<String, dynamic>> localMap = {};
          if (listStr != null) {
            List<dynamic> list = jsonDecode(listStr);
            for (var e in list) {
              localMap[e['id'] ?? ''] = Map<String, dynamic>.from(e);
            }
          }
          for (var item in items) {
            localMap[item.id] = {'id': item.id, ...item.toMap()};
          }
          await prefs.setString(key, jsonEncode(localMap.values.toList()));
        } catch (_) {}

        if (!ctrl.isClosed) ctrl.add(items);
      }, onError: (_) async {
        try {
          final prefs = await _prefs;
          final key = 'local_recurring_payments_$uid';
          final listStr = prefs.getString(key);
          if (listStr != null) {
            List<dynamic> list = jsonDecode(listStr);
            final items = list.map((e) => RecurringPaymentModel.fromMap(e['id'] ?? '', Map<String, dynamic>.from(e))).toList()..sort((a, b) => a.nextDate.compareTo(b.nextDate));
            if (!ctrl.isClosed) ctrl.add(items);
          } else {
            if (!ctrl.isClosed) ctrl.add([]);
          }
        } catch (_) {
          if (!ctrl.isClosed) ctrl.add([]);
        }
      });
    }

    return _recurringControllers[uid]!.stream;
  }

  // ─── Assets (Varlıklar & Servet) ───────────────────────────────────────────

  Future<void> addAsset(String uid, Map<String, dynamic> payload) {
    return _col(uid, 'assets').add({
      ...payload,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateAsset(
    String uid,
    String id,
    Map<String, dynamic> payload,
  ) {
    return _col(uid, 'assets').doc(id).update(payload);
  }

  Future<void> deleteAsset(String uid, String id) {
    return _col(uid, 'assets').doc(id).delete();
  }

  Stream<List<AssetModel>> streamAssets(String uid) {
    return _col(uid, 'assets')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AssetModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}

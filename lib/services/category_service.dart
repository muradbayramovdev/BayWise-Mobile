import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Kullanıcının özel kategorilerini Firestore'da saklar.
/// Yapı: users/{uid}/categories/{income|expense} → { items: [...] }
class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid, String type) =>
      _db.collection('users').doc(uid).collection('categories').doc(type);

  /// Gelir veya gider kategorilerini stream olarak dinle.
  Stream<List<String>> streamCategories(String uid, String type) {
    return _doc(uid, type).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return type == 'income'
            ? List<String>.from(kDefaultIncomeCategories)
            : List<String>.from(kDefaultExpenseCategories);
      }
      final raw = snap.data()!['items'] as List<dynamic>?;
      if (raw == null || raw.isEmpty) {
        return type == 'income'
            ? List<String>.from(kDefaultIncomeCategories)
            : List<String>.from(kDefaultExpenseCategories);
      }
      return raw.cast<String>();
    });
  }

  /// Yeni kategori ekle.
  Future<void> addCategory(String uid, String type, String name) async {
    final snap = await _doc(uid, type).get();
    List<String> current;
    if (!snap.exists || snap.data() == null) {
      current = type == 'income'
          ? List<String>.from(kDefaultIncomeCategories)
          : List<String>.from(kDefaultExpenseCategories);
    } else {
      final raw = snap.data()!['items'] as List<dynamic>?;
      current = raw?.cast<String>() ??
          (type == 'income'
              ? List<String>.from(kDefaultIncomeCategories)
              : List<String>.from(kDefaultExpenseCategories));
    }
    if (!current.contains(name)) {
      current.add(name);
      await _doc(uid, type).set({'items': current});
    }
  }

  /// Kategori sil.
  Future<void> removeCategory(String uid, String type, String name) async {
    final snap = await _doc(uid, type).get();
    if (!snap.exists) return;
    final raw = snap.data()!['items'] as List<dynamic>?;
    final current = raw?.cast<String>() ?? [];
    current.remove(name);
    await _doc(uid, type).set({'items': current});
  }
}

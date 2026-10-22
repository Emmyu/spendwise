import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;

import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/dates.dart';
import 'transaction_repository.dart';

/// Expenses stored in Cloud Firestore: `accounts/demo/transactions/{id}`.
class FirestoreTransactionRepository implements TransactionRepository {
  FirestoreTransactionRepository({FirebaseFirestore? db, String accountId = 'demo'})
      : _col = (db ?? FirebaseFirestore.instance).collection('accounts').doc(accountId).collection('transactions');

  final CollectionReference<Map<String, dynamic>> _col;

  /// A write that never answers (no connection) should fail, not spin forever.
  static const _writeTimeout = Duration(seconds: 10);

  @override
  List<Transaction> get initial => const [];

  @override
  bool get loadsAsync => true;

  /// A new snapshot arrives whenever any document changes, including our own
  /// writes (instantly, before the server confirms them).
  @override
  Stream<List<Transaction>> watch() => _col.snapshots().map((s) => [for (final d in s.docs) _fromDoc(d)]);

  @override
  Future<void> add(Transaction tx) => _col.doc(tx.id).set(_toMap(tx)).timeout(_writeTimeout);

  @override
  Future<void> update(String id, TransactionEdit edit) => _col
      .doc(id)
      .update({
        'desc': edit.desc,
        'category': edit.category.name,
        'amount': edit.amount,
        'date': isoDate(edit.date),
        'note': edit.note,
      })
      .timeout(_writeTimeout);

  @override
  Future<void> delete(String id) => _col.doc(id).delete().timeout(_writeTimeout);

  static Map<String, Object?> _toMap(Transaction tx) => {
        'desc': tx.desc,
        'category': tx.category.name,
        'amount': tx.amount,
        'date': isoDate(tx.date), // "2026-10-13": no time zones to worry about
        'time': tx.time,
        'note': tx.note,
        'source': tx.source.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static Transaction _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final date = (d['date'] as String? ?? '').split('-').map(int.parse).toList();
    return Transaction(
      id: doc.id,
      desc: d['desc'] as String? ?? '',
      category: ExpenseCategory.values.asNameMap()[d['category']] ?? ExpenseCategory.other,
      amount: (d['amount'] as num? ?? 0).toDouble(),
      date: DateTime(date[0], date[1], date[2]),
      time: d['time'] as String? ?? '00:00',
      note: d['note'] as String? ?? '',
      source: d['source'] == 'ai' ? TxSource.ai : TxSource.manual,
    );
  }
}

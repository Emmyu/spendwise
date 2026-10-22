import '../models/transaction.dart';
import 'transaction_repository.dart';

/// Expenses stored in Cloud Firestore: `accounts/demo/transactions/{id}`.
///
/// TODO(step 3): fill this in. The app only talks to [TransactionRepository],
/// so once this works, switching from memory to Firestore changes nothing else.
class FirestoreTransactionRepository implements TransactionRepository {
  @override
  List<Transaction> get initial => const [];

  @override
  bool get loadsAsync => true;

  // TODO(step 3): return a live stream: collection.snapshots().map(...)
  @override
  Stream<List<Transaction>> watch() => throw UnimplementedError('TODO(step 3)');

  // TODO(step 3): collection.doc(tx.id).set({...})
  @override
  Future<void> add(Transaction tx) => throw UnimplementedError('TODO(step 3)');

  @override
  Future<void> update(String id, TransactionEdit edit) => throw UnimplementedError('TODO(step 3)');

  @override
  Future<void> delete(String id) => throw UnimplementedError('TODO(step 3)');

}

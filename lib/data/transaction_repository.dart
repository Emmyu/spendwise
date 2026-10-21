import 'dart:async';

import '../models/transaction.dart';
import 'mock_data.dart';

/// Where expenses live. The UI only talks to this interface, so the app runs
/// the same on the in-memory demo data and on Firestore.
abstract interface class TransactionRepository {
  /// What to show before the first update arrives (empty for a database).
  List<Transaction> get initial;

  /// True when [initial] is just a placeholder, so the UI shows "loading"
  /// until the first snapshot arrives.
  bool get loadsAsync;

  /// Every transaction; emits again whenever anything changes.
  Stream<List<Transaction>> watch();

  Future<void> add(Transaction tx);
  Future<void> update(String id, TransactionEdit edit);
  Future<void> delete(String id);
}

/// Demo data held in memory. Resets on restart. Used for tests, the
/// design-states gallery, and as the fallback when Firebase isn't set up.
class InMemoryTransactionRepository implements TransactionRepository {
  InMemoryTransactionRepository({
    List<Transaction>? seed,
    this.latency = const Duration(milliseconds: 400),
  }) : _items = [...(seed ?? baseTransactions)];

  /// Fake network delay so "Saving…" is visible, like a real write.
  final Duration latency;

  List<Transaction> _items;

  // sync: true so listeners see changes immediately (keeps tests simple).
  final _changes = StreamController<List<Transaction>>.broadcast(sync: true);

  @override
  List<Transaction> get initial => List.unmodifiable(_items);

  @override
  bool get loadsAsync => false;

  @override
  Stream<List<Transaction>> watch() => _changes.stream;

  /// Replaces everything (used by the design-states gallery).
  void reset(List<Transaction> items) => _set([...items]);

  @override
  Future<void> add(Transaction tx) async {
    await Future<void>.delayed(latency);
    _set([..._items.where((t) => t.id != tx.id), tx]);
  }

  @override
  Future<void> update(String id, TransactionEdit edit) async {
    await Future<void>.delayed(latency);
    _set([for (final t in _items) t.id == id ? edit.applyTo(t) : t]);
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(latency);
    _set(_items.where((t) => t.id != id).toList());
  }

  void _set(List<Transaction> items) {
    _items = items;
    _changes.add(initial);
  }
}

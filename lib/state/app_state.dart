import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../data/transaction_repository.dart';
import '../models/category.dart';
import '../models/chat.dart';
import '../models/design_state.dart';
import '../models/expense_form.dart';
import '../models/transaction.dart';
import '../services/ai_assistant.dart';
import '../services/mock_ai.dart';
import '../utils/dates.dart';
import '../utils/format.dart';
import '../utils/spending.dart';

enum AppTab { home, ai, transactions }

enum OverlayKind { none, detail, delete, form }

enum TxLoadState { ready, loading, error }

enum TxRange {
  month('This month'),
  week('This week'),
  last30('Last 30 days');

  const TxRange(this.label);

  final String label;

  TxRange get next => values[(index + 1) % values.length];
}

enum TxGrouping { day, month }

class TxGroup {
  const TxGroup({required this.label, required this.total, required this.items});

  final String label;
  final double total;
  final List<Transaction> items;
}

class DayTotal {
  const DayTotal(this.day, this.amount, {required this.isToday});

  final DateTime day;
  final double amount;
  final bool isToday;
}

/// All app state, mirroring the prototype's single state object.
/// Keeps a debug error readable in a chat bubble.
String _shorten(String error) => error.length <= 300 ? error : '${error.substring(0, 300)}…';

class AppState extends ChangeNotifier {
  AppState({
    AiAssistant? assistant,
    TransactionRepository? repository,
    DateTime? today,
    DesignState initial = DesignState.home,
  })  : _ai = assistant ?? MockAiAssistant(today: today),
        _loadsSampleData = repository == null,
        _repo = repository ?? InMemoryTransactionRepository(),
        today = today ?? kToday {
    _seedAi = MockAiAssistant(today: this.today);
    _all = _repo.initial;
    _seed(initial);
    _subscribe();
  }

  final AiAssistant _ai;
  final TransactionRepository _repo;

  /// Only when no repository was passed in (tests, previews): then the sample
  /// expenses are loaded. A repository you pass in is used exactly as it is, so a
  /// fresh app starts empty.
  final bool _loadsSampleData;

  /// Used only to seed the design-state conversations.
  late final MockAiAssistant _seedAi;

  final DateTime today;

  // ── Navigation and overlays ──────────────────────────────────────────────
  late DesignState _designState;
  AppTab _tab = AppTab.home;
  OverlayKind _overlay = OverlayKind.none;
  String? _detailId;

  // ── Transactions view ────────────────────────────────────────────────────
  TxLoadState _txLoad = TxLoadState.ready;
  String _search = '';
  ExpenseCategory? _categoryFilter;
  TxRange _range = TxRange.month;
  TxGrouping _grouping = TxGrouping.day;

  // ── Data ─────────────────────────────────────────────────────────────────
  /// Everything the repository last told us about.
  List<Transaction> _all = const [];
  StreamSubscription<List<Transaction>>? _sub;

  // ── Chat ─────────────────────────────────────────────────────────────────
  List<ChatMessage> _messages = [];
  BusyState? _busy;

  /// Bumped by "new chat" so an answer that arrives late is thrown away.
  int _chatEpoch = 0;

  // ── Misc UI ──────────────────────────────────────────────────────────────
  ExpenseFormData? _form;
  int _formSession = 0;
  String? _toast;
  int _toastSeq = 0;
  bool _hideAmounts = false;
  bool _deleting = false;

  int _seq = 0;

  /// Makes ids unique across app launches (several people share one database).
  final String _session = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final Map<String, List<Timer>> _timers = {};
  bool _disposed = false;
  List<Transaction>? _txCache;

  // ── Getters ──────────────────────────────────────────────────────────────
  DesignState get designState => _designState;
  AppTab get tab => _tab;
  OverlayKind get overlay => _overlay;
  String? get detailId => _detailId;
  TxLoadState get txLoad => _txLoad;
  String get search => _search;
  ExpenseCategory? get categoryFilter => _categoryFilter;
  TxRange get range => _range;
  TxGrouping get grouping => _grouping;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  BusyState? get busy => _busy;
  ExpenseFormData? get form => _form;

  /// Changes every time a new form is opened, so form widgets can reset.
  int get formSession => _formSession;
  String? get toast => _toast;
  bool get hideAmounts => _hideAmounts;
  bool get deleting => _deleting;

  /// Formats an amount, honouring "Hide amounts".
  String displayMoney(num n) => _hideAmounts ? maskedMoney : money(n);

  /// What the assistant is running on, e.g. the Gemini model name.
  String? get assistantLabel => _ai.label;

  /// Every recorded transaction, newest first.
  List<Transaction> get transactions => _txCache ??= sortNewestFirst(_all);

  /// Spending in the same days of last month (the "than 1–13 Sep" figure).
  double get previousPeriodSpend => previousPeriodTotal(transactions, today);

  List<Transaction> get monthTransactions =>
      transactions.where((t) => isSameMonth(t.date, today)).toList();

  double get monthTotal => sumOf(monthTransactions);

  double get dailyAverage => monthTotal / today.day;

  List<CategoryTotal> get monthBreakdown => categoryBreakdown(monthTransactions);

  List<Transaction> get recentTransactions => transactions.take(4).toList();

  List<DayTotal> get lastSevenDays => [
        for (var i = 6; i >= 0; i--)
          () {
            final day = addDays(today, -i);
            return DayTotal(
              day,
              sumOf(transactions.where((t) => isSameDay(t.date, day))),
              isToday: i == 0,
            );
          }(),
      ];

  bool get isFiltered => _search.trim().isNotEmpty || _categoryFilter != null;

  List<Transaction> get filteredTransactions {
    Iterable<Transaction> list = transactions.where((t) => switch (_range) {
          TxRange.month => isSameMonth(t.date, today),
          TxRange.week => !t.date.isBefore(startOfWeek(today)),
          TxRange.last30 => !t.date.isBefore(addDays(today, -29)),
        });
    final cat = _categoryFilter;
    if (cat != null) list = list.where((t) => t.category == cat);
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((t) => '${t.desc} ${t.note} ${t.category.label}'.toLowerCase().contains(q));
    }
    return list.toList();
  }

  List<TxGroup> get transactionGroups {
    final groups = <String, List<Transaction>>{};
    final labels = <String, String>{};
    for (final t in filteredTransactions) {
      final byDay = _grouping == TxGrouping.day;
      final key = byDay ? isoDate(t.date) : isoMonth(t.date);
      labels[key] ??= byDay ? dayLabel(t.date, today: today) : monthLabel(t.date);
      (groups[key] ??= []).add(t);
    }
    return [
      for (final e in groups.entries)
        TxGroup(label: labels[e.key]!, total: sumOf(e.value), items: e.value),
    ];
  }

  Transaction? get detailTransaction {
    final id = _detailId;
    if (id == null) return null;
    return transactions.where((t) => t.id == id).firstOrNull;
  }

  // ── Navigation ───────────────────────────────────────────────────────────
  void goTo(AppTab tab) {
    _tab = tab;
    _overlay = OverlayKind.none;
    notifyListeners();
  }

  void openDetail(String id, {bool showInTransactions = false}) {
    if (showInTransactions) _tab = AppTab.transactions;
    _overlay = OverlayKind.detail;
    _detailId = id;
    notifyListeners();
  }

  void closeOverlay() {
    _overlay = OverlayKind.none;
    notifyListeners();
  }

  void askDelete() {
    _overlay = OverlayKind.delete;
    notifyListeners();
  }

  void cancelDelete() {
    if (_deleting) return;
    _overlay = OverlayKind.detail;
    notifyListeners();
  }

  /// Handles the system back gesture. Returns true if it closed something.
  bool handleBack() {
    switch (_overlay) {
      case OverlayKind.delete:
        cancelDelete();
        return true;
      case OverlayKind.detail:
        closeOverlay();
        return true;
      case OverlayKind.form:
        if (!(_form?.saving ?? false)) closeForm();
        return true;
      case OverlayKind.none:
        return false;
    }
  }

  // ── Transactions view ────────────────────────────────────────────────────
  void setSearch(String value) {
    if (value == _search) return;
    _search = value;
    notifyListeners();
  }

  void setCategoryFilter(ExpenseCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void cycleRange() {
    _range = _range.next;
    notifyListeners();
  }

  void setGrouping(TxGrouping grouping) {
    _grouping = grouping;
    notifyListeners();
  }

  void clearFilters() {
    _search = '';
    _categoryFilter = null;
    _range = TxRange.month;
    notifyListeners();
  }

  void retryLoad() {
    _txLoad = TxLoadState.loading;
    notifyListeners();
    _subscribe();
    if (_repo.loadsAsync) return; // the first snapshot flips us back to ready
    _later(1100, () {
      _txLoad = TxLoadState.ready;
      notifyListeners();
    });
  }

  /// Listens to the repository. Every change (ours or someone else's) arrives here.
  void _subscribe() {
    _sub?.cancel();
    if (_repo.loadsAsync && _txLoad == TxLoadState.ready) _txLoad = TxLoadState.loading;
    _sub = _repo.watch().listen(
      (list) {
        _all = list;
        if (_txLoad != TxLoadState.ready) _txLoad = TxLoadState.ready;
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Could not load transactions: $e');
        _txLoad = TxLoadState.error;
        notifyListeners();
      },
    );
  }

  // ── Expense form ─────────────────────────────────────────────────────────
  void openNewExpense() {
    _openForm(ExpenseFormData(
      mode: FormMode.create,
      amount: '',
      desc: '',
      category: ExpenseCategory.food,
      date: today,
      note: '',
    ));
  }

  void openEditExpense() {
    final tx = detailTransaction;
    if (tx == null) return;
    _openForm(_formFrom(tx, FormMode.edit, tx.id));
  }

  void editProposal(String messageId) {
    final msg = _messages.where((m) => m.id == messageId).firstOrNull;
    final proposal = msg?.proposal;
    if (proposal == null) return;
    _openForm(_formFrom(proposal.tx, FormMode.ai, messageId));
  }

  ExpenseFormData _formFrom(Transaction tx, FormMode mode, String target) => ExpenseFormData(
        mode: mode,
        target: target,
        amount: amountInputText(tx.amount),
        desc: tx.desc,
        category: tx.category,
        date: tx.date,
        note: tx.note,
      );

  void _openForm(ExpenseFormData form) {
    _form = form;
    _formSession++;
    _overlay = OverlayKind.form;
    notifyListeners();
  }

  void updateForm({
    String? amount,
    String? desc,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
  }) {
    final f = _form;
    if (f == null) return;
    _form = f.copyWith(
      amount: amount,
      desc: desc,
      category: category,
      date: date,
      note: note,
      amountError: amount != null ? null : f.amountError,
      descError: desc != null ? null : f.descError,
    );
    notifyListeners();
  }

  void closeForm() {
    _overlay = _form?.mode == FormMode.edit ? OverlayKind.detail : OverlayKind.none;
    _form = null;
    notifyListeners();
  }

  /// Validation messages, matching the prototype.
  static ({String? amount, String? desc}) validate(String amountText, String desc) {
    final amt = parseLeadingNumber(amountText.replaceAll(',', ''));
    String? amountError;
    if (amountText.trim().isEmpty) {
      amountError = 'Enter an amount';
    } else if (amt == null || !(amt > 0)) {
      amountError = 'Amount must be greater than ₦0';
    } else if (amt > MockAiAssistant.maxAmount) {
      amountError = 'That amount looks too large. Check it and try again';
    }
    return (amount: amountError, desc: desc.trim().isEmpty ? 'Add a short description' : null);
  }

  void saveForm() {
    final f = _form;
    if (f == null || f.saving) return;
    final errors = validate(f.amount, f.desc);
    if (errors.amount != null || errors.desc != null) {
      _form = f.copyWith(amountError: errors.amount, descError: errors.desc);
      notifyListeners();
      return;
    }
    final edit = TransactionEdit(
      desc: f.desc.trim(),
      category: f.category,
      amount: parseLeadingNumber(f.amount.replaceAll(',', ''))!,
      date: f.date,
      note: f.note.trim(),
    );

    if (f.mode == FormMode.ai) {
      _messages = [
        for (final m in _messages)
          if (m.id == f.target && m.proposal != null)
            m.withProposal(m.proposal!.copyWith(status: ProposalStatus.proposed, tx: edit.applyTo(m.proposal!.tx)))
          else
            m,
      ];
      _overlay = OverlayKind.none;
      _form = null;
      notifyListeners();
      return;
    }

    _form = f.copyWith(saving: true, amountError: null, descError: null);
    notifyListeners();
    _write(f, edit);
  }

  Future<void> _write(ExpenseFormData f, TransactionEdit edit) async {
    final editing = f.mode == FormMode.edit;
    try {
      if (editing) {
        await _repo.update(f.target!, edit);
      } else {
        await _repo.add(Transaction(
          id: 'm-$_session-${++_seq}',
          desc: edit.desc,
          category: edit.category,
          amount: edit.amount,
          date: edit.date,
          time: nowTime(),
          note: edit.note,
        ));
      }
    } catch (e) {
      debugPrint('Could not save expense: $e');
      if (_disposed) return;
      _form = _form?.copyWith(saving: false); // keep the form open so nothing is lost
      notifyListeners();
      showToast('Couldn’t save. Check your connection and try again.');
      return;
    }
    if (_disposed) return;
    _overlay = editing ? OverlayKind.detail : OverlayKind.none;
    _form = null;
    notifyListeners();
    showToast(editing ? 'Changes saved' : 'Expense saved');
  }

  // ── Delete ───────────────────────────────────────────────────────────────
  Future<void> deleteSelected() async {
    final id = _detailId;
    if (_deleting || id == null) return;
    _deleting = true;
    notifyListeners();
    try {
      await _repo.delete(id);
    } catch (e) {
      debugPrint('Could not delete: $e');
      if (_disposed) return;
      _deleting = false;
      notifyListeners();
      showToast('Couldn’t delete. Check your connection and try again.');
      return;
    }
    if (_disposed) return;
    _overlay = OverlayKind.none;
    _detailId = null;
    _deleting = false;
    notifyListeners();
    showToast('Transaction deleted');
  }

  // ── Chat ─────────────────────────────────────────────────────────────────
  /// Sends [raw] to the assistant. Returns false if it was ignored (empty, or
  /// the assistant is still working on the previous message).
  bool send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;
    if (_busy != null && !_busy!.frozen) return false;

    final epoch = _chatEpoch;
    _messages = [..._messages, ChatMessage.user(_nextId('u'), text)];
    _busy = const BusyState('Understanding your request');
    notifyListeners();

    _respondWithRetry(AssistantRequest(
          text: text,
          transactions: () => transactions,
          today: today,
          nextId: () => _nextId('a'),
          onWorking: (label, {tool}) {
            if (epoch != _chatEpoch || _disposed) return;
            _busy = BusyState(label, tool: tool);
            notifyListeners();
          },
        ))
        .then<ChatMessage>((reply) => reply, onError: (Object e) {
          debugPrint('Assistant error: $e');
          return ChatMessage(
            id: _nextId('a'),
            role: ChatRole.ai,
            text: 'I couldn’t reach the assistant just now. Check your connection and try again.'
                // While developing, show the real reason right here (model name, network, project setup...).
                '${kDebugMode ? '\n\n(debug) ${_shorten('$e')}' : ''}',
          );
        })
        .then((reply) {
          if (epoch != _chatEpoch || _disposed) return; // "new chat" was tapped meanwhile
          _busy = null;
          _messages = [..._messages, reply];
          notifyListeners();
        });
    return true;
  }

  /// The only place an AI-proposed expense is ever written to the database.
  /// Asks the assistant. If the connection drops (it happens on busy Wi-Fi), start a
  /// fresh chat and try once more, so a blip doesn't cost the user their question.
  Future<ChatMessage> _respondWithRetry(AssistantRequest request) async {
    try {
      return await _ai.respond(request);
    } catch (e) {
      debugPrint('Assistant error, trying once more with a fresh chat: $e');
      _ai.reset();
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return _ai.respond(request);
    }
  }

  Future<void> confirmProposal(String messageId) async {
    final proposal = _messages.where((m) => m.id == messageId).firstOrNull?.proposal;
    if (proposal == null) return;
    final epoch = _chatEpoch;
    final tx = proposal.tx;
    _setProposalStatus(messageId, ProposalStatus.saving);
    try {
      await _repo.add(tx);
    } catch (e) {
      debugPrint('Could not save proposal: $e');
      if (!_disposed) _setProposalStatus(messageId, ProposalStatus.failed);
      return;
    }
    if (_disposed || epoch != _chatEpoch) return;
    _setProposalStatus(messageId, ProposalStatus.saved, notify: false);
    final afterSave = [...transactions.where((t) => t.id != tx.id), tx];
    _messages = [..._messages, _ai.savedMessage(tx, afterSave, _nextId('a'))];
    notifyListeners();
  }

  void _setProposalStatus(String messageId, ProposalStatus status, {bool notify = true}) {
    _messages = [
      for (final m in _messages)
        if (m.id == messageId && m.proposal != null) m.withProposal(m.proposal!.copyWith(status: status)) else m,
    ];
    if (notify) notifyListeners();
  }

  void resetChat() {
    _chatEpoch++;
    _ai.reset();
    _messages = [];
    _busy = null;
    notifyListeners();
  }

  // ── Preferences and feedback ─────────────────────────────────────────────
  void toggleHideAmounts() {
    _hideAmounts = !_hideAmounts;
    notifyListeners();
  }

  void showToast(String text) {
    _toast = text;
    final seq = ++_toastSeq;
    notifyListeners();
    _later(2400, () {
      if (_toastSeq != seq) return;
      _toast = null;
      notifyListeners();
    }, group: 'toast');
  }

  // ── Design states (used by the widget tests) ────────────────────────────────────────
  void applyDesignState(DesignState s) {
    _cancelTimers();
    _seed(s);
    notifyListeners();
  }

  void _seed(DesignState s) {
    _designState = s;
    _tab = AppTab.home;
    _overlay = OverlayKind.none;
    _detailId = null;
    _txLoad = TxLoadState.ready;
    _search = '';
    _categoryFilter = null;
    _range = TxRange.month;
    _grouping = TxGrouping.day;
    _chatEpoch++;
    _ai.reset();
    _messages = [];
    _busy = null;
    _form = null;
    _formSession++;
    _toast = null;
    _hideAmounts = false;
    _deleting = false;
    _txCache = null;

    // The gallery's demo data: the lunch expense is in most states, not all.
    final withLunch = !const {
      DesignState.aiInitial,
      DesignState.aiConvo,
      DesignState.aiConfirm,
      DesignState.aiError,
    }.contains(s);
    final repo = _repo;
    if (_loadsSampleData && repo is InMemoryTransactionRepository) {
      _all = [...baseTransactions, if (withLunch) lunchTransaction];
      repo.reset(_all);
    }

    const lunchAsk = ChatMessage.user('m1', 'I spent ₦4,500 on lunch today.');
    ChatMessage lunchProposal(ProposalStatus status) => ChatMessage(
          id: 'm2',
          role: ChatRole.ai,
          text: 'Here’s what I understood. Nothing is saved until you confirm.',
          proposal: ProposalCardData(status: status, tx: lunchTransaction),
        );

    switch (s) {
      case DesignState.home:
        break;
      case DesignState.transactions:
        _tab = AppTab.transactions;
      case DesignState.txDetail:
        _tab = AppTab.transactions;
        _overlay = OverlayKind.detail;
        _detailId = lunchTransaction.id;
      case DesignState.deleteConfirm:
        _tab = AppTab.transactions;
        _overlay = OverlayKind.delete;
        _detailId = 'b3';
      case DesignState.txLoading:
        _tab = AppTab.transactions;
        _txLoad = TxLoadState.loading;
      case DesignState.txEmpty:
        _tab = AppTab.transactions;
        _search = 'pizza';
      case DesignState.txError:
        _tab = AppTab.transactions;
        _txLoad = TxLoadState.error;
      case DesignState.aiInitial:
        _tab = AppTab.ai;
      case DesignState.aiConvo:
        _tab = AppTab.ai;
        _messages = [
          const ChatMessage.user('m0', 'What is my biggest expense category?'),
          _seedAi.answer(SpendingQuestion.biggest, transactions, 'm01'),
          lunchAsk,
        ];
        _busy = const BusyState('Preparing expense details', tool: 'add_expense · draft', frozen: true);
      case DesignState.aiConfirm:
        _tab = AppTab.ai;
        _messages = [lunchAsk, lunchProposal(ProposalStatus.proposed)];
      case DesignState.aiSuccess:
        _tab = AppTab.ai;
        _messages = [
          lunchAsk,
          lunchProposal(ProposalStatus.saved),
          _seedAi.savedMessage(lunchTransaction, transactions, 'm3'),
        ];
      case DesignState.aiAnalysis:
        _tab = AppTab.ai;
        _messages = [
          const ChatMessage.user('m1', 'How much have I spent on food this week?'),
          _seedAi.answer(SpendingQuestion.week, transactions, 'm2', category: ExpenseCategory.food),
        ];
      case DesignState.aiError:
        _tab = AppTab.ai;
        _messages = [
          const ChatMessage.user('m1', 'I spent money on transport'),
          const ChatMessage(
            id: 'm2',
            role: ChatRole.ai,
            text: 'How much did you spend on transport? Tell me the amount and I’ll prepare the expense for you to review.',
            chips: ['₦1,500', '₦2,500', '₦5,000'],
          ),
          const ChatMessage.user('m3', '₦2,500 for a Bolt ride'),
          ChatMessage(
            id: 'm4',
            role: ChatRole.ai,
            text: 'Here’s what I understood.',
            proposal: ProposalCardData(
              status: ProposalStatus.failed,
              tx: Transaction(
                id: 'ai-bolt',
                desc: 'Bolt ride',
                category: ExpenseCategory.transport,
                amount: 2500,
                date: today,
                time: '18:05',
                source: TxSource.ai,
              ),
            ),
          ),
        ];
      case DesignState.addExpense:
        _overlay = OverlayKind.form;
        _form = ExpenseFormData(
          mode: FormMode.create,
          amount: '8,000',
          desc: 'Fuel',
          category: ExpenseCategory.transport,
          date: today,
          note: 'Total, Admiralty Way',
        );
    }
  }

  // ── Internals ────────────────────────────────────────────────────────────
  String _nextId(String prefix) => '$prefix$_session-${++_seq}';

  void _later(int ms, VoidCallback fn, {String group = 'app'}) {
    late final Timer timer;
    timer = Timer(Duration(milliseconds: ms), () {
      _timers[group]?.remove(timer);
      if (_disposed) return;
      fn();
    });
    (_timers[group] ??= []).add(timer);
  }

  void _cancelTimers([String? group]) {
    final groups = group == null ? _timers.keys.toList() : [group];
    for (final g in groups) {
      for (final t in _timers[g] ?? const <Timer>[]) {
        t.cancel();
      }
      _timers.remove(g);
    }
  }

  @override
  void notifyListeners() {
    _txCache = null;
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _cancelTimers();
    super.dispose();
  }
}

/// Amount as typed into the form, e.g. 4500 → "4,500", 12.5 → "12.5".
String amountInputText(double amount) {
  if (amount == amount.roundToDouble()) return plainAmount(amount);
  final whole = amount.truncate();
  final frac = amount.toStringAsFixed(2).split('.').last.replaceFirst(RegExp(r'0+$'), '');
  return '${plainAmount(whole)}.$frac';
}

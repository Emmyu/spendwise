/// Every screen and state from the prototype's "jump to any state" rail.
/// Used by the widget tests to put the app into any screen.
enum DesignState {
  home('Home'),
  transactions('Transactions'),
  txDetail('Transaction details'),
  deleteConfirm('Delete confirmation'),
  addExpense('Add expense'),
  aiInitial('Initial state'),
  aiConvo('During a conversation'),
  aiConfirm('Expense confirmation'),
  aiSuccess('Expense saved'),
  aiAnalysis('Spending analysis'),
  aiError('Ambiguous request, failed save'),
  txLoading('Loading'),
  txEmpty('No results'),
  txError('Couldn’t load');

  const DesignState(this.label);

  final String label;
}

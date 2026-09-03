import 'package:bloc/bloc.dart';

import '../../data/repositories/expenses_repository.dart';
import '../../domain/read_models/read_models.dart';
import '../read_status.dart';

class ExpensesState {
  const ExpensesState({
    required this.status,
    this.expenses = const [],
    this.message,
  });

  const ExpensesState.loading({List<ExpenseReadModel> expenses = const []})
    : this(status: ReadStatus.loading, expenses: expenses);

  const ExpensesState.loaded(List<ExpenseReadModel> expenses)
    : this(status: ReadStatus.loaded, expenses: expenses);

  const ExpensesState.empty()
    : this(status: ReadStatus.empty, expenses: const []);

  const ExpensesState.error(
    String message, {
    List<ExpenseReadModel> expenses = const [],
  }) : this(status: ReadStatus.error, expenses: expenses, message: message);

  const ExpensesState.corruptionRecovery(String message)
    : this(status: ReadStatus.corruptionRecovery, message: message);

  final ReadStatus status;
  final List<ExpenseReadModel> expenses;
  final String? message;
}

class ExpensesCubit extends Cubit<ExpensesState> {
  ExpensesCubit({required ExpensesReader reader, required this.groupId})
    : _reader = reader,
      super(const ExpensesState.loading());

  final ExpensesReader _reader;
  final String groupId;

  Future<void> load({bool propagateFailure = false}) async {
    if (isClosed) return;
    emit(ExpensesState.loading(expenses: state.expenses));
    try {
      final expenses = await _reader.listExpenses(groupId);
      if (isClosed) return;
      emit(
        expenses.isEmpty
            ? const ExpensesState.empty()
            : ExpensesState.loaded(expenses),
      );
    } on Object catch (error, stackTrace) {
      if (isClosed) return;
      emit(
        isCorruptionFailure(error)
            ? ExpensesState.corruptionRecovery(
                recoveryMessage('expense history'),
              )
            : ExpensesState.error(
                readFailureMessage(error, 'expense history'),
                expenses: state.expenses,
              ),
      );
      if (propagateFailure) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reload() => load();

  Future<void> reloadForRefresh() => load(propagateFailure: true);
}

typedef ExpenseHistoryCubit = ExpensesCubit;

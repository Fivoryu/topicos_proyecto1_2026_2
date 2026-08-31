import 'package:bloc/bloc.dart';

import '../../data/repositories/balances_repository.dart';
import '../../domain/read_models/read_models.dart';
import '../read_status.dart';

class BalancesState {
  const BalancesState({required this.status, this.balances, this.message});

  const BalancesState.loading({BalancesReadModel? balances})
    : this(status: ReadStatus.loading, balances: balances);

  const BalancesState.loaded(BalancesReadModel balances)
    : this(status: ReadStatus.loaded, balances: balances);

  const BalancesState.empty(BalancesReadModel balances)
    : this(status: ReadStatus.empty, balances: balances);

  const BalancesState.error(String message, {BalancesReadModel? balances})
    : this(status: ReadStatus.error, balances: balances, message: message);

  const BalancesState.corruptionRecovery(String message)
    : this(status: ReadStatus.corruptionRecovery, message: message);

  final ReadStatus status;
  final BalancesReadModel? balances;
  final String? message;
}

class BalancesCubit extends Cubit<BalancesState> {
  BalancesCubit({required BalancesReader reader, required this.groupId})
    : _reader = reader,
      super(const BalancesState.loading());

  final BalancesReader _reader;
  final String groupId;

  Future<void> load() async {
    emit(BalancesState.loading(balances: state.balances));
    try {
      final balances = await _reader.getBalances(groupId);
      emit(
        balances.participants.isEmpty
            ? BalancesState.empty(balances)
            : BalancesState.loaded(balances),
      );
    } on Object catch (error) {
      emit(
        isCorruptionFailure(error)
            ? BalancesState.corruptionRecovery(recoveryMessage('balances'))
            : BalancesState.error(
                readFailureMessage(error, 'balances'),
                balances: state.balances,
              ),
      );
    }
  }

  Future<void> reload() => load();
}

typedef BalanceCubit = BalancesCubit;

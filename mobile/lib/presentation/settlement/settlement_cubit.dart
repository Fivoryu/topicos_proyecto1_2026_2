import 'package:bloc/bloc.dart';

import '../../data/repositories/settlement_repository.dart';
import '../../domain/read_models/read_models.dart';
import '../read_status.dart';

class SettlementState {
  const SettlementState({required this.status, this.settlement, this.message});

  const SettlementState.loading({SettlementReadModel? settlement})
    : this(status: ReadStatus.loading, settlement: settlement);

  const SettlementState.loaded(SettlementReadModel settlement)
    : this(status: ReadStatus.loaded, settlement: settlement);

  const SettlementState.empty(SettlementReadModel settlement)
    : this(status: ReadStatus.empty, settlement: settlement);

  const SettlementState.error(String message, {SettlementReadModel? settlement})
    : this(status: ReadStatus.error, settlement: settlement, message: message);

  const SettlementState.corruptionRecovery(String message)
    : this(status: ReadStatus.corruptionRecovery, message: message);

  final ReadStatus status;
  final SettlementReadModel? settlement;
  final String? message;
}

class SettlementCubit extends Cubit<SettlementState> {
  SettlementCubit({required SettlementReader reader, required this.groupId})
    : _reader = reader,
      super(const SettlementState.loading());

  final SettlementReader _reader;
  final String groupId;

  Future<void> load() async {
    emit(SettlementState.loading(settlement: state.settlement));
    try {
      final settlement = await _reader.getSettlement(groupId);
      emit(
        settlement.settled || settlement.transfers.isEmpty
            ? SettlementState.empty(settlement)
            : SettlementState.loaded(settlement),
      );
    } on Object catch (error) {
      emit(
        isCorruptionFailure(error)
            ? SettlementState.corruptionRecovery(recoveryMessage('settlement'))
            : SettlementState.error(
                readFailureMessage(error, 'settlement'),
                settlement: state.settlement,
              ),
      );
    }
  }

  Future<void> reload() => load();
}

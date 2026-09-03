import 'package:bloc/bloc.dart';

import '../../data/repositories/group_repository.dart';
import '../../domain/read_models/read_models.dart';
import '../read_status.dart';

class GroupState {
  const GroupState({required this.status, this.group, this.message});

  const GroupState.loading({GroupReadModel? group})
    : this(status: ReadStatus.loading, group: group);

  const GroupState.loaded(GroupReadModel group)
    : this(status: ReadStatus.loaded, group: group);

  const GroupState.error(String message, {GroupReadModel? group})
    : this(status: ReadStatus.error, group: group, message: message);

  const GroupState.corruptionRecovery(String message)
    : this(status: ReadStatus.corruptionRecovery, message: message);

  final ReadStatus status;
  final GroupReadModel? group;
  final String? message;
}

class GroupCubit extends Cubit<GroupState> {
  GroupCubit({required GroupReader reader, required this.groupId})
    : _reader = reader,
      super(const GroupState.loading());

  final GroupReader _reader;
  final String groupId;

  Future<void> load({bool propagateFailure = false}) async {
    if (isClosed) return;
    emit(GroupState.loading(group: state.group));
    try {
      final group = await _reader.getGroup(groupId);
      if (isClosed) return;
      emit(GroupState.loaded(group));
    } on Object catch (error, stackTrace) {
      if (isClosed) return;
      emit(
        isCorruptionFailure(error)
            ? GroupState.corruptionRecovery(recoveryMessage('group'))
            : GroupState.error(
                readFailureMessage(error, 'group'),
                group: state.group,
              ),
      );
      if (propagateFailure) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reload() => load();

  Future<void> reloadForRefresh() => load(propagateFailure: true);
}

typedef GroupReadCubit = GroupCubit;

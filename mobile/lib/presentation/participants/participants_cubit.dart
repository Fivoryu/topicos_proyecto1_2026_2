import 'package:bloc/bloc.dart';

import '../../data/repositories/participants_repository.dart';
import '../../domain/read_models/read_models.dart';
import '../read_status.dart';

class ParticipantsState {
  const ParticipantsState({
    required this.status,
    this.participants = const [],
    this.message,
  });

  const ParticipantsState.loading({
    List<ParticipantReadModel> participants = const [],
  }) : this(status: ReadStatus.loading, participants: participants);

  const ParticipantsState.loaded(List<ParticipantReadModel> participants)
    : this(status: ReadStatus.loaded, participants: participants);

  const ParticipantsState.empty()
    : this(status: ReadStatus.empty, participants: const []);

  const ParticipantsState.error(
    String message, {
    List<ParticipantReadModel> participants = const [],
  }) : this(
         status: ReadStatus.error,
         participants: participants,
         message: message,
       );

  const ParticipantsState.corruptionRecovery(String message)
    : this(status: ReadStatus.corruptionRecovery, message: message);

  final ReadStatus status;
  final List<ParticipantReadModel> participants;
  final String? message;
}

class ParticipantsCubit extends Cubit<ParticipantsState> {
  ParticipantsCubit({required ParticipantsReader reader, required this.groupId})
    : _reader = reader,
      super(const ParticipantsState.loading());

  final ParticipantsReader _reader;
  final String groupId;

  Future<void> load({bool propagateFailure = false}) async {
    if (isClosed) return;
    emit(ParticipantsState.loading(participants: state.participants));
    try {
      final participants = await _reader.listParticipants(groupId);
      if (isClosed) return;
      emit(
        participants.isEmpty
            ? const ParticipantsState.empty()
            : ParticipantsState.loaded(participants),
      );
    } on Object catch (error, stackTrace) {
      if (isClosed) return;
      emit(
        isCorruptionFailure(error)
            ? ParticipantsState.corruptionRecovery(
                recoveryMessage('participants'),
              )
            : ParticipantsState.error(
                readFailureMessage(error, 'participants'),
                participants: state.participants,
              ),
      );
      if (propagateFailure) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> reload() => load();

  Future<void> reloadForRefresh() => load(propagateFailure: true);
}

typedef ParticipantsReadCubit = ParticipantsCubit;

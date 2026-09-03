import '../../domain/read_models/read_models.dart';

class ExpenseParticipantOption {
  const ExpenseParticipantOption({
    required this.id,
    required this.name,
    required this.archived,
  });

  final String id;
  final String name;
  final bool archived;
}

List<ExpenseParticipantOption> selectableExpenseParticipants({
  required Iterable<ParticipantReadModel> participants,
  ExpenseReadModel? existingExpense,
}) {
  final referencedIds = <String>{};
  final referencedArchived = <String, ExpenseParticipantOption>{};

  void remember(String id, String name, bool archived) {
    referencedIds.add(id);
    if (!archived) return;
    referencedArchived[id] ??= ExpenseParticipantOption(
      id: id,
      name: name,
      archived: true,
    );
  }

  for (final contributor in existingExpense?.contributors ?? const []) {
    remember(contributor.participantId, contributor.name, contributor.archived);
  }
  for (final beneficiary in existingExpense?.beneficiaries ?? const []) {
    remember(beneficiary.participantId, beneficiary.name, beneficiary.archived);
  }

  final result = <ExpenseParticipantOption>[];
  final includedIds = <String>{};
  for (final participant in participants) {
    if (participant.archived && !referencedIds.contains(participant.id)) {
      continue;
    }
    if (includedIds.add(participant.id)) {
      result.add(
        ExpenseParticipantOption(
          id: participant.id,
          name: participant.name,
          archived: participant.archived,
        ),
      );
    }
  }
  for (final option in referencedArchived.values) {
    if (includedIds.add(option.id)) result.add(option);
  }
  return List.unmodifiable(result);
}

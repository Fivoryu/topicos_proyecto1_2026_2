import '../data/auth/auth_transport.dart';
import '../data/repositories/balances_repository.dart';
import '../data/repositories/expenses_repository.dart';
import '../data/repositories/group_repository.dart';
import '../data/repositories/participants_repository.dart';
import '../data/repositories/settlement_repository.dart';
import '../data/refresh/refresh_coordinator.dart';
import '../data/websocket/data_changed_listener.dart';
import '../domain/read_models/read_models.dart';
import '../presentation/balances/balances_cubit.dart';
import '../presentation/expenses/expenses_cubit.dart';
import '../presentation/group/group_cubit.dart';
import '../presentation/participants/participants_cubit.dart';
import '../presentation/participants/participants_mutation_cubit.dart';
import '../presentation/settlement/settlement_cubit.dart';

/// The read dependencies created for one authenticated group session.
class DomainReaders {
  const DomainReaders({
    required this.group,
    required this.participants,
    required this.expenses,
    required this.balances,
    required this.settlement,
    this.participantsWriter,
  });

  factory DomainReaders.fromTransport(AuthTransport transport) {
    final participantsRepository = ParticipantsRepository.fromTransport(
      transport,
    );
    return DomainReaders(
      group: GroupRepository.fromTransport(transport),
      participants: participantsRepository,
      participantsWriter: participantsRepository,
      expenses: ExpensesRepository.fromTransport(transport),
      balances: BalancesRepository.fromTransport(transport),
      settlement: SettlementRepository.fromTransport(transport),
    );
  }

  factory DomainReaders.unavailable() {
    const reader = _UnavailableReaders.instance;
    return const DomainReaders(
      group: reader,
      participants: reader,
      expenses: reader,
      balances: reader,
      settlement: reader,
    );
  }

  final GroupReader group;
  final ParticipantsReader participants;
  final ParticipantsWriter? participantsWriter;
  final ExpensesReader expenses;
  final BalancesReader balances;
  final SettlementReader settlement;
}

/// Owns all protected read state for exactly one authenticated active group.
class DomainScope {
  DomainScope({
    required this.groupId,
    DomainReaders? readers,
    DataChangedListener? listener,
  }) : _listener = listener,
       groupCubit = GroupCubit(
         reader: (readers ?? DomainReaders.unavailable()).group,
         groupId: groupId,
       ),
       participantsCubit = ParticipantsCubit(
         reader: (readers ?? DomainReaders.unavailable()).participants,
         groupId: groupId,
       ),
       expensesCubit = ExpensesCubit(
         reader: (readers ?? DomainReaders.unavailable()).expenses,
         groupId: groupId,
       ),
       balancesCubit = BalancesCubit(
         reader: (readers ?? DomainReaders.unavailable()).balances,
         groupId: groupId,
       ),
       settlementCubit = SettlementCubit(
         reader: (readers ?? DomainReaders.unavailable()).settlement,
         groupId: groupId,
       ) {
    refreshCoordinator = RefreshCoordinator(
      reloaders: {
        RefreshTarget.group: groupCubit.reloadForRefresh,
        RefreshTarget.participants: participantsCubit.reloadForRefresh,
        RefreshTarget.expenses: expensesCubit.reloadForRefresh,
        RefreshTarget.balances: balancesCubit.reloadForRefresh,
        RefreshTarget.settlement: settlementCubit.reloadForRefresh,
      },
    );
    final writer = readers?.participantsWriter;
    participantsMutationCubit = writer == null
        ? null
        : ParticipantsMutationCubit(
            writer: writer,
            groupId: groupId,
            onMutationSuccess: () =>
                refreshCoordinator.refresh(RefreshImpact.participant),
            onPostMutationRefreshRetry: refreshCoordinator.retry,
          );
    listener?.bindOnDataChanged(
      () => refreshCoordinator.refresh(RefreshImpact.unknown),
    );
    listener?.start();
  }

  factory DomainScope.fromTransport(
    AuthTransport transport, {
    required String groupId,
    DataChangedListener? listener,
  }) => DomainScope(
    groupId: groupId,
    readers: DomainReaders.fromTransport(transport),
    listener: listener,
  );

  late final RefreshCoordinator refreshCoordinator;

  final String groupId;
  final GroupCubit groupCubit;
  final ParticipantsCubit participantsCubit;
  late final ParticipantsMutationCubit? participantsMutationCubit;
  final ExpensesCubit expensesCubit;
  final BalancesCubit balancesCubit;
  final SettlementCubit settlementCubit;
  final DataChangedListener? _listener;
  var _closed = false;

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _listener?.close();
    await participantsMutationCubit?.close();
    await refreshCoordinator.close();
    await Future.wait<void>([
      groupCubit.close(),
      participantsCubit.close(),
      expensesCubit.close(),
      balancesCubit.close(),
      settlementCubit.close(),
    ]);
  }
}

class _UnavailableReaders
    implements
        GroupReader,
        ParticipantsReader,
        ExpensesReader,
        BalancesReader,
        SettlementReader {
  const _UnavailableReaders._();
  static const instance = _UnavailableReaders._();

  Future<T> _fail<T>(String resource) async =>
      throw StateError('$resource reader is not configured.');

  @override
  Future<GroupReadModel> getGroup(String groupId) => _fail('group');

  @override
  Future<List<ParticipantReadModel>> listParticipants(String groupId) =>
      _fail('participants');

  @override
  Future<List<ExpenseReadModel>> listExpenses(String groupId) =>
      _fail('expenses');

  @override
  Future<BalancesReadModel> getBalances(String groupId) => _fail('balances');

  @override
  Future<SettlementReadModel> getSettlement(String groupId) =>
      _fail('settlement');
}

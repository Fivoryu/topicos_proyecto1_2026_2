import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/domain_scope.dart';
import '../balances/balances_screen.dart';
import '../expenses/expense_history_screen.dart';
import '../group/group_screen.dart';
import '../participants/participants_screen.dart';
import '../settlement/settlement_screen.dart';

const _largeWindowMinWidth = 1024.0;

/// Authenticated, one-group navigation for the server-backed read domain.
class DomainShell extends StatefulWidget {
  const DomainShell({
    required this.scope,
    required this.role,
    required this.onLogout,
    this.routeGroupId,
    this.routeRole,
    super.key,
  });

  final DomainScope scope;
  final String role;
  final Future<void> Function() onLogout;
  final String? routeGroupId;
  final String? routeRole;

  @override
  State<DomainShell> createState() => _DomainShellState();
}

class _DomainShellState extends State<DomainShell> {
  var _selectedIndex = 0;

  static const _labels = [
    'Group',
    'Participants',
    'Expenses',
    'Balances',
    'Settlement',
  ];
  static const _icons = [
    Icons.group_outlined,
    Icons.people_outline,
    Icons.receipt_long_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.compare_arrows_outlined,
  ];

  Widget _screen() => switch (_selectedIndex) {
    0 => GroupScreen(
      cubit: widget.scope.groupCubit,
      role: widget.role,
      mutationCubit: widget.scope.policyMutationCubit,
    ),
    1 => ParticipantsScreen(
      cubit: widget.scope.participantsCubit,
      mutationCubit: widget.scope.participantsMutationCubit,
    ),
    2 => ExpenseHistoryScreen(
      cubit: widget.scope.expensesCubit,
      participantsCubit: widget.scope.participantsCubit,
      mutationCubit: widget.scope.expenseMutationCubit,
    ),
    3 => BalancesScreen(cubit: widget.scope.balancesCubit),
    _ => SettlementScreen(cubit: widget.scope.settlementCubit),
  };

  List<NavigationDestination> _barDestinations() => [
    for (var index = 0; index < _labels.length; index++)
      NavigationDestination(
        icon: Icon(_icons[index]),
        selectedIcon: Icon(_icons[index]),
        label: _labels[index],
      ),
  ];

  List<NavigationRailDestination> _railDestinations() => [
    for (var index = 0; index < _labels.length; index++)
      NavigationRailDestination(
        icon: Icon(_icons[index]),
        selectedIcon: Icon(_icons[index]),
        label: Text(_labels[index]),
      ),
  ];

  void _select(int index) => setState(() => _selectedIndex = index);

  bool get _routeIsAuthorized =>
      (widget.routeGroupId == null ||
          widget.routeGroupId == widget.scope.groupId) &&
      (widget.routeRole == null || widget.routeRole == widget.role);

  @override
  Widget build(BuildContext context) {
    if (!_routeIsAuthorized) {
      return const _UnauthorizedRoute();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas Claras'),
        actions: [
          Center(child: Text('Role: ${widget.role}')),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => unawaited(widget.onLogout()),
            child: const Text('Log out'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = SafeArea(
            child: KeyedSubtree(
              key: ValueKey(_selectedIndex),
              child: _screen(),
            ),
          );
          if (constraints.maxWidth >= _largeWindowMinWidth) {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: _railDestinations(),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: content),
              SafeArea(
                top: false,
                child: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _select,
                  destinations: _barDestinations(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UnauthorizedRoute extends StatelessWidget {
  const _UnauthorizedRoute();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: const Text(
              'This route is not authorized for the active session.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );
}

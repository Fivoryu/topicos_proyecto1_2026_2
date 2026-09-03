import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/read_models/read_models.dart';
import 'participants_mutation_cubit.dart';

const _buttonStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll<Size>(Size.fromHeight(48)),
);
typedef _MutationStateBuilder =
    Widget Function(BuildContext, ParticipantsMutationState);

Widget _mutationView({
  required ParticipantsMutationCubit cubit,
  required _MutationStateBuilder builder,
}) => StreamBuilder<ParticipantsMutationState>(
  stream: cubit.stream,
  initialData: cubit.state,
  builder: (context, snapshot) =>
      builder(context, snapshot.data ?? cubit.state),
);

class ParticipantLifecycleActions extends StatelessWidget {
  const ParticipantLifecycleActions({
    required this.cubit,
    required this.participant,
    super.key,
  });

  final ParticipantsMutationCubit cubit;
  final ParticipantReadModel participant;

  void _run(Future<void> Function() operation) {
    if (cubit.state.isDisabled) return;
    unawaited(operation());
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (cubit.state.isDisabled) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Delete participant?'),
        content: Text('Delete ${participant.name}? This cannot be undone.'),
        actions: [
          _dialogButton(context, false, 'Cancel'),
          _dialogButton(context, true, 'Delete'),
        ],
      ),
    );
    if (confirmed != true || cubit.state.isDisabled) return;
    _run(() => cubit.delete(participant.id));
  }

  @override
  Widget build(BuildContext context) => _mutationView(
    cubit: cubit,
    builder: (context, state) {
      final archived = participant.archived;
      final label = archived ? 'Reactivate' : 'Archive';
      return Card(
        margin: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isLoading) const CircularProgressIndicator(),
              OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () => _run(
                        archived
                            ? () => cubit.reactivate(participant.id)
                            : () => cubit.archive(participant.id),
                      ),
                style: _buttonStyle,
                child: Text(label),
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              OutlinedButton(
                onPressed: state.isLoading
                    ? null
                    : () => _confirmDelete(context),
                style: _buttonStyle,
                child: const Text('Delete'),
              ),
              if (state.failure != null) ...[
                const SizedBox(height: DesignTokens.spacingSm),
                _failureMessage(context, state.failure!),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _failureMessage(BuildContext context, MutationFailure failure) =>
    Semantics(
      liveRegion: true,
      container: true,
      child: Text(
        failure.message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );

Widget _dialogButton(BuildContext context, bool result, String label) =>
    TextButton(
      onPressed: () => Navigator.of(context).pop(result),
      style: _buttonStyle,
      child: Text(label),
    );

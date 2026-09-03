import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/read_models/read_models.dart';
import '../read_status.dart';
import '../read_view_helpers.dart';
import 'participant_lifecycle_actions.dart';
import 'participants_cubit.dart';
import 'participants_mutation_cubit.dart';
import 'participants_mutation_widgets.dart';

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({
    required this.cubit,
    this.loadOnOpen = true,
    this.mutationCubit,
    super.key,
  });

  final ParticipantsCubit cubit;
  final bool loadOnOpen;
  final ParticipantsMutationCubit? mutationCubit;

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.loadOnOpen) unawaited(widget.cubit.load());
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<ParticipantsState>(
    stream: widget.cubit.stream,
    initialData: widget.cubit.state,
    builder: (context, snapshot) {
      final state = snapshot.data ?? widget.cubit.state;
      final mutationCubit = widget.mutationCubit;
      if (state.status == ReadStatus.empty) {
        return _buildEmpty(context);
      }
      if (state.status != ReadStatus.loaded) {
        if (mutationCubit?.canRetryPostMutationRefresh ?? false) {
          return _buildMutationRecovery(context, state, mutationCubit!);
        }
        return ReadStateMessage(
          status: state.status,
          resource: 'participants',
          message: state.message,
          onRetry: widget.cubit.reload,
        );
      }
      if (mutationCubit == null) {
        return _buildReadOnlyList(context, state);
      }
      return StreamBuilder<ParticipantsMutationState>(
        stream: mutationCubit.stream,
        initialData: mutationCubit.state,
        builder: (context, mutationSnapshot) => SingleChildScrollView(
          child: _buildEditableList(
            context,
            state,
            mutationCubit,
            (mutationSnapshot.data ?? mutationCubit.state).isDisabled,
          ),
        ),
      );
    },
  );

  Widget _buildMutationRecovery(
    BuildContext context,
    ParticipantsState state,
    ParticipantsMutationCubit mutationCubit,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReadStateMessage(
        status: state.status,
        resource: 'participants',
        message: state.message,
      ),
      ParticipantRefreshRetry(cubit: mutationCubit),
    ],
  );

  Widget _buildEmpty(BuildContext context) {
    final mutationCubit = widget.mutationCubit;
    if (mutationCubit == null) {
      return const ReadCard(
        child: Text('No participants yet. Add participants first.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParticipantMutationFeedback(cubit: mutationCubit),
        const ReadCard(
          child: Text('No participants yet. Add participants first.'),
        ),
        ParticipantRefreshRetry(cubit: mutationCubit),
        ParticipantNameForm(cubit: mutationCubit),
      ],
    );
  }

  Widget _buildReadOnlyList(BuildContext context, ParticipantsState state) =>
      ReadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Participants',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            ...state.participants.map(
              (participant) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.spacingXs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        participant.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (participant.archived)
                      Text(
                        'Archived',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildEditableList(
    BuildContext context,
    ParticipantsState state,
    ParticipantsMutationCubit mutationCubit,
    bool mutationDisabled,
  ) {
    final editingParticipant = _editingParticipant(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ParticipantMutationFeedback(cubit: mutationCubit),
        ParticipantRefreshRetry(cubit: mutationCubit),
        ParticipantNameForm(cubit: mutationCubit),
        if (editingParticipant != null)
          ParticipantNameForm(
            key: ValueKey(editingParticipant.id),
            cubit: mutationCubit,
            participant: editingParticipant,
            onCancel: _clearEditing,
          ),
        ReadCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Participants',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: DesignTokens.spacingSm),
              ...state.participants.map(
                (participant) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.spacingXs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          participant.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (participant.archived)
                        Text(
                          'Archived',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      TextButton(
                        onPressed: mutationDisabled
                            ? null
                            : () => _selectEditing(participant.id),
                        child: const Text('Rename'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ...state.participants.map(
          (participant) => ParticipantLifecycleActions(
            cubit: mutationCubit,
            participant: participant,
          ),
        ),
      ],
    );
  }

  ParticipantReadModel? _editingParticipant(ParticipantsState state) {
    final id = _editingParticipantId;
    if (id == null) return null;
    for (final participant in state.participants) {
      if (participant.id == id) return participant;
    }
    return null;
  }

  String? _editingParticipantId;

  void _selectEditing(String participantId) {
    if (!mounted) return;
    setState(() => _editingParticipantId = participantId);
  }

  void _clearEditing() {
    if (!mounted) return;
    setState(() => _editingParticipantId = null);
  }
}

typedef ParticipantsReadScreen = ParticipantsScreen;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../domain/read_models/read_models.dart';
import '../read_view_helpers.dart';
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

class ParticipantRefreshRetry extends StatelessWidget {
  const ParticipantRefreshRetry({required this.cubit, super.key});

  final ParticipantsMutationCubit cubit;

  @override
  Widget build(BuildContext context) => _mutationView(
    cubit: cubit,
    builder: (context, state) {
      if (!cubit.canRetryPostMutationRefresh) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
        child: OutlinedButton(
          onPressed: state.isLoading
              ? null
              : () => unawaited(cubit.retryPostMutationRefresh()),
          style: _buttonStyle,
          child: const Text('Retry refresh'),
        ),
      );
    },
  );
}

class ParticipantMutationFeedback extends StatelessWidget {
  const ParticipantMutationFeedback({required this.cubit, super.key});

  final ParticipantsMutationCubit cubit;

  @override
  Widget build(BuildContext context) => _mutationView(
    cubit: cubit,
    builder: (context, state) {
      final message = state.successMessage;
      if (message == null) return const SizedBox.shrink();
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Participant action completed: $message',
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
          ),
          child: Text(message),
        ),
      );
    },
  );
}

class ParticipantNameForm extends StatefulWidget {
  const ParticipantNameForm({
    required this.cubit,
    this.participant,
    this.onCancel,
    super.key,
  });

  final ParticipantsMutationCubit cubit;
  final ParticipantReadModel? participant;
  final VoidCallback? onCancel;

  @override
  State<ParticipantNameForm> createState() => _ParticipantNameFormState();
}

class _ParticipantNameFormState extends State<ParticipantNameForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.participant?.name ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.cubit.state.isDisabled) return;
    FocusScope.of(context).unfocus();
    final participant = widget.participant;
    unawaited(
      participant == null
          ? widget.cubit.add(_controller.text)
          : widget.cubit.rename(participant.id, _controller.text),
    );
  }

  @override
  Widget build(BuildContext context) => _mutationView(
    cubit: widget.cubit,
    builder: (context, state) {
      final rename = widget.participant != null;
      final failure = state.failure;
      return ReadCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              rename ? 'Rename participant' : 'Add participant',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: DesignTokens.spacingSm),
            TextField(
              controller: _controller,
              enabled: !state.isDisabled,
              textInputAction: TextInputAction.done,
              onSubmitted: state.isDisabled ? null : (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Participant name',
                errorText: failure?.fieldErrors['name'],
              ),
            ),
            if (failure != null) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              _failureMessage(context, failure),
            ],
            const SizedBox(height: DesignTokens.spacingMd),
            ElevatedButton(
              onPressed: state.isDisabled ? null : _submit,
              style: _buttonStyle,
              child: state.isLoading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(rename ? 'Save changes' : 'Add participant'),
            ),
            if (rename) ...[
              const SizedBox(height: DesignTokens.spacingSm),
              OutlinedButton(
                onPressed: state.isDisabled ? null : widget.onCancel,
                style: _buttonStyle,
                child: const Text('Cancel'),
              ),
            ],
          ],
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

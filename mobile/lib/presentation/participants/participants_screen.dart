import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../read_status.dart';
import '../read_view_helpers.dart';
import 'participants_cubit.dart';

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({
    required this.cubit,
    this.loadOnOpen = true,
    super.key,
  });

  final ParticipantsCubit cubit;
  final bool loadOnOpen;

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
      if (state.status == ReadStatus.empty) {
        return const ReadCard(
          child: Text('No participants yet. Add participants first.'),
        );
      }
      if (state.status != ReadStatus.loaded) {
        return ReadStateMessage(status: state.status, resource: 'participants');
      }
      return ReadCard(
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
    },
  );
}

typedef ParticipantsReadScreen = ParticipantsScreen;

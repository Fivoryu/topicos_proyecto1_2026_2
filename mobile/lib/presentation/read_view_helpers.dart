import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import 'read_status.dart';

class ReadCard extends StatelessWidget {
  const ReadCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.all(DesignTokens.spacingMd),
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: child,
    ),
  );
}

class ReadStateMessage extends StatelessWidget {
  const ReadStateMessage({
    required this.status,
    required this.resource,
    super.key,
  });

  final ReadStatus status;
  final String resource;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      ReadStatus.loading => 'Loading $resource…',
      ReadStatus.error => 'Unable to load $resource. Please try again.',
      ReadStatus.corruptionRecovery =>
        'Data recovery is required before $resource can be shown.',
      ReadStatus.empty => 'No $resource available.',
      ReadStatus.loaded => '',
    };
    return ReadCard(
      child: Semantics(
        liveRegion: true,
        child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

String policyLabel(SettlementPolicyValue policy) => policy.label;

enum SettlementPolicyValue { ownerOnly, anyMember }

extension SettlementPolicyValueLabel on SettlementPolicyValue {
  String get label => switch (this) {
    SettlementPolicyValue.ownerOnly => 'Owner only',
    SettlementPolicyValue.anyMember => 'Any member',
  };
}

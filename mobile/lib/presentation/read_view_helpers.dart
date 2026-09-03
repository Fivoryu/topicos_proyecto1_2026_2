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
    this.message,
    this.onRetry,
    super.key,
  });

  final ReadStatus status;
  final String resource;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final displayMessage =
        message ??
        switch (status) {
          ReadStatus.loading => 'Loading $resource…',
          ReadStatus.error => 'Unable to load $resource. Please try again.',
          ReadStatus.corruptionRecovery =>
            'Data recovery is required before $resource can be shown.',
          ReadStatus.empty => 'No $resource available.',
          ReadStatus.loaded => '',
        };
    final retryable =
        onRetry != null &&
        (status == ReadStatus.error || status == ReadStatus.corruptionRecovery);
    return ReadCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              displayMessage,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (retryable) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            OutlinedButton(onPressed: onRetry, child: Text('Retry $resource')),
          ],
        ],
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

import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';

enum SyncStatus { synced, pending, conflict }

class SyncStatusDot extends StatelessWidget {
  final SyncStatus status;

  const SyncStatusDot({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case SyncStatus.synced:
        color = ColorTokens.positive;
        break;
      case SyncStatus.pending:
        color = ColorTokens.neutralInfo;
        break;
      case SyncStatus.conflict:
        color = ColorTokens.negative;
        break;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

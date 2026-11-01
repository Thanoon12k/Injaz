import 'package:flutter/material.dart';

import '../store.dart';

/// Small cloud icon showing sync state. Tap → sync now.
class SyncBadge extends StatelessWidget {
  final Color color;
  final VoidCallback onOpenSettings;
  const SyncBadge({super.key, required this.color, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    final (IconData icon, String tip) = switch (s.syncState) {
      SyncState.localOnly => (Icons.cloud_off_outlined, 'Offline only — sign in to sync'),
      SyncState.syncing => (Icons.cloud_sync_outlined, 'Syncing…'),
      SyncState.synced => (Icons.cloud_done_outlined, 'Synced'),
      SyncState.offline => (Icons.cloud_queue, 'No connection — changes saved on phone'),
    };
    return IconButton(
      tooltip: tip,
      icon: Icon(icon, color: color),
      onPressed: () {
        if (!s.signedIn) {
          onOpenSettings();
          return;
        }
        s.syncNow();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(s.pendingChanges > 0 ? '$tip · ${s.pendingChanges} change(s) waiting' : tip),
            duration: const Duration(seconds: 2),
          ));
      },
    );
  }
}

// test/integration/offline_sync_flow_test.dart
// Integration scenario: offline -> record 3 actions -> SyncIndicator shows
// "3 actions en attente" -> network restored -> auto sync -> "Synced".
//
// Uses FakeSyncService (in-memory, no Dio, no Hive, no Connectivity) from
// test_app.dart. The SyncIndicator widget is the real widget — we inject
// the FakeSyncService via Provider so the indicator reacts to state changes.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/services/sync_service.dart';
import 'package:examboost_togo/widgets/sync_indicator.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration: offline sync flow', () {
    // Helper: pump a SyncIndicator wired to a FakeSyncService.
    Future<FakeSyncService> pumpIndicator(
      WidgetTester tester, {
      SyncStatus initialStatus = SyncStatus.idle,
    }) async {
      final sync = FakeSyncService(initialStatus: initialStatus);
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SyncService>.value(
            value: sync,
            child: const Scaffold(
              body: Center(child: SyncIndicator()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return sync;
    }

    // ─── Step 1: idle status shows cloud_outlined ────────────────
    testWidgets('Step 1 : idle -> cloud_outlined (no badge)', (tester) async {
      await pumpIndicator(tester, initialStatus: SyncStatus.idle);

      // The idle icon is cloud_outlined.
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
      // No badge text visible (pendingCount = 0).
      expect(find.text('0'), findsNothing);
    });

    // ─── Step 2: offline + 3 pending actions shows "3" badge ─────
    // Spec: Steps 1-2 (3 questions offline -> "3 actions en attente").
    testWidgets('Step 2 : offline + 3 actions -> badge "3" + tooltip en attente',
        (tester) async {
      final sync = await pumpIndicator(
        tester,
        initialStatus: SyncStatus.offline,
      );

      // Record 3 actions while offline.
      sync.recordAction();
      sync.recordAction();
      sync.recordAction();
      await tester.pumpAndSettle();

      // The offline icon is cloud_off (grey).
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // The badge "3" is visible.
      expect(find.text('3'), findsOneWidget);

      // The Tooltip on the indicator contains "3" and "en attente".
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('3'));
      expect(tooltip.message, contains('attente'));
      expect(tooltip.message, contains('Hors-ligne'));
    });

    // ─── Step 3: simulate network restored -> sync ───────────────
    // Spec: Steps 3-4 (retour réseau -> sync automatique).
    testWidgets('Step 3 : Retour réseau -> sync -> status success',
        (tester) async {
      final sync = await pumpIndicator(
        tester,
        initialStatus: SyncStatus.offline,
      );

      // Queue 3 actions.
      sync.recordAction();
      sync.recordAction();
      sync.recordAction();
      await tester.pumpAndSettle();
      expect(sync.pendingCount, 3);
      expect(find.text('3'), findsOneWidget);

      // Simulate network restored: FakeSyncService.comeBackOnline triggers
      // syncNow which drains the queue.
      await sync.comeBackOnline();
      await tester.pumpAndSettle();

      // Status is now success.
      expect(sync.status, SyncStatus.success);
      expect(sync.pendingCount, 0);
      expect(sync.syncedCount, 3);

      // The cloud_done icon (green) is displayed.
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      // No more badge.
      expect(find.text('3'), findsNothing);
    });

    // ─── Step 4: success tooltip reads "Synchronisation réussie" ─
    // Spec: Step 5 (SyncIndicator affiche "Synced").
    testWidgets('Step 4 : success -> tooltip "Synchronisation réussie"',
        (tester) async {
      final sync = await pumpIndicator(
        tester,
        initialStatus: SyncStatus.offline,
      );

      // Queue + sync.
      sync.recordAction();
      await tester.pumpAndSettle();
      await sync.comeBackOnline();
      await tester.pumpAndSettle();

      // The Tooltip message is "Synchronisation réussie".
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, contains('réussie'));
    });

    // ─── Step 5: syncing status shows cloud + spinner ────────────
    // Bonus: during the sync phase, the indicator shows a spinner.
    testWidgets('Step 5 : syncing -> cloud + CircularProgressIndicator', (tester) async {
      final sync = await pumpIndicator(
        tester,
        initialStatus: SyncStatus.offline,
      );

      // Queue 2 actions.
      sync.recordAction();
      sync.recordAction();
      await tester.pumpAndSettle();

      // Trigger syncNow but don't await it yet — pump just enough to
      // capture the syncing state.
      sync.syncNow(); // fire-and-forget
      await tester.pump();

      // The syncing icon is cloud (info color).
      expect(find.byIcon(Icons.cloud), findsOneWidget);
      // A CircularProgressIndicator is layered on top.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Drain the fake sync (10ms delay).
      await tester.pumpAndSettle();

      // Now success.
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    // ─── Step 6: error status shows cloud_off (red) ──────────────
    // Bonus: verify the error state visual.
    testWidgets('Step 6 : error -> cloud_off (rouge)', (tester) async {
      // We can't easily produce an error in FakeSyncService (it always
      // succeeds), but we can verify the SyncIndicator renders the error
      // icon when status is error. We use a direct status mutation via
      // a small FakeSyncService extension.
      final sync = FakeSyncService(initialStatus: SyncStatus.error);
      // FakeSyncService doesn't expose a status setter, but we can call
      // the public API. For this test, we just verify the icon when the
      // initial status is error.
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SyncService>.value(
            value: sync,
            child: const Scaffold(
              body: Center(child: SyncIndicator()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The error icon is cloud_off (red).
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });
  });
}

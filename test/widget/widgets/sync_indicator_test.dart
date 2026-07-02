// test/widget/widgets/sync_indicator_test.dart
// Tests for the SyncIndicator widget — petit indicateur de sync AppBar.
//
// The widget consumes SyncService via Consumer. We use FakeSyncService
// (extends SyncService with throwaway deps + overridden status/pending/
// lastError getters) so no real Dio/Connectivity/Hive is needed.
//
// We test:
//   - Status idle: cloud_outlined icon visible.
//   - Status syncing: CircularProgressIndicator visible.
//   - Status success: cloud_done icon visible.
//   - Status error: cloud_off icon visible + lastError in tooltip.
//   - Tap on indicator calls onTap callback.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:examboost_togo/models/sync_status.dart';
import 'package:examboost_togo/services/sync_service.dart';
import 'package:examboost_togo/widgets/sync_indicator.dart';

import '../../helpers/mock_services.dart';

void main() {
  group('SyncIndicator widget', () {
    Future<void> pumpIndicator(
      WidgetTester tester, {
      required FakeSyncService sync,
      VoidCallback? onTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SyncService>.value(
            value: sync,
            child: Scaffold(
              appBar: AppBar(
                actions: [
                  SyncIndicator(onTap: onTap),
                ],
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Status idle : icône cloud_outlined visible', (tester) async {
      final sync = FakeSyncService();
      sync.setStatus(SyncStatus.idle);
      await pumpIndicator(tester, sync: sync);

      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });

    testWidgets('Status syncing : CircularProgressIndicator visible',
        (tester) async {
      final sync = FakeSyncService();
      sync.setStatus(SyncStatus.syncing);
      await pumpIndicator(tester, sync: sync);

      expect(find.byIcon(Icons.cloud), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Status success : icône cloud_done visible', (tester) async {
      final sync = FakeSyncService();
      sync.setStatus(SyncStatus.success);
      await pumpIndicator(tester, sync: sync);

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('Status error : icône cloud_off + lastError dans le tooltip',
        (tester) async {
      final sync = FakeSyncService();
      sync.setStatus(SyncStatus.error);
      sync.setLastError('Connexion refusée');
      await pumpIndicator(tester, sync: sync);

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      // The tooltip is set on the widget; we verify via Tooltip message.
      expect(
        find.byWidgetPredicate((w) =>
            w is Tooltip &&
            (w.message.contains('Connexion refusée') ||
                w.message.contains('Erreur de sync'))),
        findsOneWidget,
      );
    });

    testWidgets('Tap : appelle le callback onTap', (tester) async {
      final sync = FakeSyncService();
      int tapCount = 0;
      await pumpIndicator(
        tester,
        sync: sync,
        onTap: () => tapCount++,
      );

      // Tap anywhere on the indicator (InkWell wraps the icon).
      await tester.tap(find.byIcon(Icons.cloud_outlined));
      await tester.pump();
      expect(tapCount, 1);
    });
  });
}

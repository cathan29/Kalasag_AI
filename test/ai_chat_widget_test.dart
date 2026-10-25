import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/ai/ai_chat_controller.dart';
import 'package:kalasag/ai/ai_chat_models.dart';
import 'package:kalasag/ai/ai_chat_service.dart';
import 'package:kalasag/ai/ai_chat_storage.dart';
import 'package:kalasag/ai/kalasag_ai_fab.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('floating button opens and closes the Kalasag AI sheet', (
    tester,
  ) async {
    final harness = await _Harness.create();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app());

    expect(find.byTooltip('Kalasag AI'), findsOneWidget);
    await tester.tap(find.byTooltip('Kalasag AI'));
    await tester.pumpAndSettle();
    expect(find.text('Kalasag AI Assistant'), findsOneWidget);
    expect(find.textContaining("Hi! I'm Kalasag AI"), findsOneWidget);

    await tester.tap(find.byTooltip('Close Kalasag AI'));
    await tester.pumpAndSettle();
    expect(find.text('Kalasag AI Assistant'), findsNothing);
  });

  testWidgets(
    'suggested question sends a real service request and renders response',
    (tester) async {
      final harness = await _Harness.create();
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.tap(find.byTooltip('Kalasag AI'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('What should I do during an earthquake?'));
      await tester.pumpAndSettle();

      expect(harness.service.calls, 1);
      expect(find.textContaining('Drop, cover, and hold on'), findsOneWidget);
    },
  );

  testWidgets('service failure shows retry and offline-guide actions', (
    tester,
  ) async {
    final harness = await _Harness.create(
      failure: const AiChatFailure(
        AiFailureKind.timeout,
        'Kalasag AI took too long to respond. Please try again.',
        retryable: true,
      ),
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app());
    await tester.tap(find.byTooltip('Kalasag AI'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      'How do I prepare for a typhoon?',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(find.textContaining('too long'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Open offline safety guide'), findsOneWidget);
  });
}

class _Harness {
  _Harness(this.controller, this.service, this.connectivity);

  static Future<_Harness> create({AiChatFailure? failure}) async {
    final service = _WidgetService()..failure = failure;
    final connectivity = _WidgetConnectivity();
    final controller = AiChatController(
      service: service,
      store: _WidgetStore(),
      connectivity: connectivity,
    );
    await controller.initialize();
    return _Harness(controller, service, connectivity);
  }

  final AiChatController controller;
  final _WidgetService service;
  final _WidgetConnectivity connectivity;

  Widget app() => ChangeNotifierProvider.value(
    value: controller,
    child: const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Kalasag home')),
        floatingActionButton: KalasagAiFab(),
      ),
    ),
  );

  void dispose() {
    controller.dispose();
    connectivity.dispose();
  }
}

class _WidgetService implements AiChatService {
  int calls = 0;
  AiChatFailure? failure;

  @override
  bool get isConfigured => true;

  @override
  Future<AiServiceReply> send({
    required String message,
    required String locale,
    String? previousInteractionId,
  }) async {
    calls++;
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
    return const AiServiceReply(
      text: '**Drop, cover, and hold on.** Follow official local instructions.',
      interactionId: 'signed-context',
    );
  }
}

class _WidgetStore implements AiChatStore {
  @override
  Future<StoredAiConversation> read() async =>
      const StoredAiConversation(messages: []);

  @override
  Future<void> write(
    List<AiChatMessage> messages,
    String? interactionId,
  ) async {}

  @override
  Future<void> clear() async {}
}

class _WidgetConnectivity implements AiConnectivity {
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get changes => _controller.stream;

  @override
  Future<bool> isOnline() async => true;

  void dispose() => _controller.close();
}

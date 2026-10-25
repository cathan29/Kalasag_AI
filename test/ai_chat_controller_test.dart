import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/ai/ai_chat_controller.dart';
import 'package:kalasag/ai/ai_chat_models.dart';
import 'package:kalasag/ai/ai_chat_service.dart';
import 'package:kalasag/ai/ai_chat_storage.dart';

void main() {
  late _FakeService service;
  late _MemoryStore store;
  late _FakeConnectivity connectivity;
  late DateTime now;
  late AiChatController controller;

  setUp(() {
    service = _FakeService();
    store = _MemoryStore();
    connectivity = _FakeConnectivity(true);
    now = DateTime(2026, 10, 25, 20);
    controller = AiChatController(
      service: service,
      store: store,
      connectivity: connectivity,
      clock: () => now,
    );
  });

  tearDown(() {
    controller.dispose();
    connectivity.dispose();
  });

  test('validates empty and oversized messages', () {
    expect(controller.validate('  '), 'Enter a question first.');
    expect(
      controller.validate('x' * (AiChatController.maxInputLength + 1)),
      contains('${AiChatController.maxInputLength}'),
    );
  });

  test(
    'sends multi-turn messages and preserves signed context token',
    () async {
      await controller.initialize();
      expect(await controller.send('Earthquake safety?'), isTrue);
      now = now.add(const Duration(seconds: 3));
      expect(await controller.send('What should I do next?'), isTrue);

      expect(service.previousIds, [null, 'context-1']);
      expect(controller.messages, hasLength(4));
      expect(store.interactionId, 'context-2');
    },
  );

  test(
    'offline state prevents a network request and keeps fallback available',
    () async {
      connectivity.online = false;
      await controller.initialize();

      expect(await controller.send('Flood guidance'), isFalse);
      expect(service.calls, 0);
      expect(controller.failure?.kind, AiFailureKind.offline);
      expect(controller.canRetry, isTrue);
    },
  );

  test(
    'retry reuses the failed prompt without duplicating the user message',
    () async {
      service.failure = const AiChatFailure(
        AiFailureKind.timeout,
        'Timed out',
        retryable: true,
      );
      await controller.initialize();
      expect(await controller.send('Typhoon guidance'), isFalse);
      expect(controller.messages, hasLength(1));

      service.failure = null;
      expect(await controller.retry(), isTrue);
      expect(controller.messages, hasLength(2));
      expect(controller.messages.first.role, AiMessageRole.user);
      expect(controller.messages.last.role, AiMessageRole.assistant);
    },
  );

  test('restores and clears locally persisted conversation', () async {
    store.messages = [
      AiChatMessage(
        id: 'saved',
        role: AiMessageRole.user,
        text: 'Saved question',
        createdAt: now,
      ),
    ];
    store.interactionId = 'saved-context';
    await controller.initialize();

    expect(controller.messages.single.text, 'Saved question');
    await controller.clearHistory();
    expect(controller.messages, isEmpty);
    expect(store.cleared, isTrue);
  });
}

class _FakeService implements AiChatService {
  int calls = 0;
  AiChatFailure? failure;
  final List<String?> previousIds = [];

  @override
  bool get isConfigured => true;

  @override
  Future<AiServiceReply> send({
    required String message,
    required String locale,
    String? previousInteractionId,
  }) async {
    calls++;
    previousIds.add(previousInteractionId);
    final currentFailure = failure;
    if (currentFailure != null) throw currentFailure;
    return AiServiceReply(
      text: 'Safe response $calls',
      interactionId: 'context-$calls',
    );
  }
}

class _MemoryStore implements AiChatStore {
  List<AiChatMessage> messages = [];
  String? interactionId;
  bool cleared = false;

  @override
  Future<StoredAiConversation> read() async =>
      StoredAiConversation(messages: messages, interactionId: interactionId);

  @override
  Future<void> write(
    List<AiChatMessage> messages,
    String? interactionId,
  ) async {
    this.messages = List.of(messages);
    this.interactionId = interactionId;
  }

  @override
  Future<void> clear() async {
    messages = [];
    interactionId = null;
    cleared = true;
  }
}

class _FakeConnectivity implements AiConnectivity {
  _FakeConnectivity(this.online);

  bool online;
  final _changes = StreamController<bool>.broadcast();

  @override
  Stream<bool> get changes => _changes.stream;

  @override
  Future<bool> isOnline() async => online;

  void dispose() => _changes.close();
}

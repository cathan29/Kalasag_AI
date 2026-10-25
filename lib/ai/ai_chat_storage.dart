import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'ai_chat_models.dart';

class StoredAiConversation {
  const StoredAiConversation({required this.messages, this.interactionId});

  final List<AiChatMessage> messages;
  final String? interactionId;
}

abstract interface class AiChatStore {
  Future<StoredAiConversation> read();
  Future<void> write(List<AiChatMessage> messages, String? interactionId);
  Future<void> clear();
}

class HiveAiChatStore implements AiChatStore {
  static const _boxName = 'kalasag_local_data';
  static const _key = 'ai_chat_history_v1';

  Future<Box<dynamic>> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      return Hive.openBox<dynamic>(_boxName);
    }
    return Hive.box<dynamic>(_boxName);
  }

  @override
  Future<StoredAiConversation> read() async {
    final raw = (await _box()).get(_key);
    if (raw is! String || raw.isEmpty) {
      return const StoredAiConversation(messages: []);
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return const StoredAiConversation(messages: []);
    }
    final entries = decoded['messages'];
    final messages = entries is List
        ? entries
              .whereType<Map>()
              .map(
                (item) => AiChatMessage.fromJson(item.cast<String, dynamic>()),
              )
              .where((message) => message.text.isNotEmpty)
              .toList()
        : <AiChatMessage>[];
    return StoredAiConversation(
      messages: messages,
      interactionId: decoded['interactionId'] as String?,
    );
  }

  @override
  Future<void> write(
    List<AiChatMessage> messages,
    String? interactionId,
  ) async {
    final retained = messages.length > 40
        ? messages.sublist(messages.length - 40)
        : messages;
    final box = await _box();
    await box.put(
      _key,
      jsonEncode({
        'messages': retained.map((message) => message.toJson()).toList(),
        'interactionId': interactionId,
      }),
    );
    await box.flush();
  }

  @override
  Future<void> clear() async {
    final box = await _box();
    await box.delete(_key);
    await box.flush();
  }
}

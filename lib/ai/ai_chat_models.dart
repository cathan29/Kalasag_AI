enum AiMessageRole { user, assistant }

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final AiMessageRole role;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
    id: '${json['id']}',
    role: json['role'] == AiMessageRole.user.name
        ? AiMessageRole.user
        : AiMessageRole.assistant,
    text: '${json['text'] ?? ''}',
    createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
  );
}

class AiServiceReply {
  const AiServiceReply({required this.text, required this.interactionId});

  final String text;
  final String interactionId;
}

enum AiFailureKind {
  notConfigured,
  offline,
  unauthorized,
  blocked,
  rateLimited,
  quotaExceeded,
  timeout,
  invalidResponse,
  server,
}

class AiChatFailure implements Exception {
  const AiChatFailure(this.kind, this.message, {this.retryable = false});

  final AiFailureKind kind;
  final String message;
  final bool retryable;

  @override
  String toString() => message;
}

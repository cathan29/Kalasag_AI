import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_chat_models.dart';

abstract interface class AiAccessTokenProvider {
  Future<String?> getToken();
}

class NoAiAccessTokenProvider implements AiAccessTokenProvider {
  const NoAiAccessTokenProvider();

  @override
  Future<String?> getToken() async => null;
}

class AiServiceConfig {
  const AiServiceConfig({
    required this.baseUrl,
    this.allowUnauthenticatedDevelopment = false,
  });

  factory AiServiceConfig.fromEnvironment() => const AiServiceConfig(
    baseUrl: String.fromEnvironment('KALASAG_AI_BASE_URL'),
    allowUnauthenticatedDevelopment: bool.fromEnvironment(
      'KALASAG_AI_ALLOW_UNAUTHENTICATED_DEV',
    ),
  );

  final String baseUrl;
  final bool allowUnauthenticatedDevelopment;
}

abstract interface class AiChatService {
  bool get isConfigured;

  Future<AiServiceReply> send({
    required String message,
    required String locale,
    String? previousInteractionId,
  });
}

class GeminiProxyChatService implements AiChatService {
  GeminiProxyChatService({
    required this.config,
    AiAccessTokenProvider tokenProvider = const NoAiAccessTokenProvider(),
    http.Client? client,
    this.timeout = const Duration(seconds: 25),
  }) : _tokenProvider = tokenProvider,
       _client = client ?? http.Client();

  final AiServiceConfig config;
  final AiAccessTokenProvider _tokenProvider;
  final http.Client _client;
  final Duration timeout;

  Uri? get _baseUri => Uri.tryParse(config.baseUrl.trim());

  @override
  bool get isConfigured {
    final uri = _baseUri;
    if (uri == null || !uri.hasAuthority) return false;
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' &&
        (uri.host == '127.0.0.1' || uri.host == 'localhost');
  }

  @override
  Future<AiServiceReply> send({
    required String message,
    required String locale,
    String? previousInteractionId,
  }) async {
    if (!isConfigured) {
      throw const AiChatFailure(
        AiFailureKind.notConfigured,
        'Kalasag AI still needs its secure server address.',
      );
    }

    final token = await _tokenProvider.getToken();
    if ((token == null || token.isEmpty) &&
        !config.allowUnauthenticatedDevelopment) {
      throw const AiChatFailure(
        AiFailureKind.unauthorized,
        'Secure AI access requires a real signed-in account.',
      );
    }

    final base = _baseUri!;
    final normalized = base.path.endsWith('/')
        ? base
        : base.replace(path: '${base.path}/');
    final uri = normalized.resolve('v1/chat');
    final headers = <String, String>{
      'content-type': 'application/json',
      if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'message': message,
              'locale': locale,
              'previousInteractionId': ?previousInteractionId,
            }),
          )
          .timeout(timeout);
      final body = _decodeBody(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final text = body['text'];
        final interactionId = body['interactionId'];
        if (text is! String ||
            text.trim().isEmpty ||
            interactionId is! String) {
          throw const AiChatFailure(
            AiFailureKind.invalidResponse,
            'The AI service returned an incomplete response.',
            retryable: true,
          );
        }
        return AiServiceReply(text: text.trim(), interactionId: interactionId);
      }
      throw _mapHttpError(response.statusCode, body);
    } on TimeoutException {
      throw const AiChatFailure(
        AiFailureKind.timeout,
        'Kalasag AI took too long to respond. Please try again.',
        retryable: true,
      );
    } on AiChatFailure {
      rethrow;
    } on http.ClientException {
      throw const AiChatFailure(
        AiFailureKind.offline,
        'The secure AI service could not be reached. Check your connection.',
        retryable: true,
      );
    } catch (_) {
      throw const AiChatFailure(
        AiFailureKind.server,
        'Kalasag AI is temporarily unavailable.',
        retryable: true,
      );
    }
  }

  Map<String, dynamic> _decodeBody(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  AiChatFailure _mapHttpError(int status, Map<String, dynamic> body) {
    final error = body['error'];
    final details = error is Map<String, dynamic> ? error : body;
    final code = '${details['code'] ?? ''}'.toLowerCase();
    if (status == 401 || status == 403) {
      return const AiChatFailure(
        AiFailureKind.unauthorized,
        'Your secure AI session is unavailable. Please sign in again.',
      );
    }
    if (status == 429 && code.contains('quota')) {
      return const AiChatFailure(
        AiFailureKind.quotaExceeded,
        'The Gemini usage limit has been reached. Please try again later.',
      );
    }
    if (status == 429) {
      return const AiChatFailure(
        AiFailureKind.rateLimited,
        'Too many requests were sent. Wait a moment and retry.',
        retryable: true,
      );
    }
    if (code.contains('safety') || code.contains('blocked')) {
      return const AiChatFailure(
        AiFailureKind.blocked,
        'That request could not be answered safely. Try rephrasing it.',
      );
    }
    return AiChatFailure(
      AiFailureKind.server,
      status >= 500
          ? 'The AI service is temporarily unavailable.'
          : 'The AI request could not be completed.',
      retryable: status >= 500,
    );
  }
}

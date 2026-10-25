import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kalasag/ai/ai_chat_models.dart';
import 'package:kalasag/ai/ai_chat_service.dart';

void main() {
  test('parses proxy response without sending a Gemini API key', () async {
    late http.Request captured;
    final service = GeminiProxyChatService(
      config: const AiServiceConfig(
        baseUrl: 'https://ai.kalasag.example',
        allowUnauthenticatedDevelopment: true,
      ),
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'text': 'Stay calm and follow official instructions.',
            'interactionId': 'signed-context',
          }),
          200,
        );
      }),
    );

    final reply = await service.send(
      message: 'Earthquake guidance',
      locale: 'en-PH',
    );

    expect(reply.interactionId, 'signed-context');
    expect(captured.url.path, '/v1/chat');
    expect(captured.headers.keys, isNot(contains('x-goog-api-key')));
    expect(captured.body, isNot(contains('GEMINI_API_KEY')));
  });

  test('maps quota responses to a non-retryable quota failure', () async {
    final service = GeminiProxyChatService(
      config: const AiServiceConfig(
        baseUrl: 'https://ai.kalasag.example',
        allowUnauthenticatedDevelopment: true,
      ),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'quota_exceeded'},
          }),
          429,
        ),
      ),
    );

    expect(
      () => service.send(message: 'Help', locale: 'en-PH'),
      throwsA(
        isA<AiChatFailure>().having(
          (failure) => failure.kind,
          'kind',
          AiFailureKind.quotaExceeded,
        ),
      ),
    );
  });

  test('fails closed when no production identity token is available', () async {
    final service = GeminiProxyChatService(
      config: const AiServiceConfig(baseUrl: 'https://ai.kalasag.example'),
      client: MockClient((_) async => http.Response('{}', 500)),
    );

    expect(
      () => service.send(message: 'Help', locale: 'en-PH'),
      throwsA(
        isA<AiChatFailure>().having(
          (failure) => failure.kind,
          'kind',
          AiFailureKind.unauthorized,
        ),
      ),
    );
  });
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'ai_chat_models.dart';
import 'ai_chat_service.dart';
import 'ai_chat_storage.dart';

abstract interface class AiConnectivity {
  Future<bool> isOnline();
  Stream<bool> get changes;
}

class PluginAiConnectivity implements AiConnectivity {
  PluginAiConnectivity({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  bool _online(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _online(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get changes =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}

class AiChatController extends ChangeNotifier {
  AiChatController({
    required AiChatService service,
    required AiChatStore store,
    required AiConnectivity connectivity,
    DateTime Function()? clock,
  }) : _service = service,
       _store = store,
       _connectivity = connectivity,
       _clock = clock ?? DateTime.now;

  static const maxInputLength = 1200;

  final AiChatService _service;
  final AiChatStore _store;
  final AiConnectivity _connectivity;
  final DateTime Function() _clock;
  final List<AiChatMessage> _messages = [];

  StreamSubscription<bool>? _connectivitySubscription;
  String? _interactionId;
  AiChatFailure? _failure;
  String? _lastFailedPrompt;
  bool _online = true;
  bool _loading = false;
  bool _initialized = false;
  int _requestGeneration = 0;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  AiChatFailure? get failure => _failure;
  bool get isOnline => _online;
  bool get isLoading => _loading;
  bool get isConfigured => _service.isConfigured;
  bool get isInitialized => _initialized;
  bool get canRetry => _failure?.retryable == true && _lastFailedPrompt != null;

  String get statusLabel {
    if (!_online) return 'Offline';
    if (!_service.isConfigured) return 'Setup required';
    if (_loading) return 'Thinking…';
    return 'Secure connection ready';
  }

  Future<void> initialize() async {
    try {
      final stored = await _store.read();
      _messages
        ..clear()
        ..addAll(stored.messages.take(40));
      _interactionId = stored.interactionId;
    } catch (_) {
      _messages.clear();
      _interactionId = null;
    }
    try {
      _online = await _connectivity.isOnline();
      _connectivitySubscription = _connectivity.changes.listen((online) {
        if (_online == online) return;
        _online = online;
        notifyListeners();
      });
    } catch (_) {
      _online = true;
    }
    _initialized = true;
    notifyListeners();
  }

  String? validate(String raw) {
    final message = raw.trim();
    if (message.isEmpty) return 'Enter a question first.';
    if (message.length > maxInputLength) {
      return 'Keep your message under $maxInputLength characters.';
    }
    return null;
  }

  Future<bool> send(String raw) async {
    final prompt = raw.trim();
    final validation = validate(prompt);
    if (validation != null) {
      _failure = AiChatFailure(AiFailureKind.invalidResponse, validation);
      notifyListeners();
      return false;
    }
    if (_loading) return false;
    if (!_service.isConfigured) {
      _failure = const AiChatFailure(
        AiFailureKind.notConfigured,
        'Kalasag AI needs its secure backend configuration.',
      );
      notifyListeners();
      return false;
    }
    if (!_online) {
      _failure = const AiChatFailure(
        AiFailureKind.offline,
        'Gemini requires internet. Your offline safety guide is still available.',
        retryable: true,
      );
      _lastFailedPrompt = prompt;
      notifyListeners();
      return false;
    }

    final last = _messages.isEmpty ? null : _messages.last;
    if (last?.role == AiMessageRole.user &&
        last?.text == prompt &&
        _clock().difference(last!.createdAt).inSeconds < 2) {
      return false;
    }
    _messages.add(
      AiChatMessage(
        id: 'user-${_clock().microsecondsSinceEpoch}',
        role: AiMessageRole.user,
        text: prompt,
        createdAt: _clock(),
      ),
    );
    await _persist();
    return _request(prompt);
  }

  Future<bool> retry() async {
    final prompt = _lastFailedPrompt;
    if (prompt == null || _loading || !_online) return false;
    return _request(prompt);
  }

  Future<bool> _request(String prompt) async {
    _loading = true;
    _failure = null;
    _lastFailedPrompt = null;
    final generation = ++_requestGeneration;
    notifyListeners();
    try {
      final reply = await _service.send(
        message: prompt,
        locale: 'en-PH',
        previousInteractionId: _interactionId,
      );
      if (generation != _requestGeneration) return false;
      _interactionId = reply.interactionId;
      _messages.add(
        AiChatMessage(
          id: 'assistant-${_clock().microsecondsSinceEpoch}',
          role: AiMessageRole.assistant,
          text: reply.text,
          createdAt: _clock(),
        ),
      );
      await _persist();
      return true;
    } on AiChatFailure catch (failure) {
      if (generation != _requestGeneration) return false;
      _failure = failure;
      _lastFailedPrompt = prompt;
      return false;
    } finally {
      if (generation == _requestGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void cancelCurrent() {
    if (!_loading) return;
    _requestGeneration++;
    _loading = false;
    _failure = const AiChatFailure(
      AiFailureKind.server,
      'Response cancelled.',
      retryable: true,
    );
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _requestGeneration++;
    _messages.clear();
    _interactionId = null;
    _failure = null;
    _lastFailedPrompt = null;
    _loading = false;
    await _store.clear();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      await _store.write(_messages, _interactionId);
    } catch (_) {
      // Chat remains available in memory if local persistence is unavailable.
    }
  }

  @override
  void dispose() {
    _requestGeneration++;
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../offline_safety_assistant.dart';
import 'ai_chat_controller.dart';
import 'ai_chat_models.dart';

Future<void> showKalasagAiChat(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      constraints: const BoxConstraints(maxWidth: 720),
      builder: (_) =>
          const FractionallySizedBox(heightFactor: .92, child: _AiChatPanel()),
    );

class _AiChatPanel extends StatefulWidget {
  const _AiChatPanel();

  @override
  State<_AiChatPanel> createState() => _AiChatPanelState();
}

class _AiChatPanelState extends State<_AiChatPanel> {
  static const _suggestions = [
    'What should I do during an earthquake?',
    'How do I prepare for a typhoon?',
    'What should I do during flooding?',
    'What belongs in an emergency kit?',
  ];

  final _input = TextEditingController();
  final _scroll = ScrollController();
  AiChatController? _chat;
  int _lastMessageCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AiChatController>();
    if (identical(next, _chat)) return;
    _chat?.removeListener(_onChatChanged);
    _chat = next..addListener(_onChatChanged);
    _lastMessageCount = next.messages.length;
  }

  void _onChatChanged() {
    final count = _chat?.messages.length ?? 0;
    if (count == _lastMessageCount && !(_chat?.isLoading ?? false)) return;
    _lastMessageCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _chat?.removeListener(_onChatChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? suggestion]) async {
    final value = suggestion ?? _input.text;
    final accepted = await context.read<AiChatController>().send(value);
    if (accepted && suggestion == null) _input.clear();
  }

  Future<void> _confirmClear() async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear AI conversation?'),
        content: const Text(
          'This permanently removes the locally stored chat history from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (clear == true && mounted) {
      await context.read<AiChatController>().clearHistory();
    }
  }

  void _openOfflineGuide() {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OfflineSafetyAssistantScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _ChatHeader(onClear: _confirmClear),
            Expanded(
              child: Consumer<AiChatController>(
                builder: (context, chat, _) => ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  children: [
                    if (chat.messages.isEmpty) ...[
                      const _WelcomeCard(),
                      const SizedBox(height: 12),
                      Text(
                        'Suggested questions',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      ..._suggestions.map(
                        (question) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: OutlinedButton.icon(
                            onPressed: chat.isLoading
                                ? null
                                : () => _send(question),
                            icon: const Icon(Icons.arrow_outward, size: 18),
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(question),
                            ),
                          ),
                        ),
                      ),
                    ],
                    ...chat.messages.map(
                      (message) => _MessageBubble(message: message),
                    ),
                    if (chat.isLoading) const _TypingIndicator(),
                    if (chat.failure != null)
                      _ErrorCard(
                        failure: chat.failure!,
                        canRetry: chat.canRetry,
                        onRetry: chat.retry,
                        onOpenOffline: _openOfflineGuide,
                      ),
                  ],
                ),
              ),
            ),
            _ChatComposer(
              controller: _input,
              onSend: _send,
              onCancel: () => context.read<AiChatController>().cancelCurrent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Consumer<AiChatController>(
    builder: (context, chat, _) {
      final statusColor = !chat.isOnline
          ? Theme.of(context).colorScheme.error
          : chat.isConfigured
          ? Colors.green
          : Colors.orange;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kalasag AI Assistant',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              chat.statusLabel,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (chat.messages.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear conversation',
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_outline),
                  ),
                IconButton(
                  tooltip: 'Close Kalasag AI',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi! I'm Kalasag AI, your disaster preparedness assistant. How can I help you stay safe today?",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Support tool only—not an official emergency response service. '
            'For immediate danger, contact verified responders and follow local authorities.',
          ),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == AiMessageRole.user;
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
        decoration: BoxDecoration(
          color: user ? colors.primaryContainer : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user)
              SelectableText(message.text)
            else
              MarkdownBody(
                data: message.text,
                selectable: true,
                softLineBreak: true,
              ),
            const SizedBox(height: 5),
            Text(
              DateFormat.jm().format(message.createdAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Kalasag AI is preparing a response…'),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.failure,
    required this.canRetry,
    required this.onRetry,
    required this.onOpenOffline,
  });

  final AiChatFailure failure;
  final bool canRetry;
  final Future<bool> Function() onRetry;
  final VoidCallback onOpenOffline;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(failure.message),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (canRetry)
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              TextButton.icon(
                onPressed: onOpenOffline,
                icon: const Icon(Icons.offline_bolt_outlined),
                label: const Text('Open offline safety guide'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.onSend,
    required this.onCancel,
  });

  final TextEditingController controller;
  final Future<void> Function([String? suggestion]) onSend;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Consumer<AiChatController>(
    builder: (context, chat, _) => DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !chat.isLoading,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: AiChatController.maxInputLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Ask about disaster preparedness',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (chat.isLoading)
                IconButton.filledTonal(
                  tooltip: 'Cancel response',
                  onPressed: onCancel,
                  icon: const Icon(Icons.stop),
                )
              else
                IconButton.filled(
                  tooltip: 'Send message',
                  onPressed: () => onSend(),
                  icon: const Icon(Icons.send),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

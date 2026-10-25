import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ai_chat_controller.dart';
import 'ai_chat_sheet.dart';

class KalasagAiFab extends StatelessWidget {
  const KalasagAiFab({super.key});

  @override
  Widget build(BuildContext context) => Consumer<AiChatController>(
    builder: (context, chat, _) {
      final statusColor = !chat.isOnline
          ? Theme.of(context).colorScheme.error
          : chat.isConfigured
          ? Colors.green
          : Colors.orange;
      return Semantics(
        button: true,
        label: 'Open Kalasag AI Assistant',
        child: FloatingActionButton(
          heroTag: 'kalasag-ai-fab',
          tooltip: 'Kalasag AI',
          onPressed: () => showKalasagAiChat(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.auto_awesome),
              Positioned(
                right: -7,
                top: -7,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

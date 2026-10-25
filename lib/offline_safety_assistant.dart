import 'package:flutter/material.dart';

class SafetyReply {
  const SafetyReply({
    required this.title,
    required this.steps,
    this.urgent = false,
  });

  final String title;
  final List<String> steps;
  final bool urgent;
}

class OfflineSafetyGuide {
  const OfflineSafetyGuide._();

  static SafetyReply respond(String query) {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) {
      return const SafetyReply(
        title: 'Tell me what is happening',
        steps: [
          'Try earthquake, flood, typhoon, fire, evacuation, or first aid.',
        ],
      );
    }

    if (_containsAny(text, const [
      'unconscious',
      'not breathing',
      "can't breathe",
      'cannot breathe',
      'chest pain',
      'severe bleeding',
      'trapped',
      'immediate danger',
    ])) {
      return const SafetyReply(
        title: 'Get emergency help now',
        urgent: true,
        steps: [
          'Move away from immediate danger only if it is safe to do so.',
          'Use the SOS tab or call your local emergency service now.',
          'Follow dispatcher instructions. Do not rely on this guide for diagnosis.',
        ],
      );
    }

    if (_containsAny(text, const ['earthquake', 'quake', 'shaking'])) {
      return const SafetyReply(
        title: 'During an earthquake',
        steps: [
          'Drop to your hands and knees, cover your head and neck, and hold on.',
          'Stay away from windows and do not use elevators.',
          'After shaking stops, check for hazards and follow official evacuation advice.',
        ],
      );
    }
    if (_containsAny(text, const ['flood', 'flash flood', 'rising water'])) {
      return const SafetyReply(
        title: 'During flooding',
        steps: [
          'Move to higher ground early and take your go-bag.',
          'Do not walk, swim, or drive through moving floodwater.',
          'Switch off electricity only if authorities say it is safe.',
        ],
      );
    }
    if (_containsAny(text, const ['typhoon', 'storm', 'strong wind'])) {
      return const SafetyReply(
        title: 'During a typhoon',
        steps: [
          'Stay indoors and away from windows and unsecured objects.',
          'Charge essential devices and keep water, food, medicine, and a radio ready.',
          'Monitor official local advisories and evacuate early when instructed.',
        ],
      );
    }
    if (_containsAny(text, const ['fire', 'smoke', 'burning'])) {
      return const SafetyReply(
        title: 'If there is a fire',
        steps: [
          'Leave immediately using the safest exit; crawl low under smoke.',
          'Do not use elevators and do not return for belongings.',
          'Once outside, stay out and contact emergency services.',
        ],
      );
    }
    if (_containsAny(text, const ['bleeding', 'wound', 'first aid'])) {
      return const SafetyReply(
        title: 'Basic bleeding first aid',
        steps: [
          'Apply firm, direct pressure with clean cloth or gauze.',
          'Keep pressure in place and add more material if blood soaks through.',
          'Get medical help for deep wounds, uncontrolled bleeding, or signs of shock.',
        ],
      );
    }
    if (_containsAny(text, const ['evacuate', 'evacuation', 'leave home'])) {
      return const SafetyReply(
        title: 'Evacuation basics',
        steps: [
          'Follow official routes and leave early with your go-bag and medicines.',
          'Tell a trusted contact where you are going and assist dependents if safe.',
          'Do not return until local authorities say the area is safe.',
        ],
      );
    }

    return const SafetyReply(
      title: 'Offline guide limitation',
      steps: [
        'I could not match that situation to a bundled guide.',
        'Check the Emergency and Ready tabs for hotlines, first aid, and evacuation steps.',
        'For immediate danger, contact local emergency services.',
      ],
    );
  }

  static bool _containsAny(String text, List<String> terms) =>
      terms.any(text.contains);
}

class OfflineSafetyAssistantScreen extends StatefulWidget {
  const OfflineSafetyAssistantScreen({super.key});

  @override
  State<OfflineSafetyAssistantScreen> createState() =>
      _OfflineSafetyAssistantScreenState();
}

class _OfflineSafetyAssistantScreenState
    extends State<OfflineSafetyAssistantScreen> {
  final _controller = TextEditingController();
  final _messages = <({String query, SafetyReply reply})>[];

  static const _prompts = ['Earthquake', 'Flood', 'Typhoon', 'Fire'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send([String? prompt]) {
    final query = (prompt ?? _controller.text).trim();
    if (query.isEmpty) return;
    setState(
      () => _messages.add((
        query: query,
        reply: OfflineSafetyGuide.respond(query),
      )),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Offline safety guide')),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.all(14),
            child: const Text(
              'Bundled guidance • Works offline • Not live or official advice. '
              'For immediate danger, contact emergency services.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _prompts
                  .map(
                    (prompt) => ActionChip(
                      label: Text(prompt),
                      onPressed: () => _send(prompt),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ask about a disaster or tap a quick prompt. '
                        'Responses come from rules stored on this device.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Card(
                        color: message.reply.urgent
                            ? Theme.of(context).colorScheme.errorContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.query,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message.reply.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              ...message.reply.steps.indexed.map(
                                (step) => Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Text('${step.$1 + 1}. ${step.$2}'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      labelText: 'Describe the situation',
                      prefixIcon: Icon(Icons.health_and_safety_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

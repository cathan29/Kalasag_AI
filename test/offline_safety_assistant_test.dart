import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/offline_safety_assistant.dart';

void main() {
  test('urgent symptoms return an emergency escalation', () {
    final reply = OfflineSafetyGuide.respond('Someone is not breathing');

    expect(reply.urgent, isTrue);
    expect(reply.title, 'Get emergency help now');
  });

  test('disaster keywords return specific offline steps', () {
    final reply = OfflineSafetyGuide.respond('What should I do in a flood?');

    expect(reply.urgent, isFalse);
    expect(reply.title, 'During flooding');
    expect(reply.steps, isNotEmpty);
  });

  testWidgets('quick prompt renders bundled earthquake guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: OfflineSafetyAssistantScreen()),
    );

    expect(find.textContaining('Not live or official advice'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Earthquake'));
    await tester.pump();

    expect(find.text('During an earthquake'), findsOneWidget);
    expect(find.textContaining('Drop to your hands'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/models.dart';

void main() {
  group('EmergencyContact', () {
    test('normalizes common phone number formatting', () {
      expect(
        EmergencyContact.normalizedPhone('+63 (917) 123-4567'),
        '+639171234567',
      );
      expect(EmergencyContact.normalizedPhone('0917 123 4567'), '09171234567');
    });

    test('validates plausible dialable lengths', () {
      expect(EmergencyContact.isValidPhone('911'), isFalse);
      expect(EmergencyContact.isValidPhone('+63 917 123 4567'), isTrue);
      expect(EmergencyContact.isValidPhone('1' * 16), isFalse);
    });

    test('round trips through local-storage JSON', () {
      const original = EmergencyContact(
        id: 'contact-1',
        name: 'Ana Reyes',
        phone: '+639171234567',
        relationship: 'Sister',
      );

      final restored = EmergencyContact.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.phone, original.phone);
      expect(restored.relationship, original.relationship);
    });
  });
}

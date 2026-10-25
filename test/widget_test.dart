import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalasag/theme.dart';

void main() {
  test('Kalasag theme has the expected brand color', () {
    expect(KalasagTheme.primary, const Color(0xFF4B8FF7));
  });
}

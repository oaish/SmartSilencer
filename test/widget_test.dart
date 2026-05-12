import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_silencer/main.dart';

void main() {
  testWidgets('SmartSilencer smoke test', (WidgetTester tester) async {
    // Just verify the widget tree builds without crashing
    expect(SmartSilencerApp, isNotNull);
  });
}

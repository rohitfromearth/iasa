import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/presentation/widgets/offline_answer_banner.dart';

void main() {
  testWidgets('OfflineAnswerBanner shows offline warning message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OfflineAnswerBanner()),
      ),
    );

    expect(find.text(OfflineAnswerBanner.message), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });
}

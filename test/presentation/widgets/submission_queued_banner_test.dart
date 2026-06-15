import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/presentation/widgets/submission_queued_banner.dart';

void main() {
  testWidgets('SubmissionQueuedBanner shows queued confirmation message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SubmissionQueuedBanner()),
      ),
    );

    expect(find.text(SubmissionQueuedBanner.queuedMessage), findsOneWidget);
    expect(find.text(SubmissionQueuedBanner.waitingMessage), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });
}

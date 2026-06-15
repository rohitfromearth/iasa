import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iasa/core/state/ui_state.dart';
import 'package:iasa/presentation/widgets/ui_state_view.dart';

void main() {
  testWidgets('UiStateView renders empty state for case list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UiStateView<List<String>>(
            state: const UiEmpty(message: 'No cases available'),
            successBuilder: (data) => ListView(children: data.map(Text.new).toList()),
          ),
        ),
      ),
    );

    expect(find.text('No cases available'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}

// test/core/tutorial/tutorial_coach_mark_helper_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_learning_app/core/tutorial/tutorial_coach_mark_helper.dart';

void main() {
  testWidgets('showTutorial displays the target title, description and skip label', (tester) async {
    final targetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  Container(key: targetKey, width: 50, height: 50, color: Colors.red),
                  ElevatedButton(
                    onPressed: () {
                      showTutorial(
                        context: context,
                        skipLabel: 'Skip',
                        targets: [
                          buildTutorialTarget(
                            identify: 'test_target',
                            keyTarget: targetKey,
                            title: 'Test Title',
                            description: 'Test Description',
                          ),
                        ],
                      );
                    },
                    child: const Text('Show'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}

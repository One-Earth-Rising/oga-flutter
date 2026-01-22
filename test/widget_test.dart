import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oga_web_showcase/main.dart';

void main() {
  // Suppress asset errors so missing images don't crash the test run
  setUpAll(() {
    FlutterError.onError = (details) {
      if (details.silent) return;
      if (details.exception.toString().contains('assets/')) return;
      FlutterError.presentError(details);
    };
  });

  testWidgets('Landing page to Library transition test', (
    WidgetTester tester,
  ) async {
    // 1. Build the app and trigger a frame
    await tester.pumpWidget(const OgaApp());

    // 2. Verify we start on the Landing screen
    // We use find.textContaining to be flexible with exact string matches
    expect(find.textContaining('Welcome to the OGA Ecosystem'), findsOneWidget);

    // 3. Find the 'CONTINUE TO HUB' button and tap it
    final continueButton = find.text('CONTINUE TO HUB');
    await tester.tap(continueButton);

    // 4. CRITICAL: Wait for all animations and state changes to finish
    // pumpAndSettle() waits until there are no more frames scheduled.
    await tester.pumpAndSettle();

    // 5. Verify the Library screen is now rendered
    // If this fails, double check that LibraryView() uses this exact text
    expect(find.text('MY LIBRARY'), findsOneWidget);

    // 6. Verify at least one character card is present
    expect(find.text('VEGETA'), findsOneWidget);
  });
}

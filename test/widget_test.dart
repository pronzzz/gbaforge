import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gba_forge/main.dart';

// Helper to wrap widgets in ProviderScope
Widget createWidgetUnderTest() {
  return const ProviderScope(child: GbaForgeApp());
}

void main() {
  testWidgets('HomeScreen renders initial state', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(createWidgetUnderTest());

    // Verify that the title is correct
    expect(find.text('GBAForge'), findsOneWidget);

    // Verify initial "Open ROM" message
    expect(find.text('Open a GBA ROM to start'), findsOneWidget);

    // Verify that buttons exist
    expect(find.byIcon(Icons.file_open), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);

    // Verify Navigation Rail icons
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.byIcon(Icons.text_fields), findsOneWidget);
  });

  testWidgets('Navigation rail switches screens', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Tap Script Editor icon (index 1)
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pump();

    // Should see Script Editor button (from empty state)
    // "Disassemble Script at 0x800000" is the initial button text
    expect(find.text('Disassemble Script at 0x800000'), findsOneWidget);
  });
}

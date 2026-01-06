import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/features/editor/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: GbaForgeApp()));
}

class GbaForgeApp extends ConsumerWidget {
  const GbaForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'GBAForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark, // Dark mode for "Hacker" aesthetic
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

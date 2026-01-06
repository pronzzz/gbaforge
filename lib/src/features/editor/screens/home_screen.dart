import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/rom_provider.dart';
import 'package:gba_forge/src/rust/api.dart';
import 'script_editor_screen.dart';
import 'dart:typed_data';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Uint8List? _mapPreview;
  bool _rendering = false;
  int _selectedIndex = 0; // Tab selection

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? path = result.files.single.path;
      if (path != null) {
        await ref.read(romProvider.notifier).loadRomFile(path);
        // Auto-render map 3.0 (Pallet Town) for testing
        // FireRed Map Bank 3, Map 0 is usually Pallet Town.
        // We need the Header Pointer. For now, let's just trigger a dummy render if loaded.
        _renderPreview();
      }
    }
  }

  Future<void> _renderPreview() async {
    setState(() => _rendering = true);
    try {
      // 0x08xxxxxx pointer would go here.
      // Using a dummy pointer because our mock/API expects one.
      final bytes = await renderMapPreview(mapHeaderPtr: 0x08000000);
      setState(() {
        _mapPreview = bytes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Render failed: $e')));
    } finally {
      setState(() => _rendering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final romState = ref.watch(romProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GBAForge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_open),
            onPressed: _pickFile,
            tooltip: 'Open ROM',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            // Dummy save for now
            onPressed: () {},
            tooltip: 'Save ROM',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                  icon: Icon(Icons.map), label: Text('Map')),
              NavigationRailDestination(
                  icon: Icon(Icons.text_fields), label: Text('Script')),
              NavigationRailDestination(
                  icon: Icon(Icons.image), label: Text('Sprites')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: _selectedIndex == 1
                ? const ScriptEditorScreen()
                : Center(
                    child: romState.isLoading
                        ? const CircularProgressIndicator()
                        : romState.filePath == null
                            ? const Text('Open a GBA ROM to start')
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Loaded: ${romState.gameTitle}'),
                                  const SizedBox(height: 20),
                                  _rendering
                                      ? const CircularProgressIndicator()
                                      : _mapPreview != null
                                          // 128x64 is the size we returned in mock/backend
                                          ? SizedBox(
                                              width: 512, // scaled up
                                              height: 256,
                                              child: Image.memory(
                                                _mapPreview!,
                                                gaplessPlayback: true,
                                                fit: BoxFit.contain,
                                              ),
                                            )
                                          : ElevatedButton(
                                              onPressed: _renderPreview,
                                              child: const Text(
                                                  'Render Map Preview'),
                                            ),
                                ],
                              ),
                  ),
          ),
        ],
      ),
    );
  }
}

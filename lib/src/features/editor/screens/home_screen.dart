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

        // Only attempt to render if the load was successful
        if (ref.read(romProvider).error == null) {
          _renderPreview();
        }
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

  Future<void> _saveFile() async {
    final romState = ref.read(romProvider);
    if (romState.filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ROM loaded to save')),
      );
      return;
    }

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save ROM',
      fileName: 'modified_rom.gba',
    );

    if (outputFile != null) {
      await ref.read(romProvider.notifier).saveRomFile(outputFile);
      if (mounted) {
        final error = ref.read(romProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error == null
                ? 'ROM saved successfully!'
                : 'Save failed: $error'),
            backgroundColor: error == null ? Colors.green : Colors.red,
          ),
        );
      }
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
            onPressed: _saveFile,
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
            child: romState.filePath == null
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Open a GBA ROM to start'),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_open),
                        label: const Text('Open ROM'),
                        onPressed: _pickFile,
                      ),
                    ],
                  ))
                : _buildContent(romState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(RomState romState) {
    if (romState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (romState.error != null && _selectedIndex != 0) {
      // If there's an error, forcing back to main tab might be better,
      // but showing error here is fine too.
      return Center(
          child: Text('Error: ${romState.error}',
              style: const TextStyle(color: Colors.red)));
    }

    switch (_selectedIndex) {
      case 0: // Map
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Loaded: ${romState.gameTitle ?? "Unknown Title"}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              if (romState.error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${romState.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              _rendering
                  ? const CircularProgressIndicator()
                  : _mapPreview != null
                      ? SizedBox(
                          width: 512,
                          height: 256,
                          child: Image.memory(
                            _mapPreview!,
                            gaplessPlayback: true,
                            fit: BoxFit.contain,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _renderPreview,
                          child: const Text('Render Map Preview'),
                        ),
            ],
          ),
        );
      case 1: // Script
        return const ScriptEditorScreen();
      case 2: // Sprites
        return const Center(child: Text("Sprite Editor - Coming Soon"));
      default:
        return const SizedBox.shrink();
    }
  }
}

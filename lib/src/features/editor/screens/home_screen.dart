import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/rom_provider.dart';
import '../providers/offset_provider.dart';
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
  int _selectedIndex = 0;

  // Map Editor State
  final TextEditingController _offsetController = TextEditingController();
  final TransformationController _transformController =
      TransformationController();
  Offset? _tapPosition;
  String _selectedTileInfo = "None";

  @override
  void initState() {
    super.initState();
    _offsetController.text = "0x08000000"; // Default placeholder
  }

  @override
  void dispose() {
    _offsetController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? path = result.files.single.path;
      if (path != null) {
        await ref.read(romProvider.notifier).loadRomFile(path);

        // Auto-detect offset
        final romState = ref.read(romProvider);
        if (romState.error == null && romState.gameCode != null) {
          final offsetData =
              ref.read(offsetProvider.notifier).getOffsets(romState.gameCode!);

          if (offsetData != null && offsetData.mapHeaderPtr != null) {
            _offsetController.text =
                "0x${offsetData.mapHeaderPtr!.toRadixString(16).toUpperCase()}";
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text("Auto-detected offsets for ${offsetData.name}")));
            }
            _renderPreview();
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "Offsets for ${romState.gameCode ?? 'Unknown'} not found in DB. Please enter Map Header Offset manually.")));
            }
            // Do not render automatically if offset unknown
          }
        }
      }
    }
  }

  Future<void> _renderPreview() async {
    setState(() => _rendering = true);
    try {
      // Parse offset from text field
      String text = _offsetController.text.trim();
      int? offset;
      if (text.startsWith("0x")) {
        offset = int.tryParse(text.substring(2), radix: 16);
      } else {
        offset = int.tryParse(text);
      }

      if (offset == null) throw Exception("Invalid Offset Format");

      final bytes = await renderMapPreview(mapHeaderPtr: offset);
      setState(() {
        _mapPreview = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Render failed: $e')));
      }
      // Reset map preview if failed
      setState(() {
        _mapPreview = null;
      });
    } finally {
      if (mounted) {
        setState(() => _rendering = false);
      }
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

  void _onMapTap(TapUpDetails details) {
    if (_mapPreview == null) return;

    // Calculate tile coordinates relative to the image
    setState(() {
      _tapPosition = details.localPosition;
      // Since displayed image is scaled, logic can be refined later.
      _selectedTileInfo =
          "Tap at ${_tapPosition!.dx.toStringAsFixed(1)}, ${_tapPosition!.dy.toStringAsFixed(1)}";
    });
  }

  @override
  Widget build(BuildContext context) {
    final romState = ref.watch(romProvider);
    // Ensure offsets are loaded
    ref.watch(offsetProvider);

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
                      if (romState.error != null)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error: ${romState.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_open),
                        label: const Text('Open ROM'),
                        onPressed: _pickFile,
                      ),
                    ],
                  ))
                : _buildContent(romState),
          ),
          // Validator / Inspector Panel (Only show on Map tab when ROM loaded)
          if (_selectedIndex == 0 && romState.filePath != null) ...[
            const VerticalDivider(thickness: 1, width: 1),
            Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Inspector",
                      style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  const Text("Map Header Pointer:"),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _offsetController,
                    decoration: const InputDecoration(
                      hintText: "0x08xxxxxx",
                      isDense: true,
                      border: OutlineInputBorder(),
                      labelText: "Offset (Hex)",
                    ),
                    onSubmitted: (_) => _renderPreview(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _renderPreview,
                        child: const Text("Render Map")),
                  ),
                  const Divider(),
                  Text("Selected Tile:",
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 5),
                  Text(_selectedTileInfo),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildContent(RomState romState) {
    if (romState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (romState.error != null && _selectedIndex != 0) {
      return Center(
          child: Text('Error: ${romState.error}',
              style: const TextStyle(color: Colors.red)));
    }

    switch (_selectedIndex) {
      case 0: // Map
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey.shade200,
              width: double.infinity,
              child: Text(
                'Loaded: ${romState.gameTitle ?? "Unknown"} (${romState.gameCode ?? "?"})',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: _rendering
                  ? const Center(child: CircularProgressIndicator())
                  : _mapPreview == null
                      ? const Center(
                          child: Text(
                              "No Map Rendered\nEnter an offset and click Render."))
                      : InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 0.1,
                          maxScale: 10.0,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          child: Center(
                            child: GestureDetector(
                              onTapUp: _onMapTap,
                              child: Image.memory(
                                _mapPreview!,
                                gaplessPlayback: true,
                                filterQuality:
                                    FilterQuality.none, // Pixel art style
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
            ),
          ],
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

import 'package:flutter/material.dart';
import 'package:gba_forge/src/rust/api.dart';
import 'package:gba_forge/src/rust/scripting.dart';

class ScriptEditorScreen extends StatefulWidget {
  const ScriptEditorScreen({super.key});

  @override
  State<ScriptEditorScreen> createState() => _ScriptEditorScreenState();
}

class _ScriptEditorScreenState extends State<ScriptEditorScreen> {
  List<ScriptCommand>? _script;
  bool _loading = false;

  Future<void> _loadScript() async {
    setState(() => _loading = true);
    try {
      // Mock offset for testing
      final script = await disassembleScript(offset: 0x800000);
      setState(() => _script = script);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_script == null && !_loading) {
      return Center(
        child: ElevatedButton(
          onPressed: _loadScript,
          child: const Text("Disassemble Script at 0x800000"),
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Simple list view simulation of a Node Graph
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _script!.length,
      itemBuilder: (context, index) {
        final cmd = _script![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Node ${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                if (cmd is ScriptCommand_Message)
                  Text("Message Box\nPtr: 0x${cmd.textPtr.toRadixString(16)}"),
                if (cmd is ScriptCommand_TrainerBattle)
                  Text("Trainer Battle\nID: ${cmd.trainerId}"),
                if (cmd is ScriptCommand_End)
                  const Text("End Script", style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        );
      },
    );
  }
}

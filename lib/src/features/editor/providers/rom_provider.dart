import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gba_forge/src/rust/api.dart';

// State to hold the currently loaded ROM info
class RomState {
  final String? filePath;
  final String? gameTitle;
  final String? gameCode;
  final bool isLoading;
  final String? error;

  RomState({
    this.filePath,
    this.gameTitle,
    this.gameCode,
    this.isLoading = false,
    this.error,
  });

  RomState copyWith({
    String? filePath,
    String? gameTitle,
    String? gameCode,
    bool? isLoading,
    String? error,
  }) {
    return RomState(
      filePath: filePath ?? this.filePath,
      gameTitle: gameTitle ?? this.gameTitle,
      gameCode: gameCode ?? this.gameCode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class RomNotifier extends StateNotifier<RomState> {
  RomNotifier() : super(RomState());

  Future<void> loadRomFile(String path) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // 1. Load Rom
      final title = await loadRom(path: path);

      // 2. Fetch Header Info to get Code
      String code = "UNKNOWN";
      try {
        final info = await getRomHeaderInfo();
        // Format is "Code: XXXX, Title: YYYY"
        final parts = info.split(',');
        if (parts.isNotEmpty) {
          final codePart = parts[0].trim(); // "Code: XXXX"
          if (codePart.startsWith("Code: ")) {
            code = codePart.substring(6);
          }
        }
      } catch (e) {
        print("Failed to fetch header info: $e");
      }

      state = state.copyWith(
        filePath: path,
        gameTitle: title,
        gameCode: code,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveRomFile(String path) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await saveRom(outputPath: path);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final romProvider = StateNotifierProvider<RomNotifier, RomState>((ref) {
  return RomNotifier();
});

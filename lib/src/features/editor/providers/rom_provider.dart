import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gba_forge/src/rust/api.dart';

// State to hold the currently loaded ROM info
class RomState {
  final String? filePath;
  final String? gameTitle;
  final bool isLoading;
  final String? error;

  RomState({this.filePath, this.gameTitle, this.isLoading = false, this.error});

  RomState copyWith(
      {String? filePath, String? gameTitle, bool? isLoading, String? error}) {
    return RomState(
      filePath: filePath ?? this.filePath,
      gameTitle: gameTitle ?? this.gameTitle,
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
      final title = await loadRom(path: path);
      state =
          state.copyWith(filePath: path, gameTitle: title, isLoading: false);
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

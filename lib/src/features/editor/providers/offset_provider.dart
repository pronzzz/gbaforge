import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OffsetData {
  final String name;
  final int? mapHeaderPtr;
  final int? scriptBankPtr;

  OffsetData({
    required this.name,
    this.mapHeaderPtr,
    this.scriptBankPtr,
  });

  factory OffsetData.fromJson(Map<String, dynamic> json) {
    return OffsetData(
      name: json['name'] as String,
      mapHeaderPtr: json['map_header_ptr'] != null
          ? int.tryParse(json['map_header_ptr']) ??
              int.tryParse(json['map_header_ptr'].substring(2), radix: 16)
          : null,
      scriptBankPtr: json['script_bank_ptr'] != null
          ? int.tryParse(json['script_bank_ptr']) ??
              int.tryParse(json['script_bank_ptr'].substring(2), radix: 16)
          : null,
    );
  }
}

class OffsetNotifier extends StateNotifier<Map<String, OffsetData>> {
  OffsetNotifier() : super({});

  Future<void> loadOffsets() async {
    try {
      final jsonString = await rootBundle.loadString('assets/offsets.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      final Map<String, OffsetData> offsets = {};
      jsonMap.forEach((key, value) {
        offsets[key] = OffsetData.fromJson(value);
      });

      state = offsets;
    } catch (e) {
      // Log error (avoid print in production, but okay for debug)
      print('Error loading offsets: $e');
    }
  }

  OffsetData? getOffsets(String gameCode) {
    return state[gameCode];
  }
}

final offsetProvider =
    StateNotifierProvider<OffsetNotifier, Map<String, OffsetData>>((ref) {
  final notifier = OffsetNotifier();
  notifier.loadOffsets();
  return notifier;
});

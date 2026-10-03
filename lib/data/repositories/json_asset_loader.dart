import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Loads mock data bundled in `assets/data/*.json`.
class JsonAssetLoader {
  const JsonAssetLoader(this._bundle);

  final AssetBundle _bundle;

  Future<List<Map<String, dynamic>>> loadList(String path) async {
    final raw = await _bundle.loadString(path);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }
}

final jsonAssetLoaderProvider =
    Provider<JsonAssetLoader>((ref) => JsonAssetLoader(rootBundle));

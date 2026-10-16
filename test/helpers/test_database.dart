import 'dart:io';

import 'package:flutter_pos/data/datasources/local/database.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Serves a temp directory as the app documents directory, so the real
/// [AppDatabase] (file-backed drift/sqlite) opens on the test host.
class _TempPathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _TempPathProvider(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

/// A fresh, empty [AppDatabase] in its own temp directory. Close it after use.
Future<AppDatabase> openTestDatabase() async {
  final dir = await Directory.systemTemp.createTemp('flutter_pos_test_');
  PathProviderPlatform.instance = _TempPathProvider(dir.path);
  return AppDatabase();
}

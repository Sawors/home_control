import 'dart:convert';
import 'dart:io';

import 'config.dart';

class LocalFiles {
  static const String projectNamespace = "net.sawors.home_control";
  static final Map<String, Directory> _asyncDirs = {};
  Directory get cacheDir {
    if (Platform.isLinux) {
      return Directory(
        "${Platform.environment["HOME"]}/.cache/$projectNamespace",
      );
    } else if (Platform.isAndroid) {
      return _asyncDirs["android-cache"]!;
    }
    throw UnsupportedError(
      "Cache management is not yet implemented for your operating system.",
    );
  }

  Directory get configDir {
    if (Platform.isLinux) {
      return Directory("${Platform.environment["HOME"]}/.config/home_control");
    } else if (Platform.isAndroid) {
      return _asyncDirs["android-data"]!;
    }
    throw UnsupportedError(
      "Cache management is not yet implemented for your operating system.",
    );
  }

  Directory get dataDir {
    if (Platform.isLinux) {
      return Directory(
        "${Platform.environment["HOME"]}/.local/share/$projectNamespace",
      );
    } else if (Platform.isAndroid) {
      return _asyncDirs["android-userdata"]!;
    }
    throw UnsupportedError(
      "Cache management is not yet implemented for your operating system.",
    );
  }

  Directory get homeStoreDir {
    return Directory("${dataDir.path}/homes");
  }

  Directory get adaptersDir {
    return Directory("${dataDir.path}/adapters");
  }

  String get configFilePath => "${configDir.path}/config.json";
  String get serverConfigFilePath => "${configDir.path}/server-config.json";
  String get accessKeyFilePath => "${dataDir.path}/access.json";

  static Future<void> initializeDirectories({
    bool server = false,
    Map<String, Directory>? deviceAsyncDirMap,
  }) async {
    final localFiles = LocalFiles();
    _asyncDirs.addAll(deviceAsyncDirMap ?? {});
    await localFiles.configDir.create();
    await localFiles.dataDir.create(recursive: true);
    await localFiles.homeStoreDir.create(recursive: true);
    final File configFile = File(
      server ? LocalFiles().serverConfigFilePath : LocalFiles().configFilePath,
    );
    if (!await configFile.exists()) {
      await configFile.writeAsString(
        JsonEncoder.withIndent("  ").convert(
          server
              ? ProgramConfig().defaultServerConfig
              : ProgramConfig().defaultConfig,
        ),
      );
    }
    await localFiles.cacheDir.create();
  }
}

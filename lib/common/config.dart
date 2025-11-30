import 'dart:convert';
import 'dart:io';

class ProgramConfig {
  static final Map<String, dynamic> configData = {};

  Map<String, dynamic> get defaultConfig => {
    "server": "https://rpi-aux.local:4143",
  };
  Map<String, dynamic> get defaultServerConfig => {
    "port": "4143",
    "binding-address": "https://rpi-aux.local",
  };

  static Future<dynamic> loadConfigFromFile(
    File file, {
    bool merge = false,
  }) async {
    if (!merge) {
      configData.clear();
    }
    configData.addAll(jsonDecode(await file.readAsString()));
  }

  static dynamic getConfigValue(String path) {
    final pathElements = path.split(".");
    dynamic value;
    Map<String, dynamic> submap = configData;
    for (String e in pathElements) {
      value = submap[e];
      if (value is List<dynamic>) {
        submap = Map.fromEntries(
          value.indexed.map((e) => MapEntry(e.$1.toString(), e.$2)),
        );
      } else if (value is Map<String, dynamic>) {
        submap = value;
      } else {
        submap = {};
      }
    }
    return value;
  }
}

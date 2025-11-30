import 'dart:convert';
import 'dart:io';

import 'local_files.dart';

final class CacheEntry {
  static const Duration defaultLifetime = Duration(hours: 1);
  static const Duration immortalLifetime = Duration.zero;
  late final dynamic value;
  late final DateTime birth;
  late final Duration lifetime;

  bool get isExpired =>
      lifetime.compareTo(immortalLifetime) != 0 &&
      birth.add(lifetime).isBefore(DateTime.now());

  // set lifetime to 0 to ignore lifetime
  CacheEntry(this.value, {DateTime? birth, Duration? lifetime}) {
    this.birth = birth ?? DateTime.now();
    this.lifetime = lifetime ?? defaultLifetime;
  }

  CacheEntry.immortal(this.value, {DateTime? birth}) {
    this.birth = birth ?? DateTime.now();
    lifetime = immortalLifetime;
  }

  Map<String, dynamic> get asMap => {
    "value": value,
    "birth": birth.toUtc().toIso8601String(),
    "lifetime": lifetime.inSeconds.toString(),
  };

  CacheEntry.fromMap(Map<String, dynamic> map) {
    if (!map.containsKey("value")) {
      throw ArgumentError("'value' field cannot be empty !");
    }
    value = map["value"];
    birth = map.containsKey("birth")
        ? DateTime.parse(map["birth"])
        : DateTime.now();
    lifetime = Duration(seconds: int.tryParse(map["lifetime"] ?? "0") ?? 0);
  }
}

class CacheManager {
  static CacheManager? _instance;
  final Map<NamespacedKey, CacheEntry> cacheState = {};
  final Set<String> cacheNamespaceToSave = {};
  final Set<String> unloadedNamespaces = {};
  final Set<String> excludedFromSaveNamespaces = {};
  final bool lazyLoading;
  final Directory cacheDir;

  CacheManager({this.lazyLoading = true, required this.cacheDir});

  static Future<CacheManager> initialize({CacheManager? source}) async {
    _instance ??= source ?? CacheManager(cacheDir: managedCacheDirectory);
    return instance;
  }

  static CacheManager get instance {
    if (_instance == null) {
      throw StateError("The cache manager has not been initialized");
    }
    return _instance!;
  }

  static Directory get managedCacheDirectory => Directory(
    "${LocalFiles().cacheDir.path}${Platform.pathSeparator}managed",
  );

  Future<Map<NamespacedKey, CacheEntry>> loadCacheNamespace(
    String namespace,
  ) async {
    final File file = File("${cacheDir.path}/$namespace.json");
    return loadCacheFile(file);
  }

  Future<Map<NamespacedKey, CacheEntry>> loadCacheFile(File file) async {
    final fileName = file.uri.pathSegments.last;
    final String namespace = fileName.endsWith(".json")
        ? fileName.substring(0, fileName.length - 5)
        : fileName;
    if (!await file.exists()) {
      throw FileSystemException(
        "Cache file not found for namespace $namespace",
      );
    }
    const JsonDecoder decoder = JsonDecoder();
    Map<NamespacedKey, CacheEntry> result = {};
    Map<String, dynamic> fileMap =
        decoder.convert(await file.readAsString()) as Map<String, dynamic>;
    for (MapEntry<String, dynamic> entry in fileMap.entries) {
      NamespacedKey key = NamespacedKey(namespace, entry.key);
      if (entry.value is Map<String, dynamic>) {
        try {
          final ent = CacheEntry.fromMap(entry.value);
          if (!ent.isExpired) {
            result[key] = ent;
          } else {
            stdout.writeln(
              "[CACHE] : skipping expired entry ${key.toString()}",
            );
          }
        } on ArgumentError {
          // ignore
        }
      }
    }
    unloadedNamespaces.remove(namespace);
    cacheState.addAll(result);
    return result;
  }

  Map<NamespacedKey, CacheEntry> loadCacheNamespaceSync(String namespace) {
    final File file = File("${cacheDir.path}/$namespace.json");
    return loadCacheFileSync(file);
  }

  Map<String, CacheEntry> getNamespace(String namespace) {
    return Map.fromEntries(
      cacheState.entries
          .where((e) => e.key.namespace == namespace)
          .map((e) => MapEntry(e.key.key, e.value)),
    );
  }

  Map<NamespacedKey, CacheEntry> loadCacheFileSync(File file) {
    final fileName = file.uri.pathSegments.last;
    final String namespace = fileName.endsWith(".json")
        ? fileName.substring(0, fileName.length - 5)
        : fileName;
    if (!file.existsSync()) {
      throw FileSystemException(
        "Cache file not found for namespace $namespace",
      );
    }
    const JsonDecoder decoder = JsonDecoder();
    Map<NamespacedKey, CacheEntry> result = {};
    Map<String, dynamic> fileMap =
        decoder.convert(file.readAsStringSync()) as Map<String, dynamic>;
    for (MapEntry<String, dynamic> entry in fileMap.entries) {
      NamespacedKey key = NamespacedKey(namespace, entry.key);
      if (entry.value is Map<String, dynamic>) {
        try {
          final ent = CacheEntry.fromMap(entry.value);
          if (!ent.isExpired) {
            result[key] = ent;
          } else {
            stdout.writeln(
              "[CACHE] : skipping expired entry ${key.toString()}",
            );
          }
        } on ArgumentError {
          // ignore
        }
      }
    }
    unloadedNamespaces.remove(namespace);
    cacheState.addAll(result);
    return result;
  }

  Future<Map<NamespacedKey, CacheEntry>> loadCache() async {
    Directory cacheDir = managedCacheDirectory;
    Map<NamespacedKey, CacheEntry> result = {};
    if (!await cacheDir.exists()) {
      return result;
    }
    for (FileSystemEntity f in await cacheDir.list().toList()) {
      if (await FileSystemEntity.isFile(f.path)) {
        String fileName = f.uri.pathSegments.last;
        final String filenameNoExtension = fileName.endsWith(".json")
            ? fileName.substring(0, fileName.length - 5)
            : fileName;
        if (!lazyLoading) {
          result.addAll(await loadCacheFile(f as File));
        } else {
          unloadedNamespaces.add(filenameNoExtension);
        }
      }
    }
    cacheState.addAll(result);
    return result;
  }

  Future<void> saveNamespace(String namespace) async {
    if (excludedFromSaveNamespaces.contains(namespace)) {
      return;
    }
    File cacheFile = File(
      "${managedCacheDirectory.path}${Platform.pathSeparator}$namespace.json",
    );
    Map<String, Map<String, dynamic>> entries = Map.fromEntries(
      cacheState.entries
          .where((v) => v.key.namespace == namespace && !v.value.isExpired)
          .map((v) => MapEntry(v.key.key, v.value.asMap)),
    );
    if (entries.isEmpty) {
      await cacheFile.delete();
    } else {
      await cacheFile.create(recursive: true).then((f) {
        try {
          final converted = jsonEncode(entries);
          f.writeAsString(converted);
        } catch (_) {
          stdout.writeln(
            "[CACHE] : Could not save cache file ${f.uri.pathSegments.last}",
          );
        }
      });
    }
  }

  Future<void> saveCache() async {
    if (cacheNamespaceToSave.isEmpty) {
      return;
    }

    for (String namespace in cacheNamespaceToSave) {
      stdout.writeln("[CACHE] : saving namespace '$namespace'");
      await saveNamespace(namespace);
    }
    cacheNamespaceToSave.clear();
  }

  setCachedValue(NamespacedKey key, String value) {
    if (lazyLoading) {
      final namespace = key.namespace;
      if (unloadedNamespaces.contains(namespace)) {
        cacheState.addAll(loadCacheNamespaceSync(namespace));
      }
    }
    CacheEntry entry = CacheEntry(value);
    if (cacheState[key] != entry) {
      cacheNamespaceToSave.add(key.namespace);
      cacheState[key] = entry;
    }
  }

  removeKey(NamespacedKey key) {
    if (lazyLoading) {
      final namespace = key.namespace;
      if (unloadedNamespaces.contains(namespace)) {
        cacheState.addAll(loadCacheNamespaceSync(namespace));
      }
    }
    cacheState.remove(key);
    cacheNamespaceToSave.add(key.namespace);
  }

  removeNamespace(String namespace) {
    if (lazyLoading) {
      if (unloadedNamespaces.contains(namespace)) {
        cacheState.addAll(loadCacheNamespaceSync(namespace));
      }
    }
    cacheState.removeWhere((k, _) => k.namespace == namespace);
    cacheNamespaceToSave.add(namespace);
  }

  setCachedEntry(NamespacedKey key, CacheEntry entry) {
    if (lazyLoading) {
      final namespace = key.namespace;
      if (unloadedNamespaces.contains(namespace)) {
        cacheState.addAll(loadCacheNamespaceSync(namespace));
      }
    }
    if (cacheState[key] != entry) {
      cacheState[key] = entry;
      cacheNamespaceToSave.add(key.namespace);
    }
  }

  CacheEntry? getCachedEntry(NamespacedKey key) {
    if (lazyLoading) {
      final namespace = key.namespace;
      if (unloadedNamespaces.contains(namespace)) {
        cacheState.addAll(loadCacheNamespaceSync(namespace));
      }
    }
    return cacheState[key];
  }

  dynamic getCachedValue(NamespacedKey key) {
    if (lazyLoading) {
      final namespace = key.namespace;
      if (unloadedNamespaces.contains(namespace)) {
        cacheState.addAll(loadCacheNamespaceSync(namespace));
      }
    }
    return cacheState[key]?.value;
  }
}

class NamespacedKey {
  final String namespace;
  final String key;

  const NamespacedKey(this.namespace, this.key);

  static NamespacedKey? fromStringOrNull(String string) {
    List<String> split = string.split(":");
    if (split.length < 2) {
      return null;
    }
    final namespace = split[0];
    final key = split.sublist(1).join(":");
    if (namespace.isEmpty || key.isEmpty) {
      return null;
    }
    return NamespacedKey(namespace, key);
  }

  static NamespacedKey fromString(String string) {
    List<String> split = string.split(":");
    if (split.length < 2) {
      throw const FormatException(
        "Namespaced key is not correctly formatted ! Missing a namespace or a key",
      );
    }
    final namespace = split[0];
    final key = split.sublist(1).join(":");
    if (namespace.isEmpty || key.isEmpty) {
      throw const FormatException(
        "Namespaced key is not correctly formatted ! Missing a namespace or a key",
      );
    }
    return NamespacedKey(namespace, key);
  }

  @override
  String toString() {
    return "$namespace:$key";
  }

  String toPath() {
    return "$namespace/$key";
  }

  @override
  bool operator ==(Object other) {
    return hashCode == other.hashCode;
  }

  @override
  int get hashCode => toString().hashCode;
}

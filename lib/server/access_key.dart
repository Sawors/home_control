import 'package:home_control/devices/devices.dart';
import 'package:home_control/devices/home.dart';

class AccessKeyManager {
  //     Key Hash, The actual key
  final Map<String, AccessCredentials> userAccessKeys;

  AccessKeyManager({required this.userAccessKeys});

  static AccessKeyManager fromJsonMap(List<dynamic> jsonMap) {
    return AccessKeyManager(
      userAccessKeys: Map.fromEntries(
        jsonMap.map((e) {
          final key = AccessCredentials.fromJsonMap(e);
          return MapEntry(key.keyHash, key);
        }),
      ),
    );
  }

  List<dynamic> toJsonMap() {
    return userAccessKeys.values.map((v) => v.toJsonMap()).toList();
  }

  static (bool, bool) hasDeviceTypeAccess(
    String deviceType,
    Set<String> accessScope,
  ) {
    final Set<String> typeAccessesQuery = {};
    final Set<String> typeAccessesControl = {};
    for (String scope in accessScope) {
      final identifier = scope.split(":").first;
      final allowedType = scope.split(":").lastOrNull;
      if (identifier == "device-type-query" && allowedType != null) {
        typeAccessesQuery.add(allowedType);
      } else if (identifier == "device-type-control" && allowedType != null) {
        typeAccessesControl.add(allowedType);
      }
    }

    return (
      typeAccessesQuery.any((t) => deviceType.startsWith(t)),
      typeAccessesControl.any((t) => deviceType.startsWith(t)),
    );
  }
}

class AccessCredentials {
  final String keyHash;
  final String? name;
  final Set<String> accessScope;

  AccessCredentials({
    required this.keyHash,
    required this.accessScope,
    this.name,
  });

  Map<String, dynamic> toJsonMap() {
    return {"key": keyHash, "access-scope": accessScope.toList(), "name": name};
  }

  static AccessCredentials fromJsonMap(Map<String, dynamic> jsonMap) {
    return AccessCredentials(
      keyHash: jsonMap["key"],
      accessScope: (jsonMap["access-scope"] as List<dynamic>)
          .map((r) => r.toString())
          .toSet(),
      name: jsonMap["name"],
    );
  }
}

abstract class AccessScopeChecker {
  static bool hasAdminAccess(Set<String> possessedScopes) {
    return possessedScopes.contains("home-manage");
  }

  static bool hasHomeReadAccess({
    required Set<String> possessedScopes,
    Set<String>? additionalChecks,
  }) {
    return hasAdminAccess(possessedScopes) ||
        {
          "home-query",
          ...additionalChecks ?? {},
        }.any((k) => possessedScopes.contains(k));
  }

  static bool hasHomeWriteAccess({
    required Set<String> possessedScopes,
    Set<String>? additionalChecks,
  }) {
    return hasAdminAccess(possessedScopes) ||
        {
          "home-control",
          ...additionalChecks ?? {},
        }.any((k) => possessedScopes.contains(k));
  }

  static bool hasRoomReadAccess({
    required Room room,
    required Set<String> possessedScopes,
    Set<String>? additionalChecks,
  }) {
    return hasAdminAccess(possessedScopes) ||
        {
          "home-deep-query",
          "home-query-rooms",
          "room-query:${room.id}",
          ...additionalChecks ?? {},
        }.any((k) => possessedScopes.contains(k));
  }

  static bool hasRoomViewAccess({
    required Room room,
    required Set<String> possessedScopes,
    Set<String>? additionalChecks,
  }) {
    return hasAdminAccess(possessedScopes) ||
        hasRoomReadAccess(room: room, possessedScopes: possessedScopes) ||
        {
          "home-deep-query",
          "home-query-rooms",
          "room-query:${room.id}",
          "room-thumbnail:${room.id}",
          ...additionalChecks ?? {},
        }.any((k) => possessedScopes.contains(k));
  }

  static bool hasRoomWriteAccess({
    required Room room,
    required Set<String> possessedScopes,
    Set<String>? additionalChecks,
  }) {
    return hasAdminAccess(possessedScopes) ||
        {
          "home-control-rooms",
          "room-manage:${room.id}",
          ...additionalChecks ?? {},
        }.any((k) => possessedScopes.contains(k));
  }

  static bool hasDeviceReadAccess({
    required HomeDevice device,
    required Room? room,
    required Home? home,
    required Set<String> possessedScopes,
    Set<String>? additionalChecks,
  }) {
    return hasAdminAccess(possessedScopes) ||
        {
          "home-deep-query",
          "home-query-devices",
          "room-query-devices:${room?.id}",
          "device-type-query:${device.deviceType}",
          "device-query:${device.id}",
          ...additionalChecks ?? {},
        }.any((k) => possessedScopes.contains(k));
  }

  static bool hasDeviceViewAccess({
    required HomeDevice device,
    required Room? room,
    required Home? home,
    required Set<String> possessedScopes,
    Set<String>? additionalChecks,
  }) {
    return hasAdminAccess(possessedScopes) ||
        hasDeviceReadAccess(
          device: device,
          room: room,
          home: home,
          possessedScopes: possessedScopes,
        ) ||
        {
          "device-thumbnail:${device.id}",
          ...additionalChecks ?? {},
        }.any((k) => possessedScopes.contains(k));
  }

  static bool hasDeviceWriteAccess({
    required HomeDevice device,
    required Room? room,
    required Home? home,
    required Set<String> possessedScopes,
    Set<String>? additionalChecks,
  }) {
    return hasAdminAccess(possessedScopes) ||
        {
          "home-control-devices",
          "room-control-devices:${room?.id}",
          "device-type-control:${device.deviceType}",
          "device-control:${device.id}",
          ...additionalChecks ?? {},
        }.any((k) => possessedScopes.contains(k));
  }
}

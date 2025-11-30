import 'dart:convert';
import 'dart:io';

import 'package:address/address.dart';
import 'package:home_control/common/utils.dart';
import 'package:home_control/devices/devices.dart';
import 'package:home_control/server/access_key.dart';

import '../common/color.dart';

class Home {
  final String name;
  final String id;
  final List<Room> rooms;
  final Address address;
  final Map<String, String>? idIpMappings;
  final AccessKeyManager keyring;
  final Uri server;

  Home({
    required this.name,
    required this.id,
    required this.rooms,
    required this.address,
    required this.keyring,
    required this.server,
    this.idIpMappings,
  });

  static Future<Home> fromDirectory(Directory dir, Uri server) async {
    final Directory rooms = Directory("${dir.path}/rooms");
    final File homeConfig = File("${dir.path}/home.json");
    final File ipMappings = File("${dir.path}/ips.json");
    final File keyringFile = File("${dir.path}/keys.json");
    final AccessKeyManager keyring = AccessKeyManager.fromJsonMap(
      jsonDecode(await keyringFile.readAsString()),
    );
    final jsonData = jsonDecode(await homeConfig.readAsString());
    Map<String, String>? mappings;
    try {
      mappings =
          (jsonDecode(await ipMappings.readAsString()) as Map<String, dynamic>)
              .map((s, v) => MapEntry(s, v.toString()));
    } catch (_) {}
    final List<Room> loadRooms = [];
    final String homeId = jsonData["id"];
    await for (FileSystemEntity f in rooms.list(recursive: false)) {
      if (!await FileSystemEntity.isDirectory(f.path)) {
        continue;
      }
      try {
        final Room room = await Room.fromDirectory(
          Directory(f.path),
          homeId: homeId,
          ipMappings: mappings,
          server: server,
        );
        loadRooms.add(room);
      } catch (e) {
        stderr.writeln("Error while looking for a room in ${f.path} : $e");
      }
    }

    return Home(
      name: jsonData["name"],
      id: homeId,
      rooms: loadRooms,
      idIpMappings: mappings,
      address: addressFromJsonMap(jsonData["address"]),
      keyring: keyring,
      server: server,
    );
  }

  static Home fromFullJson(Map<String, dynamic> jsonMap, {Uri? server}) {
    final Map<String, HomeDevice> devices = {};
    final Map<String, String>? ipMappings = null;

    final homeData = jsonMap["home"];
    final roomData = jsonMap["rooms"];
    final deviceData = jsonMap["devices"];
    for (Map<String, dynamic> deviceMap in deviceData) {
      final device = HomeDevice.fromJsonMap(
        deviceMap,
        homeId: homeData["id"],
        ipOverrides: Map.fromEntries(
          (homeData["ip-mappings"] as Map<String, dynamic>).entries.map(
            (d) => MapEntry(d.key, d.value.toString()),
          ),
        ),
      );
      if (device != null) {
        devices[device.id] = device;
      }
    }

    return Home(
      name: homeData["name"],
      id: homeData["id"],
      rooms: (roomData as List<dynamic>)
          .map((r) => Room.fromJsonMap(r, devices, server: server))
          .toList(),
      idIpMappings: ipMappings,
      address: addressFromJsonMap(homeData["address"]),
      keyring: AccessKeyManager.fromJsonMap(homeData["keyring"]),
      server: jsonMap["server"] ?? server,
    );
  }

  // homeId/roomId:deviceId
  HomeDevice? getDevice(String devicePath) {
    final split = devicePath.split(":");
    final deviceId = split.last;
    final pathSegments = split.first.split("/");
    final String targetHomeId = pathSegments.first;
    final String targetRoomId = pathSegments.last;
    if (targetHomeId != id) {
      return null;
    }
    for (Room r in rooms) {
      if (r.id == targetRoomId) {
        for (HomeDevice d in r.devices) {
          if (d.id == deviceId) {
            return d;
          }
        }
      }
    }

    return null;
  }

  Room? getRoom(String roomId) {
    for (Room r in rooms) {
      if (r.id == roomId) {
        return r;
      }
    }
    return null;
  }

  Map<String, dynamic> toJsonMap({bool includeKeyring = false}) {
    final json = {
      "name": name,
      "id": id,
      "address": addressToJsonMap(address),
      "rooms": rooms.map((r) => r.id).toList(),
      "ip-mappings": idIpMappings,
    };
    if (includeKeyring) {
      json["keyring"] = keyring.toJsonMap();
    }
    return json;
  }
}

class Coordinates {
  final double x;
  final double y;
  final double z;

  Coordinates(this.x, this.y, this.z);

  Map<String, dynamic> toJsonMap() {
    return {"x": x, "y": y, "z": z};
  }

  static Coordinates fromJsonMap(dynamic jsonMap) {
    if (jsonMap is Map<String, dynamic>) {
      return Coordinates(
        (jsonMap["x"] as num).toDouble(),
        (jsonMap["y"] as num).toDouble(),
        ((jsonMap["z"] ?? 0) as num).toDouble(),
      );
    } else if (jsonMap is List<dynamic>) {
      return Coordinates(
        (jsonMap[0] as num).toDouble(),
        (jsonMap[1] as num).toDouble(),
        ((jsonMap.elementAtOrNull(2) ?? 0) as num).toDouble(),
      );
    }
    throw TypeError();
  }
}

class Polygon {
  // WARNING : Only works for polygons without holes !
  late final List<Coordinates> relativePoints;

  Polygon.fromPoints(this.relativePoints);
  Polygon.rectangle(double width, double length, {double? height}) {
    relativePoints = [
      Coordinates(0, 0, height ?? 0),
      Coordinates(width, 0, height ?? 0),
      Coordinates(width, length, height ?? 0),
      Coordinates(0, length, height ?? 0),
    ];
  }

  List<Map<String, dynamic>> toJsonMap() {
    return relativePoints.map((r) => r.toJsonMap()).toList();
  }

  static Polygon fromJsonMap(List<dynamic> jsonMap) {
    return Polygon.fromPoints(
      jsonMap.map((p) => Coordinates.fromJsonMap(p)).toList(),
    );
  }
}

class Room {
  final RGBColor? color;
  final String name;
  final String id;
  final String? icon;
  final String? homeId;
  final Polygon shape;
  final List<HomeDevice> devices;
  final Uri server;
  final String? accessKey;

  Room({
    this.color,
    required this.name,
    required this.id,
    this.icon,
    this.homeId,
    required this.shape,
    required this.devices,
    required this.server,
    this.accessKey,
  });

  static Future<Room> fromDirectory(
    Directory directory, {
    String? homeId,
    required Map<String, String>? ipMappings,
    required Uri server,
    String? accessKey,
  }) async {
    final File roomManifest = File("${directory.path}/room.json");
    final roomManData = jsonDecode(await roomManifest.readAsString());
    final devicesDir = Directory("${directory.path}/devices");
    List<HomeDevice> devices = [];
    await for (FileSystemEntity f in devicesDir.list(recursive: true)) {
      if (await FileSystemEntity.isDirectory(f.path)) {
        continue;
      }
      try {
        final jsonData = jsonDecode(await File(f.path).readAsString());
        final List<dynamic> localDevices = jsonData is List<dynamic>
            ? jsonData
            : [jsonData];
        for (Map<String, dynamic> device in localDevices) {
          final dev = HomeDevice.fromJsonMap(
            device,
            homeId: homeId,
            ipOverrides: ipMappings,
          )?.withAccessKey(accessKey ?? "");
          if (dev != null) {
            devices.add(dev);
          }
        }
      } catch (e) {
        stderr.writeln("Error while reading ${f.path} : $e");
      }
    }

    return Room(
      name: roomManData["name"],
      icon: roomManData["icon"],
      id: roomManData["id"],
      shape: Polygon.fromJsonMap(roomManData["shape"]),
      homeId: homeId,
      devices: devices,
      server: server,
    );
  }

  Map<String, dynamic> toJsonMap() {
    return {
      "name": name,
      "icon": icon,
      "id": id,
      "shape": shape.toJsonMap(),
      "home": homeId,
      "devices": devices.map((d) => d.id).toList(),
    };
  }

  static Room fromJsonMap(
    Map<String, dynamic> jsonMap,
    Map<String, HomeDevice> devices, {
    Uri? server,
  }) {
    return Room(
      name: jsonMap["name"],
      id: jsonMap["id"],
      icon: jsonMap["icon"],
      shape: Polygon.fromJsonMap(jsonMap["shape"]),
      devices: (jsonMap["devices"] as List<dynamic>)
          .map((deviceId) => devices[deviceId])
          .nonNulls
          .toList(),
      server: jsonMap["server"] ?? server,
    );
  }

  HomeDevice? getDevice(String deviceId) {
    for (HomeDevice d in devices) {
      if (d.id == deviceId) {
        return d;
      }
    }
    return null;
  }
}

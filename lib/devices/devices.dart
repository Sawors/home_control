import 'package:home_control/devices/home.dart';
import 'package:home_control/devices/lights/vendors/yeelight/yeelight_light_bulb.dart';

abstract class HomeDevice {
  // How to add a device ? :
  // 1. Create a class that inherits HomeDevice.
  // DEPRECATED
  // 2. Add its builder to the deviceBuilder map with your device specific type.
  //      A builder takes a json map (and optionally a homeId String)
  //      and outputs a HomeDevice instance.
  // 3. You're done !
  //
  // Note : A device path looks like this : "light/philips-hue/bulb".
  //        Each path segment is separated by a "/" and is used to
  //        specify more and more your type of device.
  //
  //        A common way to create a path is :
  //          "<device-general-type>/<constructor>/<object>"
  //
  //        Please note that device paths works in cascade : if your device does
  //        not find a builder in its full path, it will try to find a builder
  //        recursively along the path. This way, you can create very specific
  //        builders and type, or very general ones that act as fallback builders.
  //        For instance, if the builder "light/philips-hue/bulb/gu10" does not exist,
  //        it will search for a builder in "light/philips-hue/bulb",
  //        then "light/philips-hue", then "light".

  static final Map<
    String,
    HomeDevice Function(Map<String, dynamic>, {String? homeId})
  >
  _deviceBuilder = {};
  final String? homeId;
  final String name;
  final String deviceType;
  final String id;
  final String ip;
  final String? icon;
  final Coordinates? location;
  final Uri server;
  String? accessKey;

  HomeDevice({
    this.homeId,
    required this.ip,
    required this.name,
    required this.deviceType,
    required this.id,
    required this.server,
    this.accessKey,
    this.location,
    this.icon,
  });

  DeviceAdapter get adapter;

  HomeDevice withAccessKey(String accessKey) {
    this.accessKey = accessKey;
    return this;
  }

  static HomeDevice? fromJsonMap(
    Map<String, dynamic> jsonMap, {
    String? homeId,
    Map<String, String>? ipOverrides,
  }) {
    final List<String> typePath = jsonMap["device-type"].toString().split("/");
    for (int i = typePath.length - 1; i >= 0; i--) {
      final String subPath = typePath.sublist(0, i + 1).join("/");
      final HomeDevice Function(Map<String, dynamic>, {String? homeId})?
      builder = _deviceBuilder[subPath];
      if (builder != null) {
        final ipOverridden = {
          ...jsonMap,
          "ip": ipOverrides?[jsonMap["id"]] ?? jsonMap["ip"],
        };
        return builder(ipOverridden, homeId: homeId);
      }
    }
    return null;
  }

  Map<String, dynamic> toJsonMap({bool includeServer = false}) {
    return Map.fromEntries(
      {
        "device-type": deviceType,
        "ip": ip,
        "location": location?.toJsonMap(),
        "id": id,
        "home-id": homeId,
        "name": name,
        "icon": icon,
        "server": includeServer ? server : null,
      }.entries.where((e) => e.value != null),
    );
  }

  static HomeDevice? fromType(
    String type,
    Map<String, dynamic> deviceJson, {
    String? homeId,
  }) {
    final List<String> typePath = type.split("/");
    for (int i = typePath.length - 1; i >= 0; i--) {
      final String subPath = typePath.sublist(0, i + 1).join("/");
      final builder = _deviceBuilder[subPath];
      if (builder != null) {
        return builder(deviceJson, homeId: homeId);
      }
    }
    return null;
  }

  static void registerBuilder(
    String deviceType,
    HomeDevice Function(Map<String, dynamic>, {String? homeId}) builder,
  ) {
    _deviceBuilder[deviceType] = builder;
  }

  static void loadBundledDevices({required Uri server}) {
    _deviceBuilder.addAll({
      "light/yeelight": (Map<String, dynamic> jsonMap, {String? homeId}) {
        return YeelightLight(
          ip: jsonMap["ip"],
          name: jsonMap["name"],
          location: jsonMap["location"] != null
              ? Coordinates.fromJsonMap(jsonMap["location"])
              : null,
          homeId: homeId,
          deviceType: jsonMap["device-type"],
          id: jsonMap["id"],
          icon: jsonMap["icon"],
          server: jsonMap["server"] ?? server,
        );
      },
    });
  }

  String buildDevicePath(String homeId, String roomId) {
    return "$homeId/$roomId:$id";
  }

  // client side
  Future<dynamic> sendCommand(List<String> commandArgs, String key);
  // server side
  Future<dynamic> acceptCommand(
    List<String> commandArgs,
    DeviceAdapter adapter,
  );
  Future<Map<String, dynamic>> getState();
}

class ServerAccess {
  final Uri server;

  ServerAccess({required this.server});

  Map<String, dynamic> toJsonMap() {
    return {"server": server.toString()};
  }

  static ServerAccess fromJsonMap(Map<String, dynamic> jsonMap) {
    return ServerAccess(server: Uri.parse(jsonMap["server"]));
  }
}

abstract class DeviceAdapter {
  Future<Map<String, dynamic>> sendCommand(List<String> command);
}

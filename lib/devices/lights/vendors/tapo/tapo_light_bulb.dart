/*
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import '../../light_bulb.dart';

class TapoClient {
  final String username;
  final String password;
  late final String executable;

  TapoClient({
    required this.username,
    required this.password,
    String? executable,
  }) {
    if (Platform.isLinux) {
      this.executable =
          executable ??
          "${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/assets/exe/linux-tapo-api";
    } else if (Platform.isWindows) {
      this.executable =
          executable ??
          "${File(Platform.resolvedExecutable).parent.path}/data/flutter_assets/assets/exe/windows-tapo-api";
    }
  }

  Future<Map<String, dynamic>> sendCommand(List<String> args) async {
    final rez = await Process.run(executable, [username, password, ...args]);
    Map<String, dynamic> result;
    try {
      final rz = jsonDecode(rez.stdout);
      result = rz;
    } catch (_) {
      result = {"error": "${rez.stderr}"};
    }
    return result;
  }
}

class TapoLight extends LightBulb {
  final TapoClient client;

  TapoLight({
    required this.client,
    required super.ip,
    required super.name,
    required super.homeId,
    required super.deviceType,
    required super.id,
    required super.icon,
  });

  // @override
  // Future<LightState> setColorTemperature(double whiteTemperature) async {
  //   // will be clamped between 2500 and 6500
  //   final result = await client.sendCommand([
  //     ip,
  //     "temperature",
  //     whiteTemperature.toString(),
  //   ]);
  //   if (result["error"] != null) {
  //     return LightState.error();
  //   }
  //   return LightState.fromMap(result);
  // }

  @override
  Future<LightState> setBrightness(double brightnessPercent) async {
    final result = await client.sendCommand([
      ip,
      "brightness",
      brightnessPercent.toString(),
    ]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  @override
  Future<LightState> state() async {
    final result = await client.sendCommand([ip, "state"]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  @override
  Future<LightState> toggle() async {
    final result = await client.sendCommand([ip, "toggle"]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  @override
  Future<LightState> off() async {
    final result = await client.sendCommand([ip, "off"]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  @override
  Future<LightState> on() async {
    final result = await client.sendCommand([ip, "on"]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  @override
  Future<LightState> setColor(Color rgbColor) {
    // TODO: implement setColor
    throw UnimplementedError();
  }

  @override
  String get type => "tapo";
}
*/

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:home_control/common/color.dart';
import 'package:home_control/common/local_files.dart';
import 'package:home_control/devices/devices.dart';
import 'package:home_control/devices/lights/light_bulb.dart';
import 'package:http/http.dart';

class YeelightAdapter extends DeviceAdapter {
  late final String executable;
  late final String localAdapterDir;

  YeelightAdapter() {
    localAdapterDir = "${LocalFiles().adaptersDir.path}/lights/yeelight";
    final execPath = "$localAdapterDir/adapter.py";
    if (!File(execPath).existsSync()) {
      throw OSError(
        "Executable for Yeelights not found in ${LocalFiles().adaptersDir.path}}",
      );
    }
    executable = execPath;
  }

  @override
  Future<Map<String, dynamic>> sendCommand(List<String> command) async {
    final rez = await Process.run("$localAdapterDir/bin/python", [
      executable,
      ...command,
    ]);
    Map<String, dynamic> result;
    try {
      final rz = jsonDecode(rez.stdout);
      result = rz;
    } catch (_) {
      result = {"error": "${rez.stdout}"};
    }
    return result;
  }
}

class YeelightLight extends LightBulb {
  // the minimal distance to the "temperature" range from which a rgb color
  // will be transformed into a temperature value
  final double _colorSwitchToTemperatureThreshold = 10;
  YeelightLight({
    required super.ip,
    required super.name,
    super.homeId,
    required super.deviceType,
    required super.id,
    required super.server,
    super.icon,
    super.location,
  });

  @override
  Future<LightState> off() async {
    final rez = await sendCommand([ip, "off"], accessKey ?? "");
    if ((rez["error"] ?? false) == true) {
      return LightState.error();
    }
    return LightState.fromMap(rez["state"]);
  }

  @override
  Future<LightState> on() async {
    final rez = await sendCommand([ip, "on"], accessKey ?? "");
    if ((rez["error"] ?? false) == true) {
      return LightState.error();
    }
    return LightState.fromMap(rez["state"]);
  }

  @override
  Future<LightState> setBrightness(double brightnessPercent) async {
    return setLightState(
      LightState(
        isOn: true,
        brightnessPercent: brightnessPercent,
        color: RGBColor(r: 0, g: 0, b: 0),
        isError: false,
        colorTemperature: 2500,
      ),
      usedFields: ["brightness"],
    );
  }

  @override
  Future<LightState> state() async {
    final rez = await sendCommand([ip, "get-state"], accessKey ?? "");
    if ((rez["error"] ?? false) == true) {
      return LightState.error();
    }
    return LightState.fromMap(rez["state"]);
  }

  Future<LightState> setLightState(
    LightState state, {
    Iterable<String>? usedFields,
  }) async {
    final rez = await sendCommand([
      ip,
      "set-state",
      jsonEncode(state.toJsonMap(usedFields: usedFields)),
    ], accessKey ?? "");
    if ((rez["error"] ?? false) is String) {
      return LightState.error();
    }
    return LightState.fromMap(rez["state"]);
  }

  @override
  Future<LightState> toggle() async {
    final rez = await sendCommand([ip, "toggle"], accessKey ?? "");
    if ((rez["error"] ?? false) == true) {
      return LightState.error();
    }
    return LightState.fromMap(rez["state"]);
  }

  @override
  String get type => "yeelight";

  @override
  Future<LightState> setColor(
    RGBColor rgbColor, {
    bool evaluateForColorTemp = true,
  }) {
    if (evaluateForColorTemp) {
      final distance = getClosestTemperature(rgbColor);
      if (distance.$2 <= _colorSwitchToTemperatureThreshold) {
        return setColorTemperature(distance.$1);
      }
    }
    return setLightState(
      LightState(
        isOn: true,
        brightnessPercent: 0,
        color: rgbColor,
        isError: false,
        colorTemperature: 2500,
      ),
      usedFields: ["color"],
    );
  }

  @override
  Future<LightState> setColorTemperature(int temperatureKelvins) {
    return setLightState(
      LightState(
        isOn: true,
        brightnessPercent: 0,
        color: RGBColor(r: 0, g: 0, b: 0),
        isError: false,
        colorTemperature: temperatureKelvins,
      ),
      usedFields: ["color-temp"],
    );
  }

  double _euclidianDistance(
    RGBColor color1,
    RGBColor color2, {
    bool doSquareRoot = true,
  }) {
    final num distance =
        pow(color1.r - color2.r, 2) +
        pow(color1.g - color2.g, 2) +
        pow(color1.b - color2.b, 2);
    return doSquareRoot ? sqrt(distance) : distance.toDouble();
  }

  (int temp, double distance) getClosestTemperature(RGBColor color) {
    final RGBColor minTemp = RGBColor.fromTemperature(1700);
    final RGBColor maxTemp = RGBColor.fromTemperature(6500);
    final transition = maxTemp.toVector() - minTemp.toVector();

    return (1, 1);
  }

  @override
  Future<dynamic> sendCommand(List<String> commandArgs, String key) async {
    final request = await post(
      Uri.parse(
        "${server.toString()}/api/homes/$homeId?action=send-device-command",
      ),
      headers: {"HC-Access-Key": key},
      body: jsonEncode({id: commandArgs}),
    );
    if (request.statusCode >= 300) {
      return {"error": true, "body": request.body};
    }
    return jsonDecode(request.body)[id];
  }

  @override
  Future<Map<String, dynamic>> acceptCommand(
    List<String> commandArgs,
    DeviceAdapter adapter,
  ) {
    return adapter.sendCommand(commandArgs);
  }

  @override
  Future<Map<String, dynamic>> getState() async {
    return state().then((s) => s.toJsonMap());
  }

  @override
  DeviceAdapter get adapter => YeelightAdapter();
}

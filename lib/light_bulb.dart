import 'dart:convert';
import 'dart:io';

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

class LightState {
  final bool isOn;
  final int brightness;
  final int color;
  final bool isError;

  LightState({
    required this.isOn,
    required this.brightness,
    required this.color,
    required this.isError,
  });

  static LightState fromMap(Map<String, dynamic> jsonMap) {
    return LightState(
      isOn: jsonMap["enabled"],
      brightness: jsonMap["brightness"],
      color: jsonMap["color"],
      isError: false,
    );
  }

  static LightState error() {
    return LightState(isOn: false, brightness: 0, color: 0, isError: true);
  }
}

class LightBulb {
  final String ip;
  final String name;
  final TapoClient client;

  LightBulb({required this.ip, required this.name, required this.client});

  Future<LightState> on() async {
    final result = await client.sendCommand([ip, "on"]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  Future<LightState> off() async {
    final result = await client.sendCommand([ip, "off"]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  Future<LightState> toggle() async {
    final result = await client.sendCommand([ip, "toggle"]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  Future<LightState> state() async {
    final result = await client.sendCommand([ip, "state"]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  Future<LightState> setBrightness(int brightness) async {
    final result = await client.sendCommand([
      ip,
      "brightness",
      brightness.toString(),
    ]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }

  Future<LightState> setColorTemperature(int whiteTemperature) async {
    // will be clamped between 2500 and 6500
    final result = await client.sendCommand([
      ip,
      "temperature",
      whiteTemperature.toString(),
    ]);
    if (result["error"] != null) {
      return LightState.error();
    }
    return LightState.fromMap(result);
  }
}

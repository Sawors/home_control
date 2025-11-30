import 'package:home_control/common/color.dart';
import 'package:home_control/devices/devices.dart';

class LightState {
  final bool isOn;
  final double brightnessPercent;
  final RGBColor color;
  final int colorTemperature;
  final bool isError;

  LightState({
    required this.isOn,
    required this.brightnessPercent,
    required this.color,
    required this.isError,
    required this.colorTemperature,
  });

  static LightState fromMap(Map<String, dynamic> jsonMap) {
    final colorField = jsonMap["color"];
    final color = RGBColor.fromJsonMap(colorField);
    return LightState(
      isOn: jsonMap["enabled"],
      brightnessPercent: jsonMap["brightness"],
      color: color,
      isError: jsonMap["is-error"] ?? false,
      colorTemperature: jsonMap["color-temp"],
    );
  }

  Map<String, dynamic> toJsonMap({
    Iterable<String>? usedFields,
    includeIsError = false,
  }) {
    final map = {
      "enabled": isOn,
      "brightness": brightnessPercent,
      "color": [color.r, color.g, color.b],
      "color-temp": colorTemperature,
    };
    if (usedFields != null) {
      map["used-fields"] = usedFields;
    }
    if (includeIsError) {
      map["is-error"] = isError;
    }
    return map;
  }

  static LightState error() {
    return LightState(
      isOn: false,
      brightnessPercent: 0,
      color: RGBColor(r: 1, g: 0, b: 0),
      isError: true,
      colorTemperature: 2500,
    );
  }
}

abstract class LightBulb extends HomeDevice {
  // this is the client side implementation
  LightBulb({
    required super.ip,
    required super.name,
    super.homeId,
    required super.deviceType,
    required super.id,
    required super.server,
    super.icon,
    super.location,
  });

  String get type;

  Future<LightState> on();

  Future<LightState> off();

  Future<LightState> toggle();

  Future<LightState> state();

  Future<LightState> setBrightness(double brightnessPercent);

  Future<LightState> setColor(RGBColor rgbColor);
  Future<LightState> setColorTemperature(int temperatureKelvins);
}

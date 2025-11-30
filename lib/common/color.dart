import 'dart:math';

import 'package:vector_math/vector_math.dart';

class RGBColor {
  final double r;
  final double g;
  final double b;

  RGBColor({required this.r, required this.g, required this.b});
  static RGBColor fromInt(int integer, {int radix = 16}) {
    return RGBColor(
      r: ((integer >> 16) & 0xFF) / 255,
      g: ((integer >> 8) & 0xFF) / 255,
      b: (integer & 0xFF) / 255,
    );
  }

  static RGBColor fromHexString(String hex) {
    return fromInt(
      int.parse(hex.replaceFirst("#", "").replaceFirst("0x", ""), radix: 16),
    );
  }

  static RGBColor fromJsonMap(List<dynamic> jsonMap) {
    return RGBColor(r: jsonMap[0], g: jsonMap[1], b: jsonMap[2]);
  }

  static RGBColor fromTemperature(num kelvinColorTemp) {
    final temp = kelvinColorTemp / 100;

    final red = temp <= 66
        ? 255
        : (pow(temp - 60, -0.1332047592) * 329.698727446).round().clamp(0, 255);

    final green = temp <= 66
        ? (99.4708025861 * log(temp) - 161.1195681661).round().clamp(0, 255)
        : (pow(temp - 60, -0.0755148492) * 288.1221695283).round().clamp(
            0,
            255,
          );

    final blue = temp >= 66
        ? 255
        : temp <= 19
        ? 0
        : (138.5177312231 * log(temp - 10) - 305.0447927307).round().clamp(
            0,
            255,
          );
    return RGBColor(r: red / 255, g: green / 255, b: blue / 255);
  }

  List<double> toJsonMap() {
    return [r, g, b];
  }

  int toInt8() {
    return ((r * 255).toInt() << 16) +
        ((g * 255).toInt() << 8) +
        (b * 255).toInt();
  }

  String toHexString({String prefix = "#"}) {
    return "$prefix${toInt8().toRadixString(16)}";
  }

  Vector3 toVector() {
    return Vector3(r, g, b);
  }
}

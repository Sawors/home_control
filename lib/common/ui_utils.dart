import 'dart:ui';

import 'color.dart';

extension RGBColorCompat on Color {
  RGBColor toRgbColor() {
    return RGBColor(r: r, g: g, b: b);
  }

  static Color fromTemperature(num colorTemp) {
    return RGBColor.fromTemperature(colorTemp).toDartColor();
  }
}

extension RGBColorUI on RGBColor {
  Color toDartColor() {
    return Color.from(alpha: 1, red: r, green: g, blue: b);
  }
}

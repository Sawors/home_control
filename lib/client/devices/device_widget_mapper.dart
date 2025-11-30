import 'package:flutter/material.dart';
import 'package:home_control/devices/lights/light_bulb.dart';
import 'package:home_control/devices/lights/light_control_widget.dart';

import '../../devices/devices.dart';

abstract class HomeDeviceWidget {
  static final Map<String, Widget? Function(HomeDevice, {String? homeId})>
  deviceWidgetBuilder = {};

  static void registerWidget(
    String deviceType,
    Widget? Function(HomeDevice, {String? homeId}) builder,
  ) {
    deviceWidgetBuilder[deviceType] = builder;
  }

  static Widget? fromDevice(HomeDevice device, {String? homeId}) {
    final List<String> typePath = device.deviceType.split("/");
    for (int i = typePath.length - 1; i >= 0; i--) {
      final String subPath = typePath.sublist(0, i + 1).join("/");
      final Widget? Function(HomeDevice, {String? homeId})? builder =
          deviceWidgetBuilder[subPath];
      if (builder != null) {
        return builder(device, homeId: homeId);
      }
    }
    return null;
  }

  static void loadBundledDevices() {
    deviceWidgetBuilder.addAll({
      "light": (HomeDevice device, {String? homeId}) {
        if (device is LightBulb) {
          return LightControlWidget(light: device);
        }
        return null;
      },
    });
  }
}

import 'package:flutter/material.dart';
import 'package:home_control/client/devices/device_widget_mapper.dart';

import '../../devices/home.dart';
import '../../main.dart';

class RoomWidget extends StatelessWidget {
  final Room room;
  const RoomWidget(this.room, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 30,
        runSpacing: 30,
        children: room.devices
            .map(
              (l) => SizedBox(
                width: 250,
                height: 350,
                child:
                    HomeDeviceWidget.fromDevice(l.withAccessKey(accessKey)) ??
                    Text("No widget available for ${l.deviceType}"),
              ),
            )
            .toList(),
      ),
    );
  }
}

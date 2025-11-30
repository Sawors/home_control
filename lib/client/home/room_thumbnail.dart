import 'package:flutter/material.dart';
import 'package:home_control/devices/home.dart';

class RoomThumbnail extends StatelessWidget {
  final Room room;
  const RoomThumbnail(this.room, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(room.name, style: theme.textTheme.titleLarge),
        Expanded(child: Center(child: Text(room.devices.length.toString()))),
      ],
    );
  }
}

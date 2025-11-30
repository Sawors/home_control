import 'package:flutter/material.dart';
import 'package:home_control/client/home/home_container_page.dart';
import 'package:home_control/client/home/room_thumbnail.dart';
import 'package:home_control/client/home/room_widget.dart';

import '../../devices/home.dart';

class HomeThumbnailWidget extends StatelessWidget {
  final Home home;
  const HomeThumbnailWidget(this.home, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      spacing: 20,
      children: [
        Text(home.name, style: theme.textTheme.displaySmall),
        Expanded(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: home.rooms
                .map(
                  (r) => MaterialButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        width: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              HomeContainerPage(home, child: RoomWidget(r)),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 500,
                      height: 250,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: RoomThumbnail(r),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

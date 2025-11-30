import 'package:flutter/material.dart';

import '../../devices/home.dart';

class HomeContainerPage extends StatelessWidget {
  final Widget child;
  final Home home;
  const HomeContainerPage(this.home, {super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(home.name)),

      body: child,
    );
  }
}

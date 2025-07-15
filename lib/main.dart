import 'package:flutter/material.dart';
import 'package:home_control/light_bulb.dart';

import 'light_control_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Control',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const MyHomePage(title: 'Home Control'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final client = TapoClient(
    username: "sawors@proton.me",
    password: "#tEJ6@cXuB5NP!*us4WS",
  );
  final List<LightBulb> lights = [];

  @override
  void initState() {
    lights.addAll([
      LightBulb(ip: "192.168.1.36", name: "Plafond", client: client),
      LightBulb(ip: "192.168.1.37", name: "Chevet", client: client),
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: lights
                .map(
                  (l) => SizedBox(
                    width: 200,
                    height: 330,
                    child: LightControlWidget(light: l),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

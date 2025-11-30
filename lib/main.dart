import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_control/client/devices/device_widget_mapper.dart';
import 'package:home_control/client/home/home_thumbnail_widget.dart';
import 'package:home_control/common/config.dart';
import 'package:home_control/devices/devices.dart';
import 'package:home_control/devices/home.dart';
import 'package:home_control/devices/lights/light_bulb.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

import 'common/cache.dart';
import 'common/local_files.dart';

final List<String> availableHomes = ["appart-lausanne-0"];
final accessKey = "sawors";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Map<String, Directory> platformDirMap = {};
  if (Platform.isAndroid) {
    platformDirMap["android-cache"] = await getApplicationCacheDirectory();
    platformDirMap["android-userdata"] =
        await getApplicationDocumentsDirectory();
    platformDirMap["android-data"] = await getApplicationSupportDirectory();
  }
  await LocalFiles.initializeDirectories(
    server: false,
    deviceAsyncDirMap: platformDirMap,
  );
  await CacheManager.initialize();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await ProgramConfig.loadConfigFromFile(File(LocalFiles().configFilePath));
  } else {
    ProgramConfig.configData.addAll(ProgramConfig().defaultConfig);
  }
  final server = Uri.parse(ProgramConfig.configData["server"]);
  HomeDevice.loadBundledDevices(server: server);
  HomeDeviceWidget.loadBundledDevices();

  // await for (FileSystemEntity f in LocalFiles().homeStoreDir.list(
  //   recursive: false,
  // )) {
  //   if (!await FileSystemEntity.isDirectory(f.path)) {
  //     continue;
  //   }
  //   final dir = Directory(f.path);
  //   try {
  //     // Wasting resources here, but it should save lots of memory in the long run.
  //     final home = await Home.fromDirectory(dir, server);
  //     availableHomes.add(home);
  //     stdout.writeln(
  //       "Loaded home \"${home.name}\" from ${dir.uri.pathSegments.sublist(dir.uri.pathSegments.length - 3, dir.uri.pathSegments.length - 1).join("/")}",
  //     );
  //   } catch (e) {
  //     stderr.writeln(
  //       "Errors while loading home ${dir.uri.pathSegments.last} : $e",
  //     );
  //   }
  // }
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
  // final client = TapoClient(
  //   username: "sawors@proton.me",
  //   password: "#tEJ6@cXuB5NP!*us4WS",
  // );
  final List<LightBulb> lights = [];

  @override
  void initState() {
    lights.addAll([]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final server = Uri.parse(ProgramConfig.configData["server"]);
    print(server.toString());
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: availableHomes
                .map(
                  (l) => FutureBuilder(
                    future: get(
                      Uri.parse(
                        "${server.toString()}/api/homes/$l?action=get-deep-status",
                      ),
                      headers: {"HC-Access-Key": accessKey},
                    ),
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      if (data == null) {
                        return SizedBox(
                          width: 500,
                          height: 400,
                          child: Center(
                            child: SizedBox.square(
                              dimension: 100,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }
                      Map<String, dynamic> jsonData = jsonDecode(data.body);
                      final Home home = Home.fromFullJson(
                        jsonData,
                        server: server,
                      );
                      return SizedBox(
                        width: 500,
                        height: 400,
                        child: HomeThumbnailWidget(home),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

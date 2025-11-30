import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:home_control/common/cache.dart';
import 'package:home_control/server/access_key.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../common/config.dart';
import '../common/local_files.dart';
import '../devices/devices.dart';
import '../devices/home.dart';

//
// CONFIG
//
const serverFallbackPort = 4145;
const accessKeyHardLimit = 100;
//
// CONFIG END
//
final Map<String, Home> homeCache = {};
final Map<String, HomeDevice> deviceCache = {};

void main(List<String> args) async {
  final Map<String, String?> progArgs = Map.fromEntries(
    args.map((v) {
      final split = v.split("=");
      return MapEntry(split[0], split.elementAtOrNull(1));
    }),
  );
  await LocalFiles.initializeDirectories(server: true);
  await CacheManager.initialize();
  await ProgramConfig.loadConfigFromFile(
    File(LocalFiles().serverConfigFilePath),
  );
  var handler = const Pipeline()
      .addMiddleware(logRequests())
      //.addMiddleware(fixCors)
      .addHandler((req) => entryPoint(req));
  var server = await shelf_io.serve(
    handler,
    '127.0.0.1',
    int.tryParse(
          progArgs["--port"] ??
              ProgramConfig.configData["port"]?.toString() ??
              "",
        ) ??
        serverFallbackPort,
  );
  // Enable content compression
  server.autoCompress = true;
  final serverUri = Uri.parse(
    ProgramConfig.configData["binding-address"] ?? "https://localhost",
  );

  HomeDevice.loadBundledDevices(server: serverUri);
  await for (FileSystemEntity f in LocalFiles().homeStoreDir.list(
    recursive: false,
  )) {
    if (!await FileSystemEntity.isDirectory(f.path)) {
      continue;
    }
    final dir = Directory(f.path);
    try {
      // Wasting resources here, but it should save lots of memory in the long run.
      final home = await Home.fromDirectory(dir, serverUri);
      homeCache[home.id] = home;
      stdout.writeln(
        "Loaded home \"${home.name}\" from ${dir.uri.pathSegments.sublist(dir.uri.pathSegments.length - 3, dir.uri.pathSegments.length - 1).join("/")}",
      );
    } catch (e) {
      rethrow;
      stderr.writeln(
        "Errors while loading home ${dir.uri.pathSegments.last} : $e",
      );
    }
  }

  // CORS bullshit
  //for OPTIONS (preflight) requests just add headers and an empty response
  /*final Map<String, String> headers = {
    'Access-Control-Allow-Origin': '*',
    'Content-Type': 'text/html',
    'Access-Control-Allow-Headers': 'authorization',
  };

  Response? options(Request request) => (request.method == 'OPTIONS')
      ? Response.ok(null, headers: headers)
      : null;

  Response cors(Response response) => response.change(
    headers: Map.fromEntries([
      ...headers.entries, ...response.headers.entries,
    ]),
  );

  Middleware fixCors = createMiddleware(
    requestHandler: options,
    responseHandler: cors,
  );*/

  stdout.writeln('Serving at https://${server.address.host}:${server.port}');
}

FutureOr<Response> entryPoint(Request request) async {
  // https://localhost:port/api/homes/<home-id>
  final List<String> path = request.requestedUri.normalizePath().pathSegments;
  if (path[0] != "api") {
    return Response.notFound("Path not found");
  }
  if (path[1] == "homes") {
    return handleHomeRequest(request);
  }
  return Response.notFound("Action not found");
}

FutureOr<Response> handleHomeRequest(Request request) async {
  final pathSegments = request.requestedUri.normalizePath().pathSegments;
  final List<String> accessKeys = request.headersAll["hc-access-key"] ?? [];
  if (accessKeys.length > accessKeyHardLimit) {
    return Response.forbidden(
      "There is a limit of maximum 100 keys per request.",
    );
  }
  final Set<String> accessScope = {};
  // may be used later
  //final String? userId = request.headers["HC-User-Id"];
  final String action =
      request.requestedUri.queryParameters["action"] ?? "get-info";
  final Response forbiddenResponse = Response.forbidden(
    "You cannot perform this action with the given access keys.",
  );
  final String? homeId = pathSegments.elementAtOrNull(2);
  final String? roomId = request.requestedUri.queryParameters["room-id"];
  if (homeId == null) {
    return Response.badRequest(
      body: "Please at least give a home id to look for.",
    );
  }
  final Home? home = homeCache[homeId];
  if (home == null) {
    return Response.notFound("Home has not been found.");
  }
  // start of actual operations

  for (String rawKey in accessKeys) {
    final String hash = sha256.convert(rawKey.codeUnits).toString();
    final AccessCredentials? matching = home.keyring.userAccessKeys[hash];
    if (matching != null) {
      accessScope.addAll(matching.accessScope);
    }
  }
  if (accessScope.isEmpty) {
    return Response.forbidden("No access has been found with the given keys");
  }
  final Room? room = roomId != null ? home.getRoom(roomId) : null;

  if (roomId != null) {
    if (room == null) {
      return Response.badRequest(body: "No room found with the given id.");
    }
    //
    // ROOM ONLY ACTIONS
    //
    switch (action) {
      case "get-room-info":
        if (!AccessScopeChecker.hasRoomReadAccess(
          room: room,
          possessedScopes: accessScope,
        )) {
          return forbiddenResponse;
        }
        //
        final result = room.toJsonMap();
        return Response.ok(jsonEncode(result));
      case "get-room-devices-state":
        final fullAccess = AccessScopeChecker.hasRoomReadAccess(
          room: room,
          possessedScopes: accessScope,
        );
        if (!fullAccess) {
          return forbiddenResponse;
        }
        final List<String> deviceIds =
            request.requestedUri.queryParametersAll["device"] ?? [];
        final Map<String, dynamic> result = {};
        for (String device in deviceIds) {
          final resolvedDevice = room.getDevice(device);
          if (resolvedDevice != null &&
              (fullAccess ||
                  accessScope.contains("device-query:${resolvedDevice.id}") ||
                  AccessKeyManager.hasDeviceTypeAccess(
                    resolvedDevice.deviceType,
                    accessScope,
                  ).$1)) {
            result[device] = resolvedDevice.toJsonMap();
          } else {
            result[device] = null;
          }
        }
        return Response.ok(jsonEncode(result));
    }
  }

  // room agnostic actions, but room can still be useful (mainly devices)
  switch (action) {
    case "get-home-info":
      if (!AccessScopeChecker.hasHomeReadAccess(possessedScopes: accessScope)) {
        return forbiddenResponse;
      }
      return Response.ok(jsonEncode(home.toJsonMap()));
    case "get-deep-status":
      // permission check
      if (!accessScope.contains("home-deep-query") &&
          !AccessScopeChecker.hasAdminAccess(accessScope) &&
          !AccessScopeChecker.hasHomeReadAccess(possessedScopes: accessScope)) {
        return forbiddenResponse;
      }
      //
      final List<Map<String, dynamic>> devices = [];
      final List<Map<String, dynamic>> rooms = [];
      for (Room r in home.rooms) {
        rooms.add(r.toJsonMap());
        for (HomeDevice d in r.devices) {
          devices.add(d.toJsonMap());
        }

        return Response.ok(
          jsonEncode({
            "home": home.toJsonMap(includeKeyring: true),
            "rooms": rooms,
            "devices": devices,
          }),
        );
      }

    case "send-device-command":
      // accept a body like that :
      // {
      //   "device-id-1": ["command-arg-1", "command-arg-2", ...],
      //   "device-id-2": ["command-arg-1", "command-arg-2", ...]
      //    ...
      // }
      final Map<String, dynamic> body = jsonDecode(
        await request.readAsString(),
      );
      final Iterable<String> deviceIds = body.keys;
      final Map<String, dynamic> result = {};
      for (String device in deviceIds) {
        final HomeDevice? cachedDevice = deviceCache[device];
        HomeDevice? resolvedDevice;
        if (cachedDevice != null) {
          resolvedDevice = cachedDevice;
        } else {
          if (room != null) {
            resolvedDevice = room.getDevice(device);
          } else {
            for (Room r in home.rooms) {
              final d = r.getDevice(device);
              if (d != null) {
                resolvedDevice = d;
                break;
              }
            }
          }
          if (resolvedDevice != null) {
            deviceCache[device] = resolvedDevice;
          }
        }
        if (resolvedDevice != null &&
            AccessScopeChecker.hasDeviceWriteAccess(
              device: resolvedDevice,
              room: room,
              home: home,
              possessedScopes: accessScope,
            )) {
          final rawCommand = body[device];
          final List<String> command = rawCommand is String
              ? [rawCommand]
              : (rawCommand as List<dynamic>).map((t) => t.toString()).toList();
          result[device] = await resolvedDevice.acceptCommand(
            command,
            resolvedDevice.adapter,
          );
        } else {
          result[device] = null;
        }
      }
      return Response.ok(jsonEncode(result));
    case "get-device-state":
      final List<String> body =
          (jsonDecode(await request.readAsString()) as List<dynamic>)
              .map((s) => s.toString())
              .toList();
      final states = await Future.wait(
        body.map((deviceId) {
          final HomeDevice? cachedDevice = deviceCache[deviceId];
          HomeDevice? resolvedDevice;
          if (cachedDevice != null) {
            resolvedDevice = cachedDevice;
          } else {
            if (room != null) {
              resolvedDevice = room.getDevice(deviceId);
            } else {
              for (Room r in home.rooms) {
                final d = r.getDevice(deviceId);
                if (d != null) {
                  resolvedDevice = d;
                  break;
                }
              }
            }
            if (resolvedDevice != null) {
              deviceCache[deviceId] = resolvedDevice;
            }
          }
          if (resolvedDevice == null) {
            return Future.value((deviceId, null));
          }
          return resolvedDevice.getState().then((r) => (deviceId, r));
        }),
      );
      return Response.ok(
        jsonEncode(Map.fromEntries(states.map((s) => MapEntry(s.$1, s.$2)))),
      );
  }

  return Response.badRequest(body: "Unknown Error");
}

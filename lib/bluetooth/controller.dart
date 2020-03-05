import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:joycon/bluetooth/bluetooth.dart';

class Controller {
  static const MethodChannel _controllerChannel =
      const MethodChannel('com.mumumusuc.libjoycon/controller');
  static SendPort sendPort;
  final BluetoothDevice device;

  static init() async {
    if (sendPort == null) {
      /*
      final ReceivePort response = ReceivePort();
      await Isolate.spawn(_background, response.sendPort);
      print('waiting for background reply');
      sendPort = await response.first;
      print('background replied');
       */
    }
  }

  const Controller._(this.device);

  factory Controller(BluetoothDevice device) {
    return Controller._(device).._create(device);
  }

  DeviceCategory get category => device.category;

  static void _background(SendPort reply) async {
    WidgetsFlutterBinding.ensureInitialized();
    MethodChannel channel =
        const MethodChannel('com.mumumusuc.libjoycon/controller');
    final ReceivePort port = ReceivePort();
    print('background reply port');
    reply.send(port.sendPort);
    await for (var msg in port) {
      final callback = msg[0] as SendPort;
      final method = msg[1] as String;
      final args = msg[2] as Map<dynamic, dynamic>;
      channel.invokeMethod(method, args).then(
            (value) => callback.send(value),
          );
    }
  }

  static Future<T> _invoke<T>(String method, Map<dynamic, dynamic> args) {
    /*
    final ReceivePort answer = ReceivePort();
    sendPort.send([answer.sendPort, method, args]);
    return answer.first.then((value) => value as T);
     */
    return _controllerChannel
        .invokeMethod(method, args)
        .then((v) => v as T)
        .catchError((e) {
      Fluttertoast.showToast(
        msg: '${e}',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    });
  }

  @override
  bool operator ==(other) {
    if (runtimeType != other.runtimeType) return false;
    return device == other.device;
  }

  @override
  int get hashCode => device.hashCode;

  void dispose() {
    _destroy(device);
  }

  void _create(BluetoothDevice device) {
    _invoke<String>('create', {'address': device.address}).then((value) {
      assert(value == device.address);
    });
  }

  void _destroy(BluetoothDevice device) {
    _invoke('destroy', {'address': device.address}).then((value) {
      assert(value == device.address);
    });
  }

  Future<int> setPlayer(int player, int flash) {
    return _invoke<int>(
      'setPlayer',
      {
        'address': device.address,
        'player': player,
        'flash': flash,
      },
    );
  }

  Future<int> setHomeLight(HomeLightPattern pattern) {
    return _invoke<int>(
      'setHomeLight',
      {
        'address': device.address,
        'intensity': pattern.intensity,
        'duration': pattern.duration,
        'repeat': pattern.repeat,
        'cycles': pattern.cycles
            .expand((e) => [e.intensity, e.fade, e.keep])
            .toList(),
      },
    );
  }

  Future<int> enableRumble(bool enable) {
    return _invoke<int>(
      'enableRumble',
      {
        'address': device.address,
        'enable': enable,
      },
    );
  }

  Future<int> rumble(List<int> data) {
    return _invoke<int>(
      'rumble',
      {
        'address': device.address,
        'data': data,
      },
    );
  }

  Future<int> rumblef(List<double> data) {
    return _invoke<int>(
      'rumblef',
      {
        'address': device.address,
        'data': data,
      },
    );
  }

  Future<int> setColor(
      Color body, Color button, Color leftGrip, Color rightGrip) {
    return _invoke<int>(
      'setColor',
      {
        'address': device.address,
        'body': body.value,
        'button': button.value,
        'left_grip': leftGrip.value,
        'right_grip': rightGrip.value,
      },
    );
  }
}

class HomeLightCycle {
  final int intensity;
  final int fade;
  final int keep;

  const HomeLightCycle({
    @required this.intensity,
    @required this.fade,
    @required this.keep,
  });

  static HomeLightCycle get zero =>
      HomeLightCycle(intensity: 0, fade: 0, keep: 0);

  HomeLightCycle copyWith({
    int intensity,
    int fade,
    int keep,
  }) {
    return HomeLightCycle(
      intensity: intensity ?? this.intensity,
      fade: fade ?? this.fade,
      keep: keep ?? this.keep,
    );
  }
}

class HomeLightPattern {
  final String name;
  final int intensity;
  final int duration;
  final int repeat;
  final List<HomeLightCycle> cycles;

  const HomeLightPattern({
    this.name,
    @required this.intensity,
    @required this.duration,
    @required this.repeat,
    @required this.cycles,
  });

  HomeLightPattern copyWith({
    String name,
    int intensity,
    int duration,
    int repeat,
    List<HomeLightCycle> cycles,
  }) {
    return HomeLightPattern(
      name: name ?? this.name,
      intensity: intensity ?? this.intensity,
      duration: duration ?? this.duration,
      repeat: repeat ?? this.repeat,
      cycles: cycles ?? this.cycles,
    );
  }
}

import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:joycon/bluetooth/bluetooth.dart';
import 'package:joycon/bluetooth/controller.dart';
import 'package:joycon/option/config.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

class Bloc with BluetoothCallbackMixin {
  final Bluetooth bluetooth = Bluetooth();
  final _BluetoothDeviceNotifier _devices = _BluetoothDeviceNotifier();
  final ValueNotifier<BluetoothState> _adapter =
      ValueNotifier(BluetoothState.UNKNOWN);

  BluetoothDeviceMap get map => _devices.value;

  static Bloc of(BuildContext context) =>
      Provider.of<Bloc>(context, listen: false);

  Bloc._() {
    bluetooth.addListener(this);
    bluetooth.getAdapterState().then((value) {
      _adapter.value = value;
      if (value == BluetoothState.ENABLED) {
        _fetchDeviceState();
      }
    });
    // test
    _devices.append(
      Map.fromIterable(
        List.generate(
          3,
          (i) => BluetoothDevice(
            name: DeviceCategory.names[i],
            address: '00:11:22:33:$i$i:55',
          ),
        ),
        key: (it) => it,
        value: (it) => BluetoothDeviceMeta(
          state: BluetoothDeviceState.PAIRED,
        ),
      ),
      notify: false,
    );
    _devices.append(
      Map.fromIterable(
        List.generate(
          3,
          (i) => BluetoothDevice(
            name: DeviceCategory.names[i],
            address: '00:11:22:33:44:$i$i',
          ),
        ),
        key: (it) => it,
        value: (it) => BluetoothDeviceMeta(
          state: BluetoothDeviceState.CONNECTED,
        ),
      ),
      notify: false,
    );
  }

  void _fetchDeviceState() {
    bluetooth.getPairedDevices().then((v) {
      // print('getPairedDevices -> ${v.length}');
      _devices.append(
        Map.fromIterable(
          v,
          key: (it) => it,
          value: (it) => BluetoothDeviceMeta(
            state: BluetoothDeviceState.PAIRED,
          ),
        ),
        notify: false,
      );
    }).then((v) {
      return bluetooth.getConnectedDevices().then((v) {
        //  print('getConnectedDevices -> ${v.length}');
        _devices.update(
          Map.fromIterable(
            v,
            key: (it) => it,
            value: (it) => BluetoothDeviceMeta(
              state: BluetoothDeviceState.CONNECTED,
            ),
          ),
          notify: false,
        );
      });
    }).then((_) => _devices._notify());
  }

  static List<SingleChildWidget> get providers => [
        Provider<Bloc>(create: (_) => Bloc._(), dispose: (_, v) => v.dispose()),
        ValueListenableProvider(create: (c) => Bloc.of(c)._devices),
        ValueListenableProvider(create: (c) => Bloc.of(c)._adapter),
        ListenableProvider.value(value: defaultConfig),
      ];

  void dispose() {
    bluetooth.removeListener(this);
    _adapter.dispose();
    _devices.dispose();
  }

  @override
  void onAdapterStateChanged(BluetoothState state) {
    _adapter.value = state;
    print(state);
    if (state == BluetoothState.ENABLED) {
      _fetchDeviceState();
    }
  }

  @override
  void onDeviceStateChanged(
      BluetoothDevice device, BluetoothDeviceState state) {
    if (state == BluetoothDeviceState.FOUND)
      _devices.append({device: BluetoothDeviceMeta(state: state)});
    else
      _devices.update({device: BluetoothDeviceMeta(state: state)});
  }
}

class BluetoothDeviceMeta {
  final BluetoothDeviceState state;
  final Controller controller;

  BluetoothDeviceMeta({this.state, this.controller});

  BluetoothDeviceMeta copyWith({
    BluetoothDeviceState state,
    Controller controller,
  }) {
    return BluetoothDeviceMeta(
      state: state ?? this.state,
      controller: controller,
    );
  }

  @override
  bool operator ==(other) {
    if (runtimeType != other.runtimeType) return false;
    return state == other.state && controller == other.controller;
  }

  @override
  int get hashCode => hashValues(state, controller);

  static BluetoothDeviceMeta of(BuildContext context, BluetoothDevice device) =>
      BluetoothDeviceMap.of(context)[device];
}

class BluetoothDeviceMap {
  final ValueKey<int> key;
  final Map<BluetoothDevice, BluetoothDeviceMeta> _data;

  BluetoothDeviceMap({
    @required this.key,
    Map<BluetoothDevice, BluetoothDeviceMeta> data,
  }) : _data = data ?? LinkedHashMap();

  BluetoothDeviceMap copyWith(
      {@required Key key, Map<BluetoothDevice, BluetoothDeviceMeta> data}) {
    return BluetoothDeviceMap(
      key: key,
      data: data ?? _data,
    );
  }

  Iterable<MapEntry<BluetoothDevice, BluetoothDeviceMeta>> get devices =>
      _data.entries;

  BluetoothDeviceMeta operator [](dynamic device) {
    if (device is int) {
      return devices.elementAt(device).value;
    }
    if (device is BluetoothDevice) {
      return _data[device];
    }
    throw FormatException('Unsupported paramater type ${device.runtimeType}');
  }

  bool _append(Map<BluetoothDevice, BluetoothDeviceMeta> data) {
    if (data.isEmpty) return false;
    // DO *NOT* use any(), it is too lazy!
    return data.entries.map<bool>((e) {
      if (_data.containsKey(e.key)) return false;
      _data[e.key] = e.value;
      return true;
    }).reduce((v, e) => v & e);
  }

  bool _update(Map<BluetoothDevice, BluetoothDeviceMeta> data) {
    if (data.isEmpty) return false;
    return data.entries.map((e) {
      if (_data.containsKey(e.key) && _data[e.key] != e.value) {
        _data[e.key] = e.value;
        return true;
      }
      return false;
    }).reduce((v, e) => v & e);
  }

  bool _remove(BluetoothDevice device) {
    if (_data.isEmpty) return false;
    if (_data.containsKey(device)) {
      _data.remove(device);
      return true;
    }
    return false;
  }

  static BluetoothDeviceMap of(BuildContext context) =>
      Provider.of<BluetoothDeviceMap>(context, listen: false);
}

class _BluetoothDeviceNotifier extends ChangeNotifier
    implements ValueNotifier<BluetoothDeviceMap> {
  BluetoothDeviceMap value = BluetoothDeviceMap(key: ValueKey(0));

  void update(Map<BluetoothDevice, BluetoothDeviceMeta> devices,
      {bool notify = true}) {
    final data = value.copyWith(key: ValueKey(value.key.value + 1));
    if (data._update(devices)) {
      value = data;
      if (notify) notifyListeners();
    }
  }

  void append(Map<BluetoothDevice, BluetoothDeviceMeta> devices,
      {bool notify = true}) {
    final data = value.copyWith(key: ValueKey(value.key.value + 1));
    if (data._append(devices)) {
      value = data;
      if (notify) notifyListeners();
    }
  }

  void remove(BluetoothDevice device, {bool notify = true}) {
    final data = value.copyWith(key: ValueKey(value.key.value + 1));
    if (data._remove(device)) {
      value = data;
      if (notify) notifyListeners();
    }
  }

  void _notify() {
    notifyListeners();
  }
}
/*
String selectDeviceIcon(BluetoothDevice device) {
  switch (device.category) {
    case DeviceCategory.ProController:
      return 'assets/image/pro_controller_icon.png';
    case DeviceCategory.JoyCon_L:
      return 'assets/image/joycon_l_icon.png';
    case DeviceCategory.JoyCon_R:
      return 'assets/image/joycon_r_icon.png';
    case DeviceCategory.JoyCon_Dual:
      return 'assets/image/joycon_d_icon.png';
    default:
      throw ArgumentError.value(device.name);
  }
}
 */

Widget getDeviceIcon(BluetoothDevice device, {Size size, Color color}) {
  switch (device.category) {
    case DeviceCategory.ProController:
      return Image.asset(
        'assets/image/pro_controller_icon.png',
        width: size?.width,
        height: size?.height,
        color: color,
      );
    case DeviceCategory.JoyCon_L:
      return Image.asset(
        'assets/image/joycon_l_icon.png',
        width: size?.width,
        height: size?.height,
        color: color,
      );
    case DeviceCategory.JoyCon_R:
      return Image.asset(
        'assets/image/joycon_r_icon.png',
        width: size?.width,
        height: size?.height,
        color: color,
      );
    case DeviceCategory.JoyCon_Dual:
      return Image.asset(
        'assets/image/joycon_d_icon.png',
        width: size?.width,
        height: size?.height,
        color: color,
      );
    default:
      throw ArgumentError.value(device.name);
  }
}

//
const double kPageMaxWidth = 500;
const BoxConstraints kPageConstraint = BoxConstraints(maxWidth: kPageMaxWidth);
const Duration kDuration = const Duration(milliseconds: 400);
const Color kDividerColor = const Color(0x07444444);
const BorderSide kDividerBorderSide =
    const BorderSide(color: kDividerColor, width: 0);

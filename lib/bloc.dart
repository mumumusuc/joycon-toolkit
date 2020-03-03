import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:joycon/bluetooth/bluetooth.dart';
import 'package:joycon/bluetooth/controller.dart';
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
      if (value == BluetoothState.ENABLED) {
        _fetchDeviceState();
      }
    });
  }

  void _fetchDeviceState() {
    Future.wait([
      bluetooth.getPairedDevices().then((v) {
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
      }),
      bluetooth.getConnectedDevices().then((v) {
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
      }),
    ]).then((_) => _devices._notify());
  }

  static List<SingleChildWidget> get providers => [
        Provider<Bloc>(create: (_) => Bloc._(), dispose: (_, v) => v.dispose()),
        ValueListenableProvider(create: (c) => Bloc.of(c)._devices),
        ValueListenableProvider(create: (c) => Bloc.of(c)._adapter),
      ];

  void dispose() {
    bluetooth.removeListener(this);
    _adapter.dispose();
    _devices.dispose();
  }

  @override
  void onAdapterStateChanged(BluetoothState state) {
    _adapter.value = state;
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

  BluetoothDeviceMeta operator [](BluetoothDevice device) {
    return _data[device];
  }

  bool _append(Map<BluetoothDevice, BluetoothDeviceMeta> data) {
    return data.entries.map((e) {
      if (_data.containsKey(e.key)) return false;
      _data[e.key] = e.value;
      return true;
    }).any((e) => e);
  }

  bool _update(Map<BluetoothDevice, BluetoothDeviceMeta> data) {
    return data.entries.map((e) {
      if (_data.containsKey(e.key) && _data[e.key] != e.value) {
        _data[e.key] = e.value;
        return true;
      }
      return false;
    }).any((e) => e);
  }

  bool _remove(BluetoothDevice device) {
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

String selectDeviceIcon(BluetoothDevice device) {
  switch (device.name) {
    case 'Pro Controller':
      return 'assets/image/pro_controller.png';
    case 'Joy-Con (L)':
      return 'assets/image/joycon_l.png';
    case 'Joy-Con (R)':
      return 'assets/image/joycon_r.png';
    default:
      throw ArgumentError.value(device.name);
  }
}

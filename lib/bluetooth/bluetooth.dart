import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum BluetoothState {
  UNKNOWN,
  ENABLED,
  TURNING_ON,
  DISABLED,
  TURNING_OFF,
  DISCOVER_OFF,
  DISCOVER_ON,
}

enum BluetoothDeviceState {
  UNKNOWN,
  NONE,
  FOUND,
  UNPAIRED,
  PAIRING,
  PAIRED,
  DISCONNECTING,
  DISCONNECTED,
  CONNECTING,
  CONNECTED,
}

typedef _OnAdapterStateChanged = void Function(BluetoothState state);
typedef _OnDeviceStateChanged = void Function(
    BluetoothDevice device, BluetoothDeviceState state);

mixin BluetoothCallbackMixin {
  void onAdapterStateChanged(BluetoothState state);

  void onDeviceStateChanged(BluetoothDevice device, BluetoothDeviceState state);
}

class BluetoothCallback with BluetoothCallbackMixin {
  final _OnAdapterStateChanged _onAdapterStateChanged;
  final _OnDeviceStateChanged _onDeviceStateChanged;

  const BluetoothCallback({
    _OnAdapterStateChanged onAdapterStateChanged,
    _OnDeviceStateChanged onDeviceStateChanged,
  })  : _onAdapterStateChanged = onAdapterStateChanged,
        _onDeviceStateChanged = onDeviceStateChanged;

  @override
  void onAdapterStateChanged(BluetoothState state) {
    _onAdapterStateChanged?.call(state);
  }

  @override
  void onDeviceStateChanged(
      BluetoothDevice device, BluetoothDeviceState state) {
    _onDeviceStateChanged?.call(device, state);
  }
}

class BluetoothDevice {
  final String name;
  final String address;

  const BluetoothDevice({this.name, this.address});

  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> data) {
    return BluetoothDevice(name: data["name"], address: data["address"]);
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != this.runtimeType) return false;
    final BluetoothDevice _other = other;
    return name == _other.name && address == _other.address;
  }

  @override
  int get hashCode => hashValues(name, address);

  @override
  String toString() => 'BluetoothDevice:{$name, $address}';

  Map<String, dynamic> toMap() => {'name': name, 'address': address};
}

class Bluetooth {
  // none
  static const int _STATE_NONE = 0;

  // adapter state
  static const int _STATE_OFF = 10;
  static const int _STATE_TURNING_ON = 11;
  static const int _STATE_ON = 12;
  static const int _STATE_TURNING_OFF = 13;
  static const int _STATE_DISCOVERY_OFF = 14;
  static const int _STATE_DISCOVERY_ON = 15;

  // device mask
  static const int _STATE_DEVICE_MASK = 0x10;

  // device connect state
  static const int _STATE_DISCONNECTED = 0;
  static const int _STATE_CONNECTING = 1;
  static const int _STATE_CONNECTED = 2;
  static const int _STATE_DISCONNECTING = 3;

  // device found
  static const int _STATE_FOUND_DEVICE = 4;

  // device bond state
  static const int _STATE_UNBOND = 10;
  static const int _STATE_BONDING = 11;
  static const int _STATE_BONDED = 12;
  static const String _ROOT = 'com.mumumusuc.libjoycon';
  static const String _CHAN_BT = '$_ROOT/bluetooth';
  static const String _CHAN_BT_STATE = '$_ROOT/bluetooth/state';
  static final Bluetooth _instance = Bluetooth._();

  final MethodChannel _mc_bt = const MethodChannel(_CHAN_BT);
  final BasicMessageChannel<dynamic> _mc_bt_state =
      const BasicMessageChannel(_CHAN_BT_STATE, const StandardMessageCodec());
  final Set<BluetoothCallbackMixin> callbacks = Set();

  int state = _STATE_NONE;

  Bluetooth._() {
    _mc_bt_state.setMessageHandler(handler);
  }

  factory Bluetooth() => _instance;

  void addListener(BluetoothCallbackMixin cb) {
    if (cb == null) return;
    callbacks.add(cb);
  }

  void removeListener(BluetoothCallbackMixin cb) {
    if (cb == null) return;
    callbacks.remove(cb);
  }

  Future<dynamic> handler(dynamic msg) async {
    if (callbacks.isEmpty) return null;
    if (msg is Map) {
      int state = msg['state'];
      print('bt state = $state');
      if ((state & _STATE_DEVICE_MASK) == 0) {
        callbacks.forEach(
            (it) => it.onAdapterStateChanged(_parseAdapterState(state)));
      } else {
        state = state & (~_STATE_DEVICE_MASK);
        final BluetoothDevice device = BluetoothDevice.fromMap(msg);
        switch (state) {
          case _STATE_DISCONNECTED:
            final BluetoothDeviceState _state = await getDeviceState(device);
            callbacks.forEach((it) => it.onDeviceStateChanged(device, _state));
            break;
          case _STATE_UNBOND:
          case _STATE_BONDING:
          case _STATE_BONDED:
            if (this.state == _STATE_DISCONNECTED ||
                this.state == _STATE_NONE) {
              callbacks.forEach((it) =>
                  it.onDeviceStateChanged(device, _parseDeviceState(state)));
            }
            break;
          default:
            callbacks.forEach((it) =>
                it.onDeviceStateChanged(device, _parseDeviceState(state)));
            break;
        }
      }
      this.state = state;
    }
    return null;
  }

  void enable(bool on) {
    _mc_bt.invokeMethod('enable', {'on': on});
  }

  void discovery(bool on) {
    _mc_bt.invokeMethod('discovery', {'on': on}).catchError((e) {
      Fluttertoast.showToast(
        msg: e.message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIos: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    });
  }

  void pair(BluetoothDevice dev) {
    _mc_bt.invokeMethod('pair', {'address': dev.address});
  }

  void connect(BluetoothDevice dev, bool on) {
    _mc_bt.invokeMethod('connect', {'address': dev.address, 'on': on});
  }

  Future<BluetoothState> getAdapterState() {
    return _mc_bt
        .invokeMethod('getAdapterState')
        .then((value) => _parseAdapterState(value));
  }

  Future<BluetoothDeviceState> getDeviceState(BluetoothDevice dev) {
    return _mc_bt.invokeMethod('getDeviceState', {'address': dev.address}).then(
        (value) => _parseDeviceState(value, mask: true));
  }

  Future<Set<BluetoothDevice>> getPairedDevices() {
    return _mc_bt
        .invokeMethod<List<dynamic>>('getPairedDevices')
        .then<Set<BluetoothDevice>>((data) {
      return data.map((it) => BluetoothDevice.fromMap(it)).toSet();
    });
  }

  Future<Set<BluetoothDevice>> getConnectedDevices() {
    return _mc_bt
        .invokeMethod<List<dynamic>>('getConnectedDevices')
        .then<Set<BluetoothDevice>>((data) {
      return data.map((it) => BluetoothDevice.fromMap(it)).toSet();
    });
  }

  static BluetoothState _parseAdapterState(int state) {
    switch (state) {
      case _STATE_OFF:
        return BluetoothState.DISABLED;
      case _STATE_TURNING_ON:
        return BluetoothState.TURNING_ON;
      case _STATE_ON:
        return BluetoothState.ENABLED;
      case _STATE_TURNING_OFF:
        return BluetoothState.TURNING_OFF;
      case _STATE_DISCOVERY_OFF:
        return BluetoothState.DISCOVER_OFF;
      case _STATE_DISCOVERY_ON:
        return BluetoothState.DISCOVER_ON;
      default:
        throw FormatException('unkown adapter state : $state');
    }
  }

  static BluetoothDeviceState _parseDeviceState(int state,
      {bool mask = false}) {
    if (mask) state = state & (~_STATE_DEVICE_MASK);
    switch (state) {
      case _STATE_DISCONNECTED:
        return BluetoothDeviceState.DISCONNECTED;
      case _STATE_CONNECTING:
        return BluetoothDeviceState.CONNECTING;
      case _STATE_CONNECTED:
        return BluetoothDeviceState.CONNECTED;
      case _STATE_DISCONNECTING:
        return BluetoothDeviceState.DISCONNECTING;
      case _STATE_FOUND_DEVICE:
        return BluetoothDeviceState.FOUND;
      case _STATE_UNBOND:
        return BluetoothDeviceState.UNPAIRED;
      case _STATE_BONDING:
        return BluetoothDeviceState.PAIRING;
      case _STATE_BONDED:
        return BluetoothDeviceState.PAIRED;
      default:
        throw FormatException('unkown adapter state : $state');
    }
  }

/*
  static dynamic _remote2LocalState(int state) {
    return _local_states[_remote_states.indexOf(state)];
  }

  static int _local2remoteState(dynamic state) {
    return _remote_states[_local_states.indexOf(state)];
  }

  // test
  void testBluetoothAdapter(BluetoothState state) {
    handler({'state': _local2remoteState(state)});
  }

  void testBluetoothDevice(BluetoothDevice device, BluetoothDeviceState state) {
    handler({
      'name': device?.name,
      'address': device?.address,
      'state': _local2remoteState(state)
    });
  }

  Future<BluetoothDeviceState> testGetDeviceState(
      BluetoothDevice device, BluetoothDeviceState expect) {
    return Future(() => expect);
  }
   */
}

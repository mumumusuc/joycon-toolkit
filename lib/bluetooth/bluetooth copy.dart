import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Bluetooth {
  static const MethodChannel _bluetoothChannel =
      const MethodChannel('com.mumumusuc.libjoycon/bluetooth');
  static const BasicMessageChannel _stateChannel = const BasicMessageChannel(
      'com.mumumusuc.libjoycon/bluetooth/state', const StandardMessageCodec());
  static final Bluetooth _instance = Bluetooth._();
  int _state = _STATE_NONE;

  Bluetooth._() {
    _stateChannel.setMessageHandler(_handler);
  }

  factory Bluetooth() => _instance;

  final Set<BluetoothCallbackMixin> callbacks = Set();

  void addListener(BluetoothCallbackMixin cb) {
    if (cb == null) return;
    callbacks.add(cb);
  }

  void removeListener(BluetoothCallbackMixin cb) {
    if (cb == null) return;
    callbacks.remove(cb);
  }

  static void enable(bool on) async {
    _bluetoothChannel.invokeMethod('enable', {'on': on});
  }

  static void discovery(bool on) {
    _bluetoothChannel.invokeMethod('discovery', {'on': on});
  }

  static void pair(BluetoothDevice dev) {
    _bluetoothChannel.invokeMethod('pair', {'key': dev.key});
  }

  static void connect(BluetoothDevice dev, bool on) {
    _bluetoothChannel.invokeMethod('connect', {'key': dev.key, 'on': on});
  }

  static Future<AdapterState> getAdapterState() {
    return _bluetoothChannel
        .invokeMethod('getAdapterState')
        .then((value) => _parseAdapterState(value));
  }

  static Future<DeviceState> getDeviceState(BluetoothDevice dev) {
    return _bluetoothChannel
        .invokeMethod('getDeviceState', {'address': dev.address}).then(
            (value) => _parseDeviceState(value, mask: true));
  }

  static Future<Set<BluetoothDevice>> getDevices() {
    return _bluetoothChannel
        .invokeMethod<List<dynamic>>('getDevices')
        .then<Set<BluetoothDevice>>((data) {
      return data.map((it) => BluetoothDevice.fromMap(it)).toSet();
    });
  }

  static Future<Set<BluetoothDevice>> getPairedDevices() {
    return _bluetoothChannel
        .invokeMethod<List<dynamic>>('getPairedDevices')
        .then<Set<BluetoothDevice>>((data) {
      return data.map((it) => BluetoothDevice.fromMap(it)).toSet();
    });
  }

  static Future<Set<BluetoothDevice>> getConnectedDevices() {
    return _bluetoothChannel
        .invokeMethod<List<dynamic>>('getConnectedDevices')
        .then<Set<BluetoothDevice>>((data) {
      return data.map((it) => BluetoothDevice.fromMap(it)).toSet();
    });
  }

  Future<dynamic> _handler(dynamic msg) async {
    if (callbacks.isEmpty) return null;
    if (msg is Map) {
      int state = msg['state'];
      //print('bt state = $state');
      if ((state & _STATE_DEVICE_MASK) == 0) {
        callbacks.forEach(
            (it) => it.onAdapterStateChanged(_parseAdapterState(state)));
      } else {
        state = state & (~_STATE_DEVICE_MASK);
        final BluetoothDevice device = BluetoothDevice.fromMap(msg);
        switch (state) {
          case _STATE_DISCONNECTED:
            final DeviceState _state = await getDeviceState(device);
            callbacks.forEach((it) => it.onDeviceStateChanged(device, _state));
            break;
          case _STATE_UNBOND:
          case _STATE_BONDING:
          case _STATE_BONDED:
            if (_state == _STATE_DISCONNECTED || _state == _STATE_NONE) {
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
      _state = state;
    }
    return null;
  }
}

enum AdapterState {
  UNKNOWN,
  ENABLED,
  TURNING_ON,
  DISABLED,
  TURNING_OFF,
  DISCOVER_OFF,
  DISCOVER_ON,
}

enum DeviceState {
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

class DeviceCategory {
  final int _value;

  int get index => _value;

  const DeviceCategory._(this._value);

  factory DeviceCategory.byName(String name) {
    final int index = names.indexOf(name);
    if (index < 0) throw ArgumentError.value(name);
    return values[index];
  }

  static const ProController = const DeviceCategory._(0);
  static const JoyCon_L = const DeviceCategory._(1);
  static const JoyCon_R = const DeviceCategory._(2);
  static const JoyCon_Dual = const DeviceCategory._(3);
  static const values = [ProController, JoyCon_L, JoyCon_R, JoyCon_Dual];
  static const names = ['Pro Controller', 'Joy-Con (L)', 'Joy-Con (R)', 'TBD'];

  @override
  String toString() => names[_value];
}

class BluetoothDevice {
  final String key;
  final String name;
  final String address;
  final DeviceState state;

  const BluetoothDevice._(
      {@required this.key,
      @required this.name,
      @required this.address,
      this.state})
      : assert(key != null),
        assert(name != null),
        assert(address != null);

  factory BluetoothDevice.fromMap(Map<dynamic, dynamic> data) {
    DeviceState state;
    var value = data['state'];
    if (value == 0)
      state = DeviceState.NONE;
    else if (value == 1)
      state = DeviceState.PAIRED;
    else if (value == 2) state = DeviceState.CONNECTED;
    return BluetoothDevice._(
        key: data['key'],
        name: data['name'],
        address: data['address'],
        state: state);
  }

  factory BluetoothDevice.test(String name, String address) {
    return BluetoothDevice._(key: 'test_key', name: name, address: address);
  }

  DeviceCategory get category => DeviceCategory.byName(name);

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != this.runtimeType) return false;
    final BluetoothDevice _other = other;
    return name == _other.name && address == _other.address;
  }

  @override
  int get hashCode => hashValues(name, address);

  @override
  String toString() => '{$name, $address}';
}

// none
const int _STATE_NONE = 0;
// adapter state
const int _STATE_OFF = 10;
const int _STATE_TURNING_ON = 11;
const int _STATE_ON = 12;
const int _STATE_TURNING_OFF = 13;
const int _STATE_DISCOVERY_OFF = 14;
const int _STATE_DISCOVERY_ON = 15;
// device mask
const int _STATE_DEVICE_MASK = 0x10;
// device connect state
const int _STATE_DISCONNECTED = 0;
const int _STATE_CONNECTING = 1;
const int _STATE_CONNECTED = 2;
const int _STATE_DISCONNECTING = 3;
// device found
const int _STATE_FOUND_DEVICE = 4;
// device bond state
const int _STATE_UNBOND = 10;
const int _STATE_BONDING = 11;
const int _STATE_BONDED = 12;

AdapterState _parseAdapterState(int state) {
  switch (state) {
    case _STATE_OFF:
      return AdapterState.DISABLED;
    case _STATE_TURNING_ON:
      return AdapterState.TURNING_ON;
    case _STATE_ON:
      return AdapterState.ENABLED;
    case _STATE_TURNING_OFF:
      return AdapterState.TURNING_OFF;
    case _STATE_DISCOVERY_OFF:
      return AdapterState.DISCOVER_OFF;
    case _STATE_DISCOVERY_ON:
      return AdapterState.DISCOVER_ON;
    default:
      throw FormatException('unkown adapter state : $state');
  }
}

DeviceState _parseDeviceState(int state, {bool mask = false}) {
  if (mask) state = state & (~_STATE_DEVICE_MASK);
  switch (state) {
    case _STATE_DISCONNECTED:
      return DeviceState.DISCONNECTED;
    case _STATE_CONNECTING:
      return DeviceState.CONNECTING;
    case _STATE_CONNECTED:
      return DeviceState.CONNECTED;
    case _STATE_DISCONNECTING:
      return DeviceState.DISCONNECTING;
    case _STATE_FOUND_DEVICE:
      return DeviceState.FOUND;
    case _STATE_UNBOND:
      return DeviceState.UNPAIRED;
    case _STATE_BONDING:
      return DeviceState.PAIRING;
    case _STATE_BONDED:
      return DeviceState.PAIRED;
    default:
      throw FormatException('unkown device state : $state');
  }
}

typedef OnAdapterStateChanged = void Function(AdapterState);
typedef OnDeviceStateChanged = void Function(BluetoothDevice, DeviceState);

mixin BluetoothCallbackMixin {
  void onAdapterStateChanged(AdapterState state);

  void onDeviceStateChanged(BluetoothDevice device, DeviceState state);
}

class BluetoothCallback with BluetoothCallbackMixin {
  final OnAdapterStateChanged _onAdapterStateChanged;
  final OnDeviceStateChanged _onDeviceStateChanged;

  const BluetoothCallback({
    OnAdapterStateChanged onAdapterStateChanged,
    OnDeviceStateChanged onDeviceStateChanged,
  })  : _onAdapterStateChanged = onAdapterStateChanged,
        _onDeviceStateChanged = onDeviceStateChanged;

  @override
  void onAdapterStateChanged(AdapterState state) {
    _onAdapterStateChanged?.call(state);
  }

  @override
  void onDeviceStateChanged(BluetoothDevice device, DeviceState state) {
    _onDeviceStateChanged?.call(device, state);
  }
}

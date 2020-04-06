import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Bluetooth {
  static const MethodChannel _bluetoothChannel =
      const MethodChannel('com.mumumusuc.libjoycon/bluetooth');
  static const BasicMessageChannel _stateChannel = const BasicMessageChannel(
      'com.mumumusuc.libjoycon/bluetooth/state', const StandardMessageCodec());
  static final Bluetooth _instance = Bluetooth._();

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
        .then((value) => AdapterState._wrap(value));
  }

  static Future<DeviceState> getDeviceState(BluetoothDevice dev) {
    return _bluetoothChannel.invokeMethod('getDeviceState',
        {'address': dev.address}).then((value) => DeviceState._wrap(value));
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
    if (!(msg is Map)) return null;

    int event = msg['event'];
    // adapter event
    if (AdapterState._isAdapterState(event)) {
      callbacks
          .forEach((it) => it.onAdapterStateChanged(AdapterState._wrap(event)));
    } else if (DeviceState._isDeviceState(event)) {
      callbacks.forEach((it) => it.onDeviceStateChanged(
          BluetoothDevice.fromMap(msg), DeviceState._wrap(event)));
    }
    return null;
  }
}

class AdapterState {
  final int _value;
  final String _name;
  const AdapterState._(this._value, this._name);
  factory AdapterState._wrap(int value) =>
      value == null ? NONE : values[value & ~_MASK];

  static bool _isAdapterState(int value) =>
      (value & AdapterState._MASK) == AdapterState._MASK;

  static const int _MASK = 0x20;
  static const AdapterState NONE = AdapterState._(0, 'None');
  static const AdapterState DISABLED = AdapterState._(0x1, 'Disabled');
  static const AdapterState ENABLED = AdapterState._(0x2, 'Enabled');
  static const AdapterState DISCOVERY_OFF = AdapterState._(0x3, 'Discovery off');
  static const AdapterState DISCOVERY_ON = AdapterState._(0x4, 'Discovery on');
  static const AdapterState TURNING_ON = AdapterState._(0x5, 'Turning on');
  static const AdapterState TURNING_OFF = AdapterState._(0x6, 'Turning off');
  static List<AdapterState> get values => [
        NONE,
        DISABLED,
        ENABLED,
        DISCOVERY_OFF,
        DISCOVERY_ON,
        TURNING_ON,
        TURNING_OFF,
      ];
  /*    
  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other._value == _value;
  }

  @override
  int get hashCode => hashValues(_value, _name);
  */
  @override
  String toString() => 'AdapterState.$_name';
}

class DeviceState {
  final int _value;
  final String _name;
  const DeviceState._(this._value, this._name);
  factory DeviceState._wrap(int value) =>
      value == null ? NONE : values[value & ~_MASK];

  static bool _isDeviceState(int value) =>
      (value & DeviceState._MASK) == DeviceState._MASK;

  static const int _MASK = 0x10;
  static const DeviceState NONE = DeviceState._(0x0, 'None');
  static const DeviceState FOUND = DeviceState._(0x1, 'Found');
  static const DeviceState REMOVE = DeviceState._(0x2, 'Remove');
  static const DeviceState UNPAIRED = DeviceState._(0x3, 'Unpaired');
  static const DeviceState UNPAIRING = DeviceState._(0x4, 'Unpairing');
  static const DeviceState PAIRING = DeviceState._(0x5, 'Pairing');
  static const DeviceState PAIRED = DeviceState._(0x6, 'Paired');
  static const DeviceState DISCONNECTED = DeviceState._(0x7, 'Disconnected');
  static const DeviceState DISCONNECTING = DeviceState._(0x8, 'Disconnecting');
  static const DeviceState CONNECTING = DeviceState._(0x9, 'Connecting');
  static const DeviceState CONNECTED = DeviceState._(0xa, 'Connected');
  static List<DeviceState> get values => [
        NONE,
        FOUND,
        REMOVE,
        UNPAIRED,
        UNPAIRING,
        PAIRING,
        PAIRED,
        DISCONNECTED,
        DISCONNECTING,
        CONNECTING,
        CONNECTED,
      ];
  /*
  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    return other._value == _value;
  }

  @override
  int get hashCode => hashValues(_value, _name);
  */
  @override
  String toString() => 'DeviceState.$_name';
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
    print("create form map $data");
    int state = data['state'];
    return BluetoothDevice._(
      key: data['key'],
      name: data['name'],
      address: data['address'],
      state: DeviceState._wrap(state),
    );
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
  String toString() => '{$name, $address, $state}';
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

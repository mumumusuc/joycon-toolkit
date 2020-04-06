library bloc;

import 'dart:collection';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'bluetooth/bluetooth.dart';
import 'generated/i18n.dart';

part 'bloc/config.dart';

part 'bloc/scale.dart';

// globals
const double kPageMaxWidth = 600;
const BoxConstraints kPageConstraint = BoxConstraints(maxWidth: kPageMaxWidth);
const Duration kDuration = const Duration(milliseconds: 400);
const Color kDividerColor = const Color(0xFFBDBDBD);
const BorderSide kDividerBorderSide =
    const BorderSide(color: kDividerColor, width: 0);
const Widget kPixelDivider = const Divider(height: 1);
const Widget kPixelDividerVertical = const VerticalDivider(width: 1);
final Map<Locale, String> kLanguages = {
  Locale("en", ""): "English",
  Locale("zh", ""): "简体中文",
};

// bloc
class BlocProvider extends StatelessWidget {
  final Widget child;

  const BlocProvider({this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ListenableProvider<Bloc>(
          create: (c) => Bloc._(),
          dispose: (_, v) => v.dispose(),
        ),
        ProxyProvider<Bloc, Config>(
          update: (_, b, __) {
            if (b.config.timeDilation)
              timeDilation = 20;
            else
              timeDilation = 1;
            return b.config;
          },
        ),
        ProxyProvider<Bloc, AdapterState>(
          update: (_, b, __) => b.adapterState,
        ),
        ProxyProvider<Bloc, BluetoothDeviceRecord>(
          update: (_, b, __) => b.record,
        ),
      ],
      child: child,
    );
  }
}

class Bloc extends ChangeNotifier with BluetoothCallbackMixin {
  final Bluetooth bluetooth;
  Config _config;
  AdapterState _adapter;
  BluetoothDeviceRecord _record;

  Config get config => _config;

  AdapterState get adapterState => _adapter;

  BluetoothDeviceRecord get record => _record;

  set config(Config config) {
    if (_config != config) {
      _config = config;
      notifyListeners();
    }
  }

  AdapterState get adapter => _adapter;

  Bloc._()
      : bluetooth = Bluetooth(),
        _adapter = AdapterState.NONE,
        _config = kDefaultConfig,
        _record = BluetoothDeviceRecord._() {
    bluetooth.addListener(this);
    Bluetooth.getAdapterState().then((v) => onAdapterStateChanged(v));
  }

  @override
  void dispose() {
    bluetooth.removeListener(this);
    super.dispose();
  }

  @override
  void onAdapterStateChanged(AdapterState state) {
    print('onAdapterStateChanged -> $state');
    if (_adapter != state) {
      _adapter = state;
      if (state == AdapterState.ENABLED ||
          state == AdapterState.DISCOVERY_ON ||
          state == AdapterState.DISCOVERY_OFF) {
        Bluetooth.getDevices().then((value) {
          var it = value.toList().asMap().map((_, v) => MapEntry(v, v.state));
          if (_record._appendOrUpdate(it)) _record = _record.copyWith();
        });
      }
      notifyListeners();
    }
  }

  @override
  void onDeviceStateChanged(BluetoothDevice device, DeviceState state) {
    print('onDeviceStateChanged -> $state');
    if (record._appendOrUpdate({device: state})) {
      _record = _record.copyWith();
      notifyListeners();
    }
  }

  static Bloc of(BuildContext context) =>
      Provider.of<Bloc>(context, listen: false);

  void updateConfig({
    Locale locale,
    ThemeData lightTheme,
    ThemeData darkTheme,
    ThemeMode themeMode,
    bool timeDilation,
    TextScale textScale,
    bool debug,
    bool showOffscreenLayersCheckerboard,
    bool showPerformanceOverlay,
    bool showRasterCacheImagesCheckerboard,
  }) {
    config = config.copyWith(
      locale: locale ?? config.locale,
      lightTheme: lightTheme ?? config.lightTheme,
      darkTheme: darkTheme ?? config.darkTheme,
      themeMode: themeMode ?? config.themeMode,
      textScale: textScale ?? config.textScale,
      timeDilation: timeDilation ?? config.timeDilation,
      debug: debug ?? config.debug,
      showOffscreenLayersCheckerboard: showOffscreenLayersCheckerboard ??
          config.showOffscreenLayersCheckerboard,
      showPerformanceOverlay:
          showPerformanceOverlay ?? config.showPerformanceOverlay,
      showRasterCacheImagesCheckerboard: showRasterCacheImagesCheckerboard ??
          config.showRasterCacheImagesCheckerboard,
    );
  }

//debug
  void inject(BluetoothDevice device, DeviceState state) {
    onDeviceStateChanged(device, state);
  }
}

class DeviceType {
  final Size size;

  const DeviceType._(this.size);

  factory DeviceType.of(BuildContext context) =>
      DeviceType._(MediaQuery.of(context).size);

  bool get isPhone => size.width < PhoneThreshold;

  bool get isTable => size.width < TabletThreshold && !isPhone;

  bool get isDesktop => size.width >= DesktopThreshold;

  static const double PhoneThreshold = 600;
  static const double TabletThreshold = 900;
  static const double DesktopThreshold = 1200;
}

class BluetoothDeviceRecord {
  final int _key;
  final Map<BluetoothDevice, DeviceState> _data;

  BluetoothDeviceRecord._({int key = 0, Map<BluetoothDevice, DeviceState> data})
      : _key = key,
        _data = data ?? LinkedHashMap();

  BluetoothDeviceRecord copyWith({Map<BluetoothDevice, DeviceState> data}) {
    return BluetoothDeviceRecord._(key: _key + 1, data: data ?? _data);
  }

  List<MapEntry<BluetoothDevice, DeviceState>> get records =>
      _data.entries.toList(growable: false);

  int get length => _data.length;

  DeviceState operator [](dynamic device) {
    if (device is int) {
      //return records[device].value;
      return records[device].key.state;
    }
    if (device is BluetoothDevice) {
      return _data[device];
    }
    throw FormatException('Unsupported paramater type ${device.runtimeType}');
  }

  bool _appendOrUpdate(Map<BluetoothDevice, DeviceState> data) {
    if (data.isEmpty) return false;
    return data.entries.map((e) {
      print('_appendOrUpdate -> $e');
      // TODO:
      if (_data[e.key] != e.value) {
        _data[e.key] = e.value;
        _data.keys.firstWhere((it) => it == e.key).state = e.key.state;
        return true;
      }
      return false;
    }).reduce((v, e) => v & e);
  }

  static BluetoothDeviceRecord of(BuildContext context) =>
      Provider.of<BluetoothDeviceRecord>(context, listen: false);
}

Widget getDeviceIcon(BluetoothDevice device, {Size size, Color color}) {
  switch (device.category) {
    case DeviceCategory.ProController:
      return Image.asset(
        'assets/image/pro_controller_icon.png',
        width: size?.width,
        height: size?.height,
        //color: color,
      );
    case DeviceCategory.JoyCon_L:
      return Image.asset(
        'assets/image/joycon_l_icon.png',
        width: size?.width,
        height: size?.height,
        //color: color,
      );
    case DeviceCategory.JoyCon_R:
      return Image.asset(
        'assets/image/joycon_r_icon.png',
        width: size?.width,
        height: size?.height,
        //color: color,
      );
    case DeviceCategory.JoyCon_Dual:
      return Image.asset(
        'assets/image/joycon_d_icon.png',
        width: size?.width,
        height: size?.height,
        //color: color,
      );
    default:
      throw ArgumentError.value(device.name);
  }
}

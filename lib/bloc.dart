library bloc;

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
    // onAdapterStateChanged(v)
    Bluetooth.getAdapterState().then((state) {
      if (state == AdapterState.ENABLED ||
          state == AdapterState.DISCOVERY_ON ||
          state == AdapterState.DISCOVERY_OFF) {
        Bluetooth.getDevices().then((value) {
          if (_record._appendOrUpdate(value.toList())) {
            _record = _record.copyWith();
            notifyListeners();
          }
        });
      }
    });
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
      if (state == AdapterState.ENABLED && _adapter == AdapterState.DISABLED) {
        Bluetooth.getDevices().then((value) {
          if (_record._appendOrUpdate(value.toList()))
            _record = _record.copyWith();
        });
      }
      notifyListeners();
    }
  }

  @override
  void onDeviceStateChanged(BluetoothDevice device, DeviceState state) {
    print('Bloc onDeviceStateChanged -> $state');
    if (record._appendOrUpdate([device])) {
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
  final List<BluetoothDevice> _data;

  BluetoothDeviceRecord._({int key = 0, List<BluetoothDevice> data})
      : _key = key,
        _data = data ?? [];

  BluetoothDeviceRecord copyWith({List<BluetoothDevice> data}) {
    return BluetoothDeviceRecord._(key: _key + 1, data: data ?? _data);
  }

  List<BluetoothDevice> get records => _data;

  int get length => _data.length;

  DeviceState operator [](dynamic index) {
    if (index is int) return _data[index].state;
    if (index is BluetoothDevice)
      return _data.firstWhere((e) => e == index).state;
    throw FormatException('Unsupported paramater type ${index.runtimeType}');
  }

  bool _appendOrUpdate(List<BluetoothDevice> data) {
    if (data?.isNotEmpty != true) return false;
    return data.map<bool>((e) {
      var i = _data.indexOf(e);
      print("_appendOrUpdate -> index = $i");
      if (i < 0) {
        _data.add(e);
        return true;
      } else if (_data[i].state != e.state) {
        _data
          ..removeAt(i)
          ..insert(i, e);
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

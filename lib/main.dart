import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:joycon/bloc.dart';
import 'package:joycon/home.dart';
import 'package:joycon/option/config.dart';
import 'package:joycon/option/theme.dart';
import 'package:joycon/widgets/color.dart';
import 'package:joycon/widgets/controller.dart';
import 'package:joycon/widgets/device.dart';
import 'package:joycon/widgets/light.dart';
import 'package:joycon/widgets/rumble.dart';
import 'package:provider/provider.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: Bloc.providers,
      child: Consumer<AppConfig>(
        builder: (context, config, _) {
          return MaterialApp(
            title: 'JoyCon',
            // See https://github.com/flutter/flutter/wiki/Desktop-shells#fonts
            showPerformanceOverlay: config.showPerformanceOverlay,
            checkerboardOffscreenLayers: config.showOffscreenLayersCheckerboard,
            checkerboardRasterCacheImages:
                config.showRasterCacheImagesCheckerboard,
            theme: config.themeData,
            darkTheme: appDefaultDarkTheme.data,
            themeMode: ThemeMode.dark,
            initialRoute: '/',
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => HomePage(),
                  );
                case '/device':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (_) =>
                        ControllerWidget(device: settings.arguments),
                  );
                default:
                  break;
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class RouteAddress {
  static const Map<String, String> address = {
    '/device': 'Device',
    '/rumble': 'Rumble',
    '/light': 'Light',
    '/color': 'Color',
    '/settings': 'Settings',
  };

  static List<String> get routers => address.keys.toList(growable: false);

  static List<String> get names => address.values.toList(growable: false);
}

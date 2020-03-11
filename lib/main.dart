import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:joycon/bloc.dart';
import 'package:joycon/home.dart';
import 'package:joycon/option/config.dart';
import 'package:joycon/widgets/controller.dart';
import 'package:provider/provider.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    print('build root app');
    return MultiProvider(
      providers: Bloc.providers,
      child: Consumer<AppConfig>(
        builder: (context, config, _) {
          print('app config changed');
          return MaterialApp(
            title: 'JoyCon',
            // See https://github.com/flutter/flutter/wiki/Desktop-shells#fonts
            showPerformanceOverlay: config.showPerformanceOverlay,
            checkerboardOffscreenLayers: config.showOffscreenLayersCheckerboard,
            checkerboardRasterCacheImages:
                config.showRasterCacheImagesCheckerboard,
            theme: config.lightTheme,
            darkTheme: config.darkTheme,
            themeMode: ThemeMode.system,
            initialRoute: '/',
            onGenerateInitialRoutes: (p) => [
              MaterialPageRoute(
                settings: RouteSettings(name: p),
                builder: (_) => HomePage(),
              ),
            ],
            onGenerateRoute: (settings) {
              switch (settings.name) {
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

            builder: (context, child) {
              return Scaffold(body: SafeArea(child: child));
            },
          );
        },
      ),
    );
  }
}

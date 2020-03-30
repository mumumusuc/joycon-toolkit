import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'dart:io';
import 'bloc.dart';
import 'home.dart';
import 'generated/i18n.dart';
import 'splash.dart';
import 'test/test.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  //debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MyApp());
  //runApp(TestApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    print('build root');
    return BlocProvider(
      child: Consumer<Config>(
        builder: (context, config, __) {
          print('build material app');
          // See https://github.com/flutter/flutter/wiki/Desktop-shells#fonts
          return MaterialApp(
            onGenerateTitle: (context) => S.of(context).title,
            showPerformanceOverlay: config.showPerformanceOverlay,
            checkerboardOffscreenLayers: config.showOffscreenLayersCheckerboard,
            checkerboardRasterCacheImages:
                config.showRasterCacheImagesCheckerboard,
            theme: config.lightTheme,
            darkTheme: config.darkTheme,
            themeMode: config.themeMode,
            locale: config.locale,
            localizationsDelegates: Config.localizationsDelegates,
            supportedLocales: Config.supportedLocales,
            localeResolutionCallback: config.localeResolutionCallback,
            initialRoute: Platform.isAndroid ? '/home' : '/home/splash',
            onGenerateInitialRoutes: (p) {
              final List<Route> routes = [];
              final parts = p.split('/');
              print(parts);
              parts.forEach((e) {
                if (e == 'home')
                  routes.add(
                    MaterialPageRoute(
                      settings: RouteSettings(name: p),
                      builder: (_) => HomePage(),
                    ),
                  );
                else if (e == 'splash') routes.add(SplashRoute());
              });
              return routes;
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/home':
                  return MaterialPageRoute(
                    builder: (_) => HomePage(),
                    settings: settings,
                  );
                default:
                  return null;
              }
            },
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: config.textScale.scale,
                ),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}

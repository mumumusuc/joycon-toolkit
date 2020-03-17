import 'dart:io';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'bloc.dart';
import 'home2.dart';
import 'option/config.dart';
import 'generated/i18n.dart';
import 'splash.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    final Locale locale = Locale('en', '');
    return MultiProvider(
      providers: Bloc.providers,
      child: Consumer<AppConfig>(
        builder: (context, config, _) {
          // See https://github.com/flutter/flutter/wiki/Desktop-shells#fonts
          return MaterialApp(
            onGenerateTitle: (context) => S.of(context).title,
            showPerformanceOverlay: config.showPerformanceOverlay,
            checkerboardOffscreenLayers: config.showOffscreenLayersCheckerboard,
            checkerboardRasterCacheImages:
                config.showRasterCacheImagesCheckerboard,
            theme: config.lightTheme,
            darkTheme: config.darkTheme,
            themeMode: ThemeMode.system,
            //locale: locale,
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            localeResolutionCallback:
                S.delegate.resolution(fallback: locale, withCountry: false),
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
                case '/':
                case '/home':
                  return MaterialPageRoute(
                    builder: (_) => HomePage(),
                    settings: settings,
                  );
                default:
                  return null;
              }
            },
/*
            builder: (context, child) {
              return Container(
                color: Theme.of(context).primaryColor,
                child: SafeArea(child: child),
              );
            },
 */
          );
        },
      ),
    );
  }
}

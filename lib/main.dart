import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'bloc.dart';
import 'home.dart';
import 'option/config.dart';
import 'widgets/controller.dart';

import 'generated/i18n.dart';

void main() {
  // See https://github.com/flutter/flutter/wiki/Desktop-shells#target-platform-override
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
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
            locale: Locale('zh', ''),
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            localeResolutionCallback:
                S.delegate.resolution(fallback: Locale('zh', '')),
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

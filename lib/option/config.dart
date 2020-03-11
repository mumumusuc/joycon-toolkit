import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'scale.dart';

class AppConfig with ChangeNotifier {
  ThemeData lightTheme;
  ThemeData darkTheme;
  AppTextScaleValue textScaleFactor;
  bool debug;
  bool timeDilate;
  bool showPerformanceOverlay;
  bool showRasterCacheImagesCheckerboard;
  bool showOffscreenLayersCheckerboard;

  AppConfig({
    this.lightTheme,
    this.darkTheme,
    this.textScaleFactor,
    this.timeDilate,
    this.debug = false,
    this.showOffscreenLayersCheckerboard = false,
    this.showPerformanceOverlay = false,
    this.showRasterCacheImagesCheckerboard = false,
  });

  static AppConfig of(BuildContext context) =>
      Provider.of<AppConfig>(context, listen: false);

  void merge(AppConfig config) {
    update(
      lightTheme: config?.lightTheme,
      darkTheme: config?.darkTheme,
      timeDilate: config?.timeDilate,
      textScaleFactor: config?.textScaleFactor,
      debug: config?.debug,
      showOffscreenLayersCheckerboard: config?.showOffscreenLayersCheckerboard,
      showPerformanceOverlay: config?.showPerformanceOverlay,
      showRasterCacheImagesCheckerboard:
          config?.showRasterCacheImagesCheckerboard,
    );
  }

  void update({
    ThemeData lightTheme,
    ThemeData darkTheme,
    double pageWidth,
    bool timeDilate,
    bool darkMode,
    bool animate,
    bool debug,
    bool showOffscreenLayersCheckerboard,
    bool showPerformanceOverlay,
    bool showRasterCacheImagesCheckerboard,
    AppTextScaleValue textScaleFactor,
  }) {
    this.lightTheme = lightTheme ?? this.lightTheme;
    this.darkTheme = darkTheme ?? this.darkTheme;
    this.textScaleFactor = textScaleFactor ?? this.textScaleFactor;
    this.timeDilate = timeDilate ?? this.timeDilate;
    this.debug = debug ?? this.debug;
    this.showOffscreenLayersCheckerboard =
        showOffscreenLayersCheckerboard ?? this.showOffscreenLayersCheckerboard;
    this.showPerformanceOverlay =
        showPerformanceOverlay ?? this.showPerformanceOverlay;
    this.showRasterCacheImagesCheckerboard =
        showRasterCacheImagesCheckerboard ??
            this.showRasterCacheImagesCheckerboard;
    notifyListeners();
  }

  AppConfig copyWith({
    ThemeData lightTheme,
    ThemeData darkTheme,
    double pageWidth,
    bool timeDilate,
    AppTextScaleValue textScaleFactor,
    bool darkMode,
    bool debug,
    bool animate,
    bool showOffscreenLayersCheckerboard,
    bool showPerformanceOverlay,
    bool showRasterCacheImagesCheckerboard,
  }) {
    return AppConfig(
      lightTheme: lightTheme,
      darkTheme: darkTheme,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      timeDilate: timeDilate ?? this.timeDilate,
      debug: debug,
      showOffscreenLayersCheckerboard: showOffscreenLayersCheckerboard ??
          this.showOffscreenLayersCheckerboard,
      showPerformanceOverlay: showOffscreenLayersCheckerboard ??
          this.showOffscreenLayersCheckerboard,
      showRasterCacheImagesCheckerboard: showOffscreenLayersCheckerboard ??
          this.showOffscreenLayersCheckerboard,
    );
  }
}

final defaultConfig = AppConfig(
  lightTheme: _build(
    Brightness.light,
    Colors.purple,
    Colors.white,
  ),
  darkTheme: _build(
    Brightness.dark,
    Colors.purple,
    Colors.black,
  ),
  timeDilate: false,
  textScaleFactor: allTextScaleValues[2],
  debug: false,
);

ThemeData buildTheme(Brightness brightness, Color primary, Color accent) =>
    _build(brightness, primary, accent);

ThemeData _build(Brightness brightness, Color primary, Color accent) {
  final ColorSwatch primarySwatch = primary;
  final ThemeData data = ThemeData(
    brightness: brightness,
    primarySwatch: primarySwatch,
    primaryColor: primarySwatch,
    primaryColorLight: primarySwatch[100],
    primaryColorDark: primarySwatch[700],
    accentColor: accent ?? primarySwatch[500],
    toggleableActiveColor: accent ?? primarySwatch[600],
  );
  final String ff = 'GoogleSans';
  final TextTheme t = data.textTheme;
  final TextTheme p = data.primaryTextTheme;
  final TextTheme a = data.accentTextTheme;
  return data.copyWith(
    textTheme: t.copyWith(headline6: t.headline6.copyWith(fontFamily: ff)),
    primaryTextTheme:
        p.copyWith(headline6: p.headline6.copyWith(fontFamily: ff)),
    accentTextTheme:
        a.copyWith(headline6: a.headline6.copyWith(fontFamily: ff)),
  );
}

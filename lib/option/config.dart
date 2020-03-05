import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'scale.dart';
import 'theme.dart';

class AppConfig with ChangeNotifier {
  AppTheme theme;
  AppTextScaleValue textScaleFactor;
  bool debug;
  bool timeDilate;
  bool animate;
  bool showPerformanceOverlay;
  bool showRasterCacheImagesCheckerboard;
  bool showOffscreenLayersCheckerboard;

  AppConfig({
    this.theme,
    this.textScaleFactor,
    this.timeDilate,
    this.animate,
    this.debug = false,
    this.showOffscreenLayersCheckerboard = false,
    this.showPerformanceOverlay = false,
    this.showRasterCacheImagesCheckerboard = false,
  });

  static AppConfig of(BuildContext context) =>
      Provider.of<AppConfig>(context, listen: false);

  bool get darkMode => theme.isDark;

  ThemeData get themeData => theme.data;

  void merge(AppConfig config) {
    update(
      theme: config?.theme,
      timeDilate: config?.timeDilate,
      textScaleFactor: config?.textScaleFactor,
      darkMode: config?.darkMode,
      animate: config?.animate,
      debug: config?.debug,
      showOffscreenLayersCheckerboard: config?.showOffscreenLayersCheckerboard,
      showPerformanceOverlay: config?.showPerformanceOverlay,
      showRasterCacheImagesCheckerboard:
          config?.showRasterCacheImagesCheckerboard,
    );
  }

  void update({
    AppTheme theme,
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
    this.theme = theme ?? this.theme;
    darkMode ??= this.darkMode;
    if (darkMode != this.darkMode) {
      this.theme = this.theme.copyWith(dark: darkMode);
    }
    this.textScaleFactor = textScaleFactor ?? this.textScaleFactor;
    this.timeDilate = timeDilate ?? this.timeDilate;
    this.animate = animate ?? this.animate;
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
    AppTheme theme,
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
    theme ??= this.theme;
    darkMode ??= this.darkMode;
    if (darkMode != this.darkMode) {
      theme = theme.copyWith(dark: darkMode);
    }
    return AppConfig(
      theme: theme,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      timeDilate: timeDilate ?? this.timeDilate,
      animate: animate ?? this.animate,
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

final appDefaultConfig = AppConfig(
  theme: appDefaultLightTheme,
  timeDilate: false,
  textScaleFactor: allTextScaleValues[2],
  debug: false,
  animate: false,
);

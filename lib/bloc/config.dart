part of bloc;

class Config {
  Locale _locale;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;
  final TextScale textScale;
  final bool debug;
  final bool timeDilation;
  final bool showPerformanceOverlay;
  final bool showRasterCacheImagesCheckerboard;
  final bool showOffscreenLayersCheckerboard;

  Locale get locale => _locale;

  Config({
    Locale locale,
    this.lightTheme,
    this.darkTheme,
    this.themeMode = ThemeMode.system,
    this.textScale = kTextScaleSystem,
    this.timeDilation = false,
    this.debug = false,
    this.showOffscreenLayersCheckerboard = false,
    this.showPerformanceOverlay = false,
    this.showRasterCacheImagesCheckerboard = false,
  }) : _locale = locale;

  Config copyWith({
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
    debug ??= this.debug;
    showOffscreenLayersCheckerboard ??= this.showOffscreenLayersCheckerboard;
    showPerformanceOverlay ??= this.showPerformanceOverlay;
    showRasterCacheImagesCheckerboard ??=
        this.showRasterCacheImagesCheckerboard;
    return Config(
      locale: locale ?? this.locale,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      themeMode: themeMode ?? this.themeMode,
      textScale: textScale ?? this.textScale,
      timeDilation: timeDilation ?? this.timeDilation,
      debug: debug,
      showOffscreenLayersCheckerboard: debug,
      // && showOffscreenLayersCheckerboard,
      showPerformanceOverlay: debug,
      // && showPerformanceOverlay,
      showRasterCacheImagesCheckerboard: debug,
      // && showRasterCacheImagesCheckerboard,
    );
  }

  static Config of(BuildContext context) =>
      Provider.of<Config>(context, listen: false);

  static Iterable<LocalizationsDelegate<dynamic>> get localizationsDelegates =>
      [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static List<Locale> get supportedLocales => S.delegate.supportedLocales;

  get localeResolutionCallback => (locale, supportedLocales) {
        final _locale = S.delegate.resolution(
            fallback: kDefaultLocale,
            withCountry: false)(locale, supportedLocales);
        if (this._locale != _locale) {
          this._locale = _locale;
          print('localeResolutionCallback -> $locale, $_locale');
        }
        return _locale;
      };
}

const Locale kDefaultLocale = Locale('en', '');
final ThemeData kDefaultLightTheme = _build(
  Brightness.light,
  Colors.purple,
  Colors.indigoAccent,
);
final ThemeData kDefaultDarkTheme = _build(
  Brightness.dark,
  Colors.deepPurple,
  Colors.deepOrangeAccent,
);
final kDefaultConfig = Config(
  lightTheme: kDefaultLightTheme,
  darkTheme: kDefaultDarkTheme,
  timeDilation: false,
  textScale: kTextScales[2],
  debug: false,
);
final kDebugConfig = kDefaultConfig.copyWith(
  showPerformanceOverlay: true,
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

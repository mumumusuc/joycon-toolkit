import 'package:flutter/material.dart';

final AppTheme appDefaultLightTheme = AppTheme._build(
  Brightness.light,
  Colors.indigo,
  Colors.pink,
);

final AppTheme appDefaultDarkTheme = AppTheme._build(
  Brightness.dark,
  Colors.indigo,
  Colors.pink,
);

class AppTheme {
  final ThemeData data;

  const AppTheme(this.data);

  factory AppTheme._build(Brightness brightness, Color primary, Color accent) {
    final bool isDark = brightness == Brightness.dark;
    final ColorSwatch primarySwatch = primary;
    ThemeData data = ThemeData(
      brightness: brightness,
      primarySwatch: primarySwatch,
      primaryColor: primarySwatch,
      primaryColorLight: primarySwatch[100],
      primaryColorDark: primarySwatch[700],
      accentColor: accent ?? primarySwatch[500],
      toggleableActiveColor: accent ?? primarySwatch[600],
      //scaffoldBackgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      //backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
    );
    final String ff = 'GoogleSans';
    final TextTheme t = data.textTheme;
    final TextTheme p = data.primaryTextTheme;
    final TextTheme a = data.accentTextTheme;
    data = data.copyWith(
      textTheme: t.copyWith(headline6: t.headline6.copyWith(fontFamily: ff)),
      primaryTextTheme:
          p.copyWith(headline6: p.headline6.copyWith(fontFamily: ff)),
      accentTextTheme:
          a.copyWith(headline6: a.headline6.copyWith(fontFamily: ff)),
    );
    return AppTheme(data);
  }

  bool get isDark => data.brightness == Brightness.dark;

  AppTheme copyWith({bool dark, Color primary, Color accent}) {
    dark ??= this.isDark;
    primary ??= data.primaryColor;
    accent ??= data.accentColor;
    return AppTheme._build(
      dark ? Brightness.dark : Brightness.light,
      primary,
      accent,
    );
  }
}

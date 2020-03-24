import 'package:community_material_icon/community_material_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc.dart';
import '../generated/i18n.dart';
import 'icon_text.dart';

class Option extends StatelessWidget {
  final Color color;

  const Option({this.color});

  @override
  Widget build(BuildContext context) {
    final ThemeData data = Theme.of(context);
    return DefaultTextStyle(
      style: data.textTheme.subtitle2.copyWith(color: color),
      child: ListTileTheme(
        textColor: color,
        iconColor: color,
        child: ListBody(
          children: [
            _buildTimeDilation(context, data),
            _buildDebug(context, data),
            _buildLocale(context, data),
            _buildThemeMode(context, data),
            _buildTextScale(context, data),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDilation(BuildContext context, [ThemeData theme]) {
    final S s = S.of(context);
    return ListTile(
      leading: const Icon(Icons.av_timer),
      title: Text(s.option_time_dilation),
      subtitle: Text(s.option_time_dilation_desc),
      trailing: Selector<Config, bool>(
        selector: (_, config) => config.timeDilation,
        builder: (context, value, _) {
          return Switch(
            value: value,
            onChanged: (value) {
              Bloc.of(context).updateConfig(timeDilation: value);
            },
          );
        },
      ),
    );
  }

  Widget _buildDebug(BuildContext context, [ThemeData theme]) {
    final S s = S.of(context);
    return ListTile(
      leading: const Icon(Icons.bug_report),
      title: Text(s.option_debug),
      subtitle: Text(s.option_debug_desc),
      trailing: Selector<Config, bool>(
        selector: (_, config) => config.debug,
        builder: (context, value, _) {
          return Switch(
            value: value,
            onChanged: (value) {
              Bloc.of(context).updateConfig(debug: value);
            },
          );
        },
      ),
    );
  }

  Widget _buildLocale(BuildContext context, [ThemeData theme]) {
    final S s = S.of(context);
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(s.option_language),
      subtitle: Text(s.option_language_desc),
      trailing: Selector<Config, Locale>(
        selector: (_, config) => config.locale,
        builder: (context, value, _) {
          return PopupMenuButton<Locale>(
            initialValue: value,
            child: _buildTextWithIcon(kLanguages[value]),
            onSelected: (locale) {
              if (locale != value)
                Bloc.of(context).updateConfig(locale: locale);
            },
            itemBuilder: (context) {
              return Config.supportedLocales
                  .map((e) => PopupMenuItem<Locale>(
                        value: e,
                        child: Text(kLanguages[e]),
                      ))
                  .toList(growable: false);
            },
          );
        },
      ),
    );
  }

  Widget _buildThemeMode(BuildContext context, [ThemeData theme]) {
    final S s = S.of(context);
    return ListTile(
      leading: const Icon(Icons.color_lens),
      title: Text(s.option_theme_mode),
      subtitle: Text(s.option_theme_mode_desc),
      trailing: Selector<Config, ThemeMode>(
        selector: (_, config) => config.themeMode,
        builder: (context, value, _) {
          return PopupMenuButton<ThemeMode>(
            initialValue: value,
            child: _buildTextWithIcon(_getThemeModeName(context, value)),
            onSelected: (mode) {
              if (mode != value) Bloc.of(context).updateConfig(themeMode: mode);
            },
            itemBuilder: (context) {
              return ThemeMode.values
                  .map((e) => PopupMenuItem<ThemeMode>(
                        value: e,
                        child: Text(_getThemeModeName(context, e)),
                      ))
                  .toList(growable: false);
            },
          );
        },
      ),
    );
  }

  Widget _buildTextScale(BuildContext context, [ThemeData theme]) {
    final S s = S.of(context);
    return ListTile(
      leading: const Icon(CommunityMaterialIcons.format_font),
      title: Text(s.option_text_scale),
      subtitle: Text(s.option_text_scale_desc),
      trailing: Selector<Config, TextScale>(
        selector: (_, config) => config.textScale,
        builder: (context, value, _) {
          return PopupMenuButton<TextScale>(
            initialValue: value,
            child: _buildTextWithIcon(value.label),
            onSelected: (scale) {
              if (scale != value)
                Bloc.of(context).updateConfig(textScale: scale);
            },
            itemBuilder: (context) {
              return kTextScales
                  .map((e) => PopupMenuItem<TextScale>(
                        value: e,
                        child: Text(e.label),
                      ))
                  .toList(growable: false);
            },
          );
        },
      ),
    );
  }

  Widget _buildTextWithIcon(String label) {
    return IconText(
      text: label,
      gap: 4,
      trailing: const Icon(Icons.arrow_drop_down, size: 16),
      padding: const EdgeInsets.all(12),
    );
  }
}

String _getThemeModeName(BuildContext context, ThemeMode mode) {
  assert(mode != null);
  switch (mode) {
    case ThemeMode.system:
      return S.of(context).theme_mode_system;
    case ThemeMode.light:
      return S.of(context).theme_mode_light;
    case ThemeMode.dark:
      return S.of(context).theme_mode_dark;
  }
  throw ArgumentError('Unknow theme mode: $mode');
}

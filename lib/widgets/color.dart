import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:joycon/bluetooth/bluetooth.dart';
import 'package:joycon/bluetooth/controller.dart';
import 'package:provider/provider.dart';

class ColorWidget extends StatelessWidget {
  final Controller controller;

  const ColorWidget(this.controller, {Key key}) : super(key: key);

  int get _index => controller.category.index;

  List<_Profile> get _profiles => _index == 0 ? _ProPresets : _JcPresets;

  void _showBlockColorPicker(
      BuildContext context, String label, Color color, ValueChanged<Color> cb) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(8),
          title: Text(label),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: color,
              onColorChanged: cb,
              availableColors: _Profile.colors,
            ),
          ),
          actions: [
            FlatButton(
              child: Text('OK'),
              onPressed: Navigator.of(context).pop,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailColorPicker(
      BuildContext context, String label, Color color, ValueChanged<Color> cb) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(8),
          title: Text(label),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: color,
              onColorChanged: cb,
              colorPickerWidth: 300.0,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              showLabel: true,
              paletteType: PaletteType.hsv,
              pickerAreaBorderRadius: const BorderRadius.only(
                topLeft: const Radius.circular(2.0),
                topRight: const Radius.circular(2.0),
              ),
            ),
          ),
          actions: [
            FlatButton(
              child: const Text('OK'),
              onPressed: Navigator.of(context).pop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerButton(
      BuildContext context, String label, Color color, ValueChanged<Color> cb) {
    Color foregroundColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.light
            ? Colors.black
            : Colors.white;
    TextTheme textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: kToolbarHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(label, style: textTheme.caption),
          ),
          Expanded(
            child: Material(
              color: color,
              elevation: 0.2,
              child: InkWell(
                onTap: () => _showBlockColorPicker(context, label, color, cb),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${color.value.toRadixString(16)}'.toUpperCase(),
                          style: textTheme.caption
                              .copyWith(color: foregroundColor),
                        ),
                      ),
                      IconButton(
                        padding: const EdgeInsets.all(0),
                        color: foregroundColor,
                        iconSize: 20,
                        icon: const Icon(Icons.colorize),
                        onPressed: () =>
                            _showDetailColorPicker(context, label, color, cb),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControllerStack(BuildContext context) {
    final Color bgColor = Theme.of(context).cardColor;
    final List<Widget> children = [
      ColorFiltered(
        colorFilter: ColorFilter.mode(
            Color(Colors.white.value - bgColor.value).withOpacity(1),
            BlendMode.srcIn),
        child: Image.asset(_OutlineAssets[_index]),
      ),
      Selector<ValueNotifier<_Profile>, Color>(
        selector: (c, p) => p.value.body,
        child: Image.asset(_BodyAssets[_index]),
        builder: (_, color, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: child,
          );
        },
      ),
      Selector<ValueNotifier<_Profile>, Color>(
        selector: (c, p) => p.value.button,
        child: Image.asset(_ButtonAssets[_index]),
        builder: (_, color, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: child,
          );
        },
      ),
    ];
    if (_index == 0) {
      children.addAll([
        Selector<ValueNotifier<_Profile>, Color>(
          selector: (c, p) => p.value.leftGrip,
          child: Image.asset(_LeftGripAssets[_index]),
          builder: (_, color, child) {
            return ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: child,
            );
          },
        ),
        Selector<ValueNotifier<_Profile>, Color>(
          selector: (c, p) => p.value.rightGrip,
          child: Image.asset(_RightGripAssets[_index]),
          builder: (_, color, child) {
            return ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: child,
            );
          },
        ),
      ]);
    }
    return Stack(
      alignment: Alignment.center,
      children: children,
    );
  }

  Widget _buildColorCard2(BuildContext context) {
    final List<Widget> children = [
      Selector<ValueNotifier<_Profile>, Color>(
        selector: (c, p) => p.value.body,
        builder: (context, color, _) {
          return _buildPickerButton(
            context,
            'body',
            color,
            (value) {
              final notifier = _getProfileNotifier(context);
              notifier.value = notifier.value.copyWith(body: value);
            },
          );
        },
      ),
      Selector<ValueNotifier<_Profile>, Color>(
        selector: (c, p) => p.value.button,
        builder: (context, color, _) {
          return _buildPickerButton(
            context,
            'button',
            color,
            (value) {
              final notifier = _getProfileNotifier(context);
              notifier.value = notifier.value.copyWith(button: value);
            },
          );
        },
      ),
    ];
    if (_index == 0) {
      children.addAll([
        Selector<ValueNotifier<_Profile>, Color>(
          selector: (c, p) => p.value.leftGrip,
          builder: (context, color, _) {
            return _buildPickerButton(
              context,
              'left grip',
              color,
              (value) {
                final notifier = _getProfileNotifier(context);
                notifier.value = notifier.value.copyWith(leftGrip: value);
              },
            );
          },
        ),
        Selector<ValueNotifier<_Profile>, Color>(
          selector: (c, p) => p.value.rightGrip,
          builder: (context, color, _) {
            return _buildPickerButton(
              context,
              'right grip',
              color,
              (value) {
                final notifier = _getProfileNotifier(context);
                notifier.value = notifier.value.copyWith(rightGrip: value);
              },
            );
          },
        ),
      ]);
    }
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: Consumer<ValueNotifier<_Profile>>(
              child: const Text('custom'),
              builder: (c, v, child) {
                _Profile profile = v.value;
                if (!_profiles.contains(profile)) profile = null;
                return DropdownButton<_Profile>(
                  isDense: true,
                  isExpanded: true,
                  iconSize: 14,
                  value: profile,
                  hint: child,
                  items: _profiles
                      .map((e) => DropdownMenuItem<_Profile>(
                            value: e,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(e.name),
                            ),
                          ))
                      .toList(),
                  onChanged: (vv) => v.value = vv,
                );
              },
            ),
            trailing: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                _Profile p = _getProfileNotifier(context).value;
                if (p.code != null) {
                  controller.setColor(
                    p.code,
                    _Profile.None,
                    _Profile.None,
                    _Profile.None,
                  );
                } else {
                  controller.setColor(
                    p.body,
                    p.button,
                    p.leftGrip,
                    p.rightGrip,
                  );
                }
              },
            ),
          ),
          const Divider(height: 3),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildControllerStack(context),
          ),
          const Divider(),
          GridView(
            primary: false,
            shrinkWrap: true,
            padding: const EdgeInsets.all(4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.0,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            children: children,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('build color widget');
    return MultiProvider(
      providers: [
        Provider.value(value: _index),
        ListenableProvider<ValueNotifier<_Profile>>(
          create: (_) => ValueNotifier<_Profile>(_profiles[0]),
          dispose: (_, v) => v.dispose(),
        ),
      ],
      child: SingleChildScrollView(child: _buildColorCard2(context)),
    );
  }

  ValueNotifier<_Profile> _getProfileNotifier(BuildContext context) =>
      Provider.of<ValueNotifier<_Profile>>(context, listen: false);
}

const _OutlineAssets = const [
  'assets/image/pro_controller_outline.png',
  'assets/image/joycon_l_outline.png',
  'assets/image/joycon_r_outline.png',
];

const _BodyAssets = const [
  'assets/image/pro_controller_body.png',
  'assets/image/joycon_l.png',
  'assets/image/joycon_r.png',
];

const _ButtonAssets = const [
  'assets/image/pro_controller_button.png',
  'assets/image/joycon_l_button.png',
  'assets/image/joycon_r_button.png',
];

const _LeftGripAssets = const ['assets/image/pro_controller_grip_left.png'];

const _RightGripAssets = const ['assets/image/pro_controller_grip_right.png'];

class _Profile {
  static const Color Black = const Color(0xFF000000);
  static const Color Gray = const Color(0xFF828282);
  static const Color Red = const Color(0xFFE10F00);
  static const Color Blue = const Color(0xFF4655F5);
  static const Color NeonRed = const Color(0xFFFF3C28);
  static const Color NeonBlue = const Color(0xFF0AB9E6);
  static const Color NeonPink = const Color(0xFFFF3278);
  static const Color NeonGreen = const Color(0xFF1EDC00);
  static const Color NeonYellow = const Color(0xFFE6FF00);
  static const Color NeonOrange = const Color(0xFFFAA005);
  static const Color NeonPurple = const Color(0xFFB400E6);
  static const Color Pikachu = const Color(0xFFFFDC00);
  static const Color Eevee = const Color(0xFFC88C32);
  static const Color Labo = const Color(0xFFD7AA73);
  static const Color None = const Color(0xFFFFFFFF);

  static get colors => const [
        Black,
        Gray,
        Red,
        Blue,
        NeonRed,
        NeonBlue,
        NeonPink,
        NeonGreen,
        NeonYellow,
        NeonOrange,
        NeonPurple,
        Pikachu,
        Eevee,
        Labo,
      ];

  final String name;
  final Color body;
  final Color button;
  final Color leftGrip;
  final Color rightGrip;
  final Color code;

  const _Profile({
    @required this.name,
    @required this.body,
    this.button = const Color(0xFFFFFFFF),
    this.leftGrip = const Color(0xFFFFFFFF),
    this.rightGrip = const Color(0xFFFFFFFF),
    this.code,
  });

  _Profile copyWith(
      {String name,
      Color body,
      Color button,
      Color leftGrip,
      Color rightGrip}) {
    return _Profile(
      name: name ?? this.name,
      body: body ?? this.body,
      button: button ?? this.button,
      leftGrip: leftGrip ?? this.leftGrip,
      rightGrip: rightGrip ?? this.rightGrip,
    );
  }
}

const List<_Profile> _JcPresets = [
  const _Profile(
    name: 'Gray',
    body: _Profile.Gray,
    button: const Color(0xFF0F0F0F),
  ),
  const _Profile(
    name: 'Red',
    body: _Profile.Red,
    button: const Color(0xFF280A0A),
  ),
  const _Profile(
    name: 'Blue',
    body: _Profile.Blue,
    button: const Color(0xFF00000A),
  ),
  const _Profile(
    name: 'Neon Red',
    body: _Profile.NeonRed,
    button: const Color(0xFF1E0A0A),
  ),
  const _Profile(
    name: 'Neon Blue',
    body: _Profile.NeonBlue,
    button: const Color(0xFF001E1E),
  ),
  const _Profile(
    name: 'Neon Pink',
    body: _Profile.NeonPink,
    button: const Color(0xFF28001E),
  ),
  const _Profile(
    name: 'Neon Green',
    body: _Profile.NeonGreen,
    button: const Color(0xFF002800),
  ),
  const _Profile(
    name: 'Neon Yellow',
    body: _Profile.NeonYellow,
    button: const Color(0xFF142800),
  ),
  const _Profile(
    name: 'Neon Orange',
    body: _Profile.NeonOrange,
    button: const Color(0xFF0F0A00),
  ),
  const _Profile(
    name: 'Neon Purple',
    body: _Profile.NeonPurple,
    button: const Color(0xFF140014),
  ),
  const _Profile(
    name: "Pokemon Let's Go! Pikachu",
    body: _Profile.Pikachu,
    button: const Color(0xFF322800),
  ),
  const _Profile(
    name: "Pokemon Let's Go! Eevee",
    body: _Profile.Eevee,
    button: const Color(0xFF281900),
  ),
  const _Profile(
    name: "Labo Creators Contest Edition",
    body: _Profile.Labo,
    button: const Color(0xFF1E1914),
  ),
];

const List<_Profile> _ProPresets = [
  const _Profile(
    name: "Black",
    body: const Color(0xFF323232),
    button: const Color(0xFFAAAAAA),
    leftGrip: _Profile.Gray,
    rightGrip: _Profile.Gray,
    code: const Color(0xFF323232),
  ),
  const _Profile(
    name: "Splatoon 2",
    body: const Color(0xFF313232),
    button: const Color(0xFFDDDDDD),
    leftGrip: _Profile.NeonGreen,
    rightGrip: _Profile.NeonPink,
    code: const Color(0xFF313232),
  ),
  const _Profile(
    name: "Xenoblade 2",
    body: const Color(0xFF323132),
    button: const Color(0xFFDDDDDD),
    leftGrip: _Profile.Red,
    rightGrip: _Profile.Red,
    code: const Color(0xFF323132),
  ),
];

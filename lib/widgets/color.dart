import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:joycon/bluetooth/bluetooth.dart';
import 'package:joycon/bluetooth/controller.dart';
//import 'dart:ui' as ui;

import 'package:provider/provider.dart';

class ColorWidget extends StatelessWidget {
  final List<String> _outlines = const [
    'assets/image/pro_controller_outline.png',
    'assets/image/joycon_l_outline.png',
    'assets/image/joycon_r_outline.png',
  ];

  const ColorWidget({Key key}) : super(key: key);

  /*
  Future<ui.Image> _loadAssetImage(BuildContext context, String file) {
    return DefaultAssetBundle.of(context)
        .load(file)
        .then((data) => data.buffer.asUint8List())
        .then((list) => ui.instantiateImageCodec(list))
        .then((codec) => codec.getNextFrame())
        .then((frame) => frame.image);
  }

  Widget _buildColorCard(BuildContext context) {
    return FutureProvider<List<ui.Image>>(
      create: (context) => Future.wait([
        _loadAssetImage(context, _body),
        _loadAssetImage(context, _leftGrip),
        _loadAssetImage(context, _rightGrip),
      ]),
      child: Consumer<List<ui.Image>>(
        builder: (_, value, __) {
          if (value == null) return SizedBox();
          return Card(
            margin: const EdgeInsets.all(8),
            child: CustomPaint(
              willChange: true,
              isComplex: false,
              painter: _LayerPainter(
                body: value[0],
                bodyColor: Colors.black,
                gripLeft: value[1],
                gripLeftColor: Colors.blue,
                gripRight: value[2],
                gripRightColor: Colors.redAccent,
              ),
            ),
          );
        },
      ),
    );
  }
*/
  void _showBlockColorPicker(BuildContext context, String label, _Holder h) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(8),
          title: Text(label),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: h.color,
              onColorChanged: (color) => h.color = color,
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

  void _showDetailColorPicker(BuildContext context, String label, _Holder h) {
    showDialog(
      context: context,
      builder: (_) => Center(
        child: AlertDialog(
          contentPadding: const EdgeInsets.all(8),
          title: Text(label),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: h.color,
              onColorChanged: (color) => h.color = color,
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

  Widget _buildPickerButton(BuildContext context, String label, _Holder h) {
    Color foregroundColor =
        ThemeData.estimateBrightnessForColor(h.color) == Brightness.light
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
              color: h.color,
              child: InkWell(
                onTap: () => _showDetailColorPicker(context, label, h),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '#${h.color.value.toRadixString(16)}'.toUpperCase(),
                          style: textTheme.caption
                              .copyWith(color: foregroundColor),
                        ),
                      ),
                      Icon(Icons.colorize, size: 20, color: foregroundColor),
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
    final device = Provider.of<Controller>(context, listen: false).device;
    final index = _getDeviceIndex(device);
    final List<Widget> children = [
      ColorFiltered(
        colorFilter: ColorFilter.mode(
            Color(Colors.white.value - bgColor.value).withOpacity(1),
            BlendMode.srcIn),
        child: Image.asset(_outlines[index]),
      ),
      Consumer<_BodyHolder>(
        child: Image.asset(_BodyHolder.of(context).assets[index]),
        builder: (_, holder, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(holder.color, BlendMode.srcIn),
            child: child,
          );
        },
      ),
      Consumer<_ButtonHolder>(
        child: Image.asset(_ButtonHolder.of(context).assets[index]),
        builder: (_, holder, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.mode(holder.color, BlendMode.srcIn),
            child: child,
          );
        },
      ),
    ];
    if (index == 0) {
      children.addAll([
        Consumer<_LeftGripHolder>(
          child: Image.asset(_LeftGripHolder.of(context).assets[index]),
          builder: (_, holder, child) {
            return ColorFiltered(
              colorFilter: ColorFilter.mode(holder.color, BlendMode.srcIn),
              child: child,
            );
          },
        ),
        Consumer<_RightGripHolder>(
          child: Image.asset(_RightGripHolder.of(context).assets[index]),
          builder: (_, holder, child) {
            return ColorFiltered(
              colorFilter: ColorFilter.mode(holder.color, BlendMode.srcIn),
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
    final device = Provider.of<Controller>(context, listen: false).device;
    final index = _getDeviceIndex(device);
    final List<Widget> children = [
      Consumer<_BodyHolder>(
        builder: (context, holder, _) {
          return _buildPickerButton(context, 'body', holder);
        },
      ),
      Consumer<_ButtonHolder>(
        builder: (context, holder, _) {
          return _buildPickerButton(context, 'button', holder);
        },
      ),
    ];
    if (index == 0) {
      children.addAll([
        Consumer<_LeftGripHolder>(
          builder: (context, holder, _) {
            return _buildPickerButton(context, 'left grip', holder);
          },
        ),
        Consumer<_RightGripHolder>(
          builder: (context, holder, _) {
            return _buildPickerButton(context, 'right grip', holder);
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
            leading: Icon(Icons.palette),
            title: Center(
              child: Consumer<ValueNotifier<_Profile>>(
                builder: (c, v, __) {
                  return DropdownButton<_Profile>(
                    isDense: true,
                    isExpanded: true,
                    iconSize: 14,
                    value: v.value,
                    items: (index == 0 ? _pro_presets : _jc_presets)
                        .map((e) => DropdownMenuItem<_Profile>(
                              value: e,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(e.name),
                              ),
                            ))
                        .toList(growable: false),
                    onChanged: (vv) {
                      v.value = vv;
                      _BodyHolder.of(c).color = vv.body;
                      _ButtonHolder.of(c).color = vv.button;
                      _LeftGripHolder.of(c).color = vv.leftGrip;
                      _RightGripHolder.of(c).color = vv.rightGrip;
                    },
                  );
                },
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                final Color body = _BodyHolder.of(context).color;
                final Color button = _ButtonHolder.of(context).color;
                final Color lGrip = _LeftGripHolder.of(context).color;
                final Color rGrip = _RightGripHolder.of(context).color;
                print('$body, $button, $lGrip, $rGrip');
                Controller controller =
                    Provider.of<Controller>(context, listen: false);
                controller.setColor(body, button, lGrip, rGrip);
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
    final device = Provider.of<Controller>(context, listen: false).device;
    final index = _getDeviceIndex(device);
    final _Profile profile = (index == 0 ? _pro_presets : _jc_presets)[0];
    return MultiProvider(
      providers: [
        ListenableProvider(
          create: (_) => ValueNotifier<_Profile>(profile),
          dispose: (_, v) => v.dispose(),
        ),
        ListenableProvider<_BodyHolder>(
          create: (_) => _BodyHolder(profile.body),
          dispose: (_, v) => v.dispose(),
        ),
        ListenableProvider<_ButtonHolder>(
          create: (_) => _ButtonHolder(profile.button),
          dispose: (_, v) => v.dispose(),
        ),
        ListenableProvider<_LeftGripHolder>(
          create: (_) => _LeftGripHolder(profile.leftGrip),
          dispose: (_, v) => v.dispose(),
        ),
        ListenableProvider<_RightGripHolder>(
          create: (_) => _RightGripHolder(profile.rightGrip),
          dispose: (_, v) => v.dispose(),
        ),
      ],
      child: ListView(
        children: <Widget>[
          Builder(builder: (context) => _buildColorCard2(context)),
        ],
      ),
    );
  }

  static int _getDeviceIndex(BluetoothDevice device) {
    switch (device.name) {
      case 'Pro Controller':
        return 0;
      case 'Joy-Con (L)':
        return 1;
      case 'Joy-Con (R)':
        return 2;
      default:
        throw ArgumentError.value(device.name);
    }
  }
}

/*
class _LayerPainter extends CustomPainter {
  final ui.Image body;
  final ui.Image gripLeft;
  final ui.Image gripRight;
  final Color bodyColor;
  final Color gripLeftColor;
  final Color gripRightColor;

  const _LayerPainter(
      {this.body,
      this.bodyColor,
      this.gripLeft,
      this.gripLeftColor,
      this.gripRight,
      this.gripRightColor,
      Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    final double r = size.width / body.width;
    paint.imageFilter =
        ui.ImageFilter.matrix(Matrix4.diagonal3Values(r, r, 1).storage);
    paint.colorFilter = ColorFilter.mode(bodyColor, BlendMode.srcIn);
    canvas.drawImage(body, Offset.zero, paint);
    paint.colorFilter = ColorFilter.mode(gripLeftColor, BlendMode.srcIn);
    canvas.drawImage(gripLeft, Offset.zero, paint);
    paint.colorFilter = ColorFilter.mode(gripRightColor, BlendMode.srcIn);
    canvas.drawImage(gripRight, Offset.zero, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
 */
abstract class _Holder extends ChangeNotifier {
  final List<String> assets;
  Color _color;

  _Holder({this.assets, Color color}) : _color = color;

  Color get color => _color;

  set color(Color color) {
    _color = color;
    notifyListeners();
  }
}

class _BodyHolder extends _Holder implements ValueListenable<_BodyHolder> {
  _BodyHolder(Color color)
      : super(
          assets: [
            'assets/image/pro_controller_body.png',
            'assets/image/joycon_l.png',
            'assets/image/joycon_r.png',
          ],
          color: color,
        );

  @override
  _BodyHolder get value => this;

  static _BodyHolder of(BuildContext context) =>
      Provider.of<_BodyHolder>(context, listen: false);
}

class _ButtonHolder extends _Holder implements ValueListenable<_ButtonHolder> {
  _ButtonHolder(Color color)
      : super(
          assets: [
            'assets/image/pro_controller_button.png',
            'assets/image/joycon_l_button.png',
            'assets/image/joycon_r_button.png',
          ],
          color: color,
        );

  @override
  _ButtonHolder get value => this;

  static _ButtonHolder of(BuildContext context) =>
      Provider.of<_ButtonHolder>(context, listen: false);
}

class _LeftGripHolder extends _Holder
    implements ValueListenable<_LeftGripHolder> {
  _LeftGripHolder(Color color)
      : super(
          assets: ['assets/image/pro_controller_grip_left.png'],
          color: color,
        );

  @override
  _LeftGripHolder get value => this;

  static _LeftGripHolder of(BuildContext context) =>
      Provider.of<_LeftGripHolder>(context, listen: false);
}

class _RightGripHolder extends _Holder
    implements ValueListenable<_RightGripHolder> {
  _RightGripHolder(Color color)
      : super(
          assets: ['assets/image/pro_controller_grip_right.png'],
          color: color,
        );

  @override
  _RightGripHolder get value => this;

  static _RightGripHolder of(BuildContext context) =>
      Provider.of<_RightGripHolder>(context, listen: false);
}

class _Profile {
  final String name;
  final Color body;
  final Color button;
  final Color leftGrip;
  final Color rightGrip;

  const _Profile({
    @required this.name,
    @required this.body,
    this.button = const Color(0xFFFFFFFF),
    this.leftGrip = const Color(0xFFFFFFFF),
    this.rightGrip = const Color(0xFFFFFFFF),
  });
}

final List<_Profile> _jc_presets = [
  _p_gray,
  _p_red,
  _p_blue,
  _p_neon_red,
  _p_neon_blue,
  _p_neon_pink,
  _p_neon_green,
  _p_neon_yellow,
  _p_neon_orange,
  _p_neon_purple,
  _p_pikachu,
  _p_eevee,
  _p_labo,
];

final List<_Profile> _pro_presets = [
  _p_pro_black,
  _p_pro_splatoon,
  _p_pro_xenoblade,
];

final _Profile _p_gray = _Profile(
  name: 'Gray',
  body: const Color(0xFF828282),
  button: const Color(0xFF0F0F0F),
);

final _Profile _p_neon_red = _Profile(
  name: 'Neon Red',
  body: const Color(0xFFFF3C28),
  button: const Color(0xFF1E0A0A),
);

final _Profile _p_neon_blue = _Profile(
  name: 'Neon Blue',
  body: const Color(0xFF0AB9E6),
  button: const Color(0xFF001E1E),
);

final _Profile _p_neon_yellow = _Profile(
  name: 'Neon Yellow',
  body: const Color(0xFFE6FF00),
  button: const Color(0xFF142800),
);

final _Profile _p_neon_green = _Profile(
  name: 'Neon Green',
  body: const Color(0xFF1EDC00),
  button: const Color(0xFF002800),
);

final _Profile _p_neon_pink = _Profile(
  name: 'Neon Pink',
  body: const Color(0xFFFF3278),
  button: const Color(0xFF28001E),
);

final _Profile _p_red = _Profile(
  name: 'Red',
  body: const Color(0xFFE10F00),
  button: const Color(0xFF280A0A),
);

final _Profile _p_blue = _Profile(
  name: 'Blue',
  body: const Color(0xFF4655F5),
  button: const Color(0xFF00000A),
);

final _Profile _p_neon_purple = _Profile(
  name: 'Neon Purple',
  body: const Color(0xFFB400E6),
  button: const Color(0xFF140014),
);

final _Profile _p_neon_orange = _Profile(
  name: 'Neon Orange',
  body: const Color(0xFFFAA005),
  button: const Color(0xFF0F0A00),
);

final _Profile _p_pikachu = _Profile(
  name: "Pokemon Let's Go! Pikachu",
  body: const Color(0xFFFFDC00),
  button: const Color(0xFF322800),
);

final _Profile _p_eevee = _Profile(
  name: "Pokemon Let's Go! Eevee",
  body: const Color(0xFFC88C32),
  button: const Color(0xFF281900),
);

final _Profile _p_labo = _Profile(
  name: "Nintendo Labo Creators Contest Edition",
  body: const Color(0xFFD7AA73),
  button: const Color(0xFF1E1914),
);

final _Profile _p_pro_black = _Profile(
  name: "Black",
  body: const Color(0xFF323232),
);

final _Profile _p_pro_splatoon = _Profile(
  name: "Splatoon 2",
  body: const Color(0xFF313232),
);

final _Profile _p_pro_xenoblade = _Profile(
  name: "Xenoblade 2",
  body: const Color(0xFF323132),
);

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:joycon/bloc.dart';
import 'package:joycon/bluetooth/bluetooth.dart';
import 'package:joycon/permission.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  final Duration _duration = const Duration(seconds: 1);

  void waitBeg() {
    if (!_controller.isAnimating) _controller.repeat();
  }

  void waitEnd() {
    if (_controller.isAnimating) _controller.animateTo(1.0);
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: _duration);
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
    PermissionHandler()
        .checkPermissionStatus(PermissionGroup.locationWhenInUse)
        .then((permission) {
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.disabled) {
        PermissionHandler().requestPermissions(
            [PermissionGroup.locationWhenInUse]).then((permissions) {
          PermissionStatus permission =
              permissions[PermissionGroup.locationWhenInUse];
          print(permission);
          if (permission != PermissionStatus.granted &&
              permission != PermissionStatus.disabled) {
            showDialog(
              context: context,
              barrierDismissible: true,
              useRootNavigator: true,
              builder: (context) => Center(
                child: Permission(),
              ),
            );
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.bodyText2;
    final String link = 'https://github.com/mumumusuc/jc-toolkit-linux';
    return Scaffold(
      appBar: AppBar(
        title: Text('Joy-Con Toolkit'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => SystemNavigator.pop(animated: true),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationIcon: CircleAvatar(
                  child: Image.asset(
                    'assets/image/joycon_d.png',
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
                ),
                applicationName: 'Joy-Con Toolkit',
                applicationVersion: '0.0.1 Feb 2020',
                applicationLegalese: '© 2020 mumumusuc',
                children: [
                  SizedBox(height: 24),
                  RichText(
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(
                            style: textStyle,
                            text: 'Learn more about Joy-Con Toolkit at '),
                        TextSpan(
                          style: textStyle.copyWith(
                            color: Theme.of(context).accentColor,
                          ),
                          text: link,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              if (await canLaunch(link)) {
                                launch(link);
                              }
                            },
                        ),
                        TextSpan(style: textStyle, text: '.'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Selector<BluetoothDeviceMap, int>(
        selector: (context, map) => map.devices.length,
        builder: (context, length, child) {
          if (length == 0)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/image/empty.svg',
                    semanticsLabel: 'empty',
                  ),
                  Text(
                    'No device found',
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                ],
              ),
            );
          return ListView(
            primary: true,
            padding: const EdgeInsets.all(8),
            children: BluetoothDeviceMap.of(context).devices.map((it) {
              return Selector<BluetoothDeviceMap, BluetoothDeviceMeta>(
                selector: (context, map) => map[it.key],
                builder: (context, meta, child) {
                  return _DeviceCard(it.key, meta);
                },
              );
            }).toList(growable: false),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Bloc.of(context).bluetooth.discovery(true),
        tooltip: 'discovery',
        child: AnimatedBuilder(
          animation: _animation,
          child: const Icon(Icons.refresh),
          builder: (context, child) {
            final BluetoothState state = Provider.of<BluetoothState>(context);
            if (state == BluetoothState.DISCOVER_ON)
              waitBeg();
            else if (state == BluetoothState.DISCOVER_OFF) waitEnd();
            return Transform.rotate(angle: _animation.value, child: child);
          },
        ),
      ),
    );
  }
}

class _DeviceCard extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothDeviceMeta meta;

  const _DeviceCard(this.device, this.meta, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<_DeviceCard>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  CurvedAnimation _curve;
  ColorTween _colorTween;
  Widget _lastState;
  Widget _thisState;
  Widget _lastTailing;
  Widget _thisTailing;

  BluetoothDevice get device => widget.device;

  BluetoothDeviceState get state => widget.meta.state;

  Color _getStateColor(BluetoothDeviceState state) {
    switch (state) {
      case BluetoothDeviceState.CONNECTED:
        return Colors.lightGreen;
      case BluetoothDeviceState.CONNECTING:
      case BluetoothDeviceState.DISCONNECTED:
      case BluetoothDeviceState.PAIRED:
        return Colors.limeAccent;
      default:
        return Colors.transparent;
    }
  }

  Widget _getStateTailing(BluetoothDeviceState state) {
    Widget w = SizedBox();
    switch (state) {
      case BluetoothDeviceState.CONNECTED:
        w = IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Bloc.of(context).bluetooth.connect(device, false),
        );
        break;
      case BluetoothDeviceState.PAIRED:
        w = const Icon(Icons.bluetooth_disabled);
        break;
      case BluetoothDeviceState.PAIRING:
      case BluetoothDeviceState.CONNECTING:
        w = const SizedBox(
          width: 20,
          height: 20,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      default:
        break;
    }
    return SizedOverflowBox(size: const Size(24, 24), child: w);
  }

  String _getStateString(BluetoothDeviceState state) {
    switch (state) {
      case BluetoothDeviceState.PAIRING:
        return 'Pairing';
      case BluetoothDeviceState.PAIRED:
        return 'Paired';
      case BluetoothDeviceState.CONNECTING:
        return 'Connecting';
      case BluetoothDeviceState.CONNECTED:
        return 'Connected';
      default:
        return '';
    }
  }

  @override
  void initState() {
    final Duration duration = const Duration(milliseconds: 350);
    _controller = AnimationController(vsync: this, duration: duration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _colorTween = ColorTween(begin: _getStateColor(state));
    _thisState = _lastState = Text(_getStateString(state));
    _thisTailing = _lastTailing = _getStateTailing(state);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DeviceCard oldWidget) {
    if (widget.meta != oldWidget.meta) {
      _lastTailing = _getStateTailing(oldWidget.meta.state);
      _thisTailing = _getStateTailing(state);
      _lastState = Text(_getStateString(oldWidget.meta.state));
      _thisState = Text(_getStateString(state));
      _colorTween.begin = _getStateColor(oldWidget.meta.state);
      _colorTween.end = _getStateColor(state);
      _controller.reset();
      _controller.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LimitedBox(
      maxHeight: 80,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final Color color = _colorTween.evaluate(_curve);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.5, 0),
                  colors: [
                    color == Colors.transparent
                        ? color
                        : Theme.of(context).cardColor,
                    color,
                  ],
                ),
              ),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              isThreeLine: false,
              leading: CircleAvatar(
                child: Image.asset(
                  selectDeviceIcon(device),
                  width: 24,
                  height: 24,
                ),
              ),
              title: Text(device.name),
              subtitle: AnimatedBuilder(
                animation: _controller,
                child: Text(device.address),
                builder: (_, child) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    child,
                    const SizedBox(
                      height: 12,
                      child: const VerticalDivider(),
                    ),
                    Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[
                        Opacity(
                          opacity: 1 - _curve.value,
                          child: _lastState,
                        ),
                        Opacity(
                          opacity: _curve.value,
                          child: _thisState,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              onTap: () {
                if (state == BluetoothDeviceState.CONNECTED) {
                  Navigator.pushNamed(context, '/device', arguments: device);
                } else {
                  Bloc.of(context).bluetooth.connect(device, true);
                }
              },
              trailing: AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Opacity(
                        opacity: 1 - _curve.value,
                        child: _lastTailing,
                      ),
                      Opacity(
                        opacity: _curve.value,
                        child: _thisTailing,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

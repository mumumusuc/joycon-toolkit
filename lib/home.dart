import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'bloc.dart';
import 'bluetooth/bluetooth.dart';
import 'generated/i18n.dart';
import 'permission.dart';
import 'widgets/fade.dart';

const Duration _kDuration = const Duration(milliseconds: 300);
const String _githubUrl = 'https://github.com/mumumusuc/joycon-toolkit';

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends PermissionState<HomePage> {
  @override
  Widget build(BuildContext context) {
    //print('build home');
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        textTheme: theme.textTheme,
        iconTheme: theme.iconTheme,
        actionsIconTheme: theme.iconTheme,
        title: Text(S.of(context).app_title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => SystemNavigator.pop(animated: true),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () => _buildAboutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Selector<BluetoothState, bool>(
              selector: (_, s) => s != BluetoothState.DISABLED,
              builder: (context, hide, child) {
                return FadeWidget(
                  fade: hide,
                  child: _buildBluetoothBanner(context),
                );
              },
            ),
            buildPermissionBanner(
              container: (child) => Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[const Divider(height: 3), child],
              ),
            ),
            buildServiceBanner(
              container: (child) => Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[const Divider(height: 3), child],
              ),
            ),
            const Divider(),
            Selector<BluetoothDeviceMap, int>(
              selector: (context, map) => map.devices.length,
              builder: (context, length, child) {
                return _ListWidget(
                  children: length == 0
                      ? null
                      : BluetoothDeviceMap.of(context)
                          .devices
                          .map<Widget>((it) {
                          return Selector<BluetoothDeviceMap,
                              BluetoothDeviceMeta>(
                            selector: (context, map) => map[it.key],
                            builder: (context, meta, child) {
                              return _DeviceCard(it.key, meta);
                            },
                          );
                        }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<BluetoothState>(
        builder: (context, state, child) {
          print(state);
          switch (state) {
            case BluetoothState.DISABLED:
              return _DiscoveryWidget(false);
            case BluetoothState.DISCOVER_ON:
              return _DiscoveryWidget(
                true,
                onPressed: () => Bloc.of(context).bluetooth.discovery(false),
              );
            case BluetoothState.ENABLED:
            case BluetoothState.TURNING_ON:
            case BluetoothState.DISCOVER_OFF:
            default:
              return _DiscoveryWidget(
                false,
                onPressed: () async {
                  if (await isPermissionReady(showBanner: true))
                    Bloc.of(context).bluetooth.discovery(true);
                },
              );
          }
        },
      ),
    );
  }

  Widget _buildBluetoothBanner(BuildContext context) {
    return MaterialBanner(
      leading: const CircleAvatar(
        child: const Icon(Icons.bluetooth),
      ),
      leadingPadding: const EdgeInsets.only(
        right: 16,
        top: 16,
        bottom: 16,
      ),
      content: Text(S.of(context).perm_bluetooth),
      actions: [
        FlatButton(
          child: Text(S.of(context).action_ok),
          onPressed: () => Bloc.of(context).bluetooth.enable(true),
        ),
      ],
    );
  }

  void _buildAboutDialog(BuildContext context) {
    final TextStyle textStyle = Theme.of(context).textTheme.bodyText2;
    showAboutDialog(
      context: context,
      applicationIcon: ClipOval(
        child: CircleAvatar(
          child: Image.asset('assets/image/icon.png'),
        ),
      ),
      applicationName: S.of(context).app_title,
      applicationVersion: '0.0.2 Feb 2020',
      applicationLegalese: '© 2020 mumumusuc',
      children: [
        SizedBox(height: 24),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                style: textStyle,
                text: S.of(context).about_desc,
              ),
              TextSpan(
                style: textStyle.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontStyle: FontStyle.italic,
                ),
                text: _githubUrl,
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    if (await canLaunch(_githubUrl)) {
                      launch(_githubUrl);
                    }
                  },
              ),
              TextSpan(style: textStyle, text: '.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListWidget extends StatelessWidget {
  final List<Widget> children;

  const _ListWidget({@required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: AnimatedCrossFade(
        firstCurve: Curves.easeInOut,
        secondCurve: Curves.easeInOut,
        sizeCurve: Curves.easeInOut,
        firstChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/image/empty.svg',
              semanticsLabel: 'empty',
            ),
            Text(
              S.of(context).no_device,
              style: Theme.of(context).textTheme.caption,
            ),
          ],
        ),
        secondChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: children ?? [],
        ),
        crossFadeState: children?.isNotEmpty == true
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: _kDuration,
        layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
          return Stack(
            overflow: Overflow.visible,
            alignment: AlignmentDirectional.topCenter,
            children: <Widget>[
              bottomChild,
              topChild,
            ],
          );
        },
      ),
    );
  }
}

class _DiscoveryWidget extends StatefulWidget {
  final bool discovering;
  final VoidCallback onPressed;

  const _DiscoveryWidget(this.discovering, {this.onPressed});

  bool get disabled => onPressed == null;

  @override
  State<StatefulWidget> createState() => _DiscoveryWidgetState();
}

class _DiscoveryWidgetState extends State<_DiscoveryWidget>
    with TickerProviderStateMixin {
  AnimationController _rotate;
  AnimationController _scale;

  bool get discovering => widget.discovering;

  bool get disabled => widget.disabled;

  @override
  void initState() {
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scale = AnimationController(vsync: this, duration: _kDuration);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _rotate.dispose();
    _scale.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.0)
          .animate(CurvedAnimation(parent: _scale, curve: Curves.easeInOut)),
      child: FloatingActionButton(
        tooltip: 'discovery',
        child: AnimatedBuilder(
          child: const Icon(Icons.refresh),
          animation: _rotate,
          builder: (context, child) {
            return Transform.rotate(
              angle: 2 * pi * _rotate.value,
              child: child,
            );
          },
        ),
        onPressed: widget.onPressed,
      ),
    );
  }

  @override
  void didUpdateWidget(_DiscoveryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discovering != discovering) {
      if (discovering)
        _rotate.repeat();
      else
        _rotate.animateTo(1);
    }
    if (oldWidget.disabled != disabled) {
      if (disabled)
        _scale.forward();
      else
        _scale.reverse();
    }
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

  Color _getStateColor(BuildContext context, BluetoothDeviceState state) {
    if (context == null) return null;
    switch (state) {
      case BluetoothDeviceState.CONNECTED:
      case BluetoothDeviceState.CONNECTING:
      case BluetoothDeviceState.DISCONNECTING:
        return Theme.of(context).colorScheme.primary;
      default:
        return Theme.of(context).cardColor;
    }
  }

  Widget _getStateTrailing(BluetoothDeviceState state) {
    Widget w = SizedBox();
    switch (state) {
      case BluetoothDeviceState.CONNECTED:
        w = IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Bloc.of(context).bluetooth.connect(device, false),
        );
        break;
      case BluetoothDeviceState.PAIRED:
        w = const Icon(Icons.bluetooth_connected);
        break;
      case BluetoothDeviceState.PAIRING:
      case BluetoothDeviceState.CONNECTING:
      case BluetoothDeviceState.DISCONNECTING:
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

  String _getStateString(BuildContext context, BluetoothDeviceState state) {
    switch (state) {
      case BluetoothDeviceState.PAIRING:
        return S.of(context).device_state_pairing;
      case BluetoothDeviceState.PAIRED:
        return S.of(context).device_state_paired;
      case BluetoothDeviceState.CONNECTING:
        return S.of(context).device_state_connecting;
      case BluetoothDeviceState.DISCONNECTING:
        return S.of(context).device_state_disconnecting;
      case BluetoothDeviceState.CONNECTED:
        return S.of(context).device_state_connected;
      default:
        return '';
    }
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: _kDuration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _colorTween = ColorTween();
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
      _lastTailing = _getStateTrailing(oldWidget.meta.state);
      _thisTailing = _getStateTrailing(state);
      _lastState = Text(_getStateString(context, oldWidget.meta.state));
      _thisState = Text(_getStateString(context, state));
      _colorTween.begin = _getStateColor(context, oldWidget.meta.state);
      _colorTween.end = _getStateColor(context, state);
      _controller.reset();
      _controller.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    switch (_controller.status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.reverse:
        _colorTween.begin = _getStateColor(context, state);
        break;
      default:
        _colorTween.end = _getStateColor(context, state);
        break;
    }
    _thisState ??= _lastState ??= Text(_getStateString(context, state));
    _thisTailing ??= _lastTailing ??= _getStateTrailing(state);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color contentColor =
        widget.meta.state == BluetoothDeviceState.CONNECTED
            ? theme.colorScheme.onPrimary
            : null;
    _colorTween.begin ??= _getStateColor(context, state);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LimitedBox(
        maxHeight: 80,
        child: AnimatedBuilder(
          animation: _controller,
          child: AnimatedBuilder(
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
          builder: (context, child) {
            return Material(
              borderRadius: BorderRadius.circular(12),
              elevation: 0,
              clipBehavior: Clip.hardEdge,
              color: _colorTween.evaluate(_controller),
              child: ListTileTheme(
                textColor: contentColor,
                iconColor: contentColor,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Image.asset(
                      selectDeviceIcon(device),
                      color: theme.colorScheme.onPrimary,
                      width: 24,
                      height: 24,
                    ),
                  ),
                  title: Text(device.name),
                  subtitle: child,
                  onTap: () {
                    if (state == BluetoothDeviceState.CONNECTED) {
                      Navigator.pushNamed(context, '/device',
                          arguments: device);
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
            );
          },
        ),
      ),
    );
  }
}

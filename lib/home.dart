import 'package:animations/animations.dart';
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
import 'widgets/controller.dart';
import 'widgets/fade.dart';

const String _githubUrl = 'https://github.com/mumumusuc/joycon-toolkit';
const ShapeBorder _cardBorder = const RoundedRectangleBorder(
  borderRadius: const BorderRadius.all(const Radius.circular(20.0)),
);
const String _svgDot =
    '''<svg style="width:24px;height:24px" viewBox="0 0 24 24">
    <path fill="#FFF" d="M12,10A2,2 0 0,0 10,12C10,13.11 10.9,14 12,14C13.11,14 14,13.11 14,12A2,2 0 0,0 12,10Z" />
</svg>''';

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
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(
            const Size.fromWidth(kPageMaxWidth),
          ),
          child: SingleChildScrollView(
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
                    children: [const Divider(height: 3), child],
                  ),
                ),
                buildServiceBanner(
                  container: (child) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [const Divider(height: 3), child],
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
                                  print('build device selector');
                                  final Widget card = _DeviceCard(it.key, meta);
                                  return Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: card,
                                  );
                                },
                              );
                            }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
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
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle = theme.textTheme.bodyText2;
    showAboutDialog(
      context: context,
      applicationIcon: ClipOval(
        child: CircleAvatar(
          child: SvgPicture.asset('assets/image/icon.svg'),
        ),
      ),
      applicationName: S.of(context).app_title,
      applicationVersion: '0.0.4 Feb 2020',
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
                style: hyperLinkTextStyle,
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
            SvgPicture.asset('assets/image/empty.svg'),
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
        duration: kDuration,
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
    _scale = AnimationController(vsync: this, duration: kDuration);
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
  ColorTween _color;
  String _lastState;
  String _thisState;
  Widget _lastTailing;
  Widget _thisTailing;

  BluetoothDevice get _device => widget.device;

  BluetoothDeviceState get _state => widget.meta.state;

  Widget get _pairedTrailing => Icon(Icons.bluetooth_connected);

  Widget get _connectedTrailing => IconButton(
        icon: const Icon(Icons.close),
        onPressed: _disconnect,
      );

  Widget get _waitingTrailing => SizedBox(
        width: 20,
        height: 20,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );

  Color _getStateColor(BluetoothDeviceState state) {
    switch (state) {
      case BluetoothDeviceState.CONNECTED:
        return Theme.of(context).colorScheme.primary;
      case BluetoothDeviceState.CONNECTING:
      case BluetoothDeviceState.DISCONNECTING:
        return Theme.of(context).colorScheme.primary.withOpacity(0.5);
      default:
        return Theme.of(context).cardColor;
    }
  }

  Widget _getStateTrailing(BluetoothDeviceState state) {
    Widget w = SizedBox();
    switch (state) {
      case BluetoothDeviceState.CONNECTED:
        w = _connectedTrailing;
        break;
      case BluetoothDeviceState.PAIRED:
        w = _pairedTrailing;
        break;
      case BluetoothDeviceState.PAIRING:
      case BluetoothDeviceState.CONNECTING:
      case BluetoothDeviceState.DISCONNECTING:
        w = _waitingTrailing;
        break;
      default:
        break;
    }
    return SizedOverflowBox(size: const Size(24, 24), child: w);
  }

  String _getStateString(BluetoothDeviceState state) {
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

  void _disconnect() => Bloc.of(context).bluetooth.connect(_device, false);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kDuration);
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _color = ColorTween();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DeviceCard oldWidget) {
    print('didUpdateWidget');
    if (widget.meta != oldWidget.meta) {
      _lastTailing = _getStateTrailing(_state);
      _thisTailing = _getStateTrailing(_state);
      _lastState = _getStateString(oldWidget.meta.state);
      _thisState = _getStateString(_state);
      _color.begin = _getStateColor(oldWidget.meta.state);
      _color.end = _getStateColor(_state);
      _controller.reset();
      _controller.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('didChangeDependencies');
    switch (_controller.status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.reverse:
        _color.begin = _getStateColor(_state);
        break;
      default:
        _color.end = _getStateColor(_state);
        break;
    }
    _thisState ??= _lastState ??= _getStateString(_state);
    _thisTailing ??= _lastTailing ??= _getStateTrailing(_state);
  }

  @override
  Widget build(BuildContext context) {
    print('build DeviceCard');
    final ThemeData theme = Theme.of(context);
    final Color contentColor = _state == BluetoothDeviceState.CONNECTED
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;
    final Widget icon = CircleAvatar(
      child: getDeviceIcon(
        _device,
        size: const Size.fromRadius(12),
        color: theme.colorScheme.onPrimary,
      ),
    );
    final Widget from = ListTileTheme(
      textColor: contentColor,
      iconColor: contentColor,
      child: ListTile(
        leading: icon,
        title: Text(_device.name),
        subtitle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_device.address),
            SvgPicture.string(_svgDot, color: contentColor),
            _buildState(),
          ],
        ),
        trailing: _buildTrailing(),
      ),
    );
    /*
    final Widget to = Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );*/
    final Widget to = ControllerWidget(device: _device);
    return _buildContainer(context, from, to);
  }

  Widget _buildContainer(BuildContext context, Widget from, Widget to) {
    return OpenContainer(
      tappable: true,
      transitionDuration: kDuration,
      closedShape: _cardBorder,
      closedColor: _color.evaluate(_curve),
      closedElevation: 0,
      closedBuilder: (_, __) {
        //print('closedBuilder');
        return from;
      },
      openBuilder: (c, __) {
        //print('openBuilder');
        return to;
      },
    );
  }

  Widget _buildState() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Stack(
        alignment: Alignment.centerLeft,
        children: [
          Opacity(
            opacity: 1 - _curve.value,
            child: Text(_lastState),
          ),
          Opacity(
            opacity: _curve.value,
            child: Text(_thisState),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailing() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 1 - _curve.value,
            child: _lastTailing,
          ),
          Opacity(
            opacity: _curve.value,
            child: _thisTailing,
          ),
        ],
      ),
    );
  }
}

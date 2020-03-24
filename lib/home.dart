import 'dart:io';

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
import 'package:community_material_icon/community_material_icon.dart';
import 'dart:math';
import 'bloc.dart';
import 'bluetooth/bluetooth.dart';
import 'device.dart';
import 'generated/i18n.dart';
import 'permission.dart';
import 'widgets/expand.dart';
import 'widgets/icon_text.dart';
import 'widgets/option.dart';

const String _githubUrl = 'https://github.com/mumumusuc/joycon-toolkit';
const ShapeBorder _cardBorder = const RoundedRectangleBorder(
  borderRadius: const BorderRadius.all(const Radius.circular(20.0)),
);

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  State<StatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends PermissionState<HomePage> {
  @override
  Widget build(BuildContext context) {
    print('HomePage -> build');
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => SystemNavigator.pop(animated: true),
        ),
        actions: _buildActions(context),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(
            const Size.fromWidth(kPageMaxWidth),
          ),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverToBoxAdapter(
                child: Selector<BluetoothState, bool>(
                  selector: (_, s) => s == BluetoothState.DISABLED,
                  builder: (context, expand, child) {
                    return ExpandWidget(
                      expand: expand,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBluetoothBanner(context),
                          const Divider(height: 3),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: buildPermissionBanner(
                  container: (child) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [child, const Divider(height: 3)],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: buildServiceBanner(
                  container: (child) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [child, const Divider(height: 3)],
                  ),
                ),
              ),
              Selector<BluetoothDeviceRecord, int>(
                selector: (context, record) => record.length,
                builder: (context, length, child) {
                  if (length == 0)
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: SvgPicture.asset('assets/image/empty.svg'),
                      ),
                    );
                  return SliverPadding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Selector<BluetoothDeviceRecord, dynamic>(
                            selector: (_, record) => record.records[index],
                            builder: (context, data, child) {
                              print('build device selector');
                              return Padding(
                                padding: const EdgeInsets.all(4),
                                child: _DeviceCard(data.key, data.value),
                              );
                            },
                          );
                        },
                        childCount: length,
                        //addRepaintBoundaries: false,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<BluetoothState>(
        builder: (context, state, child) {
          print(state);
          switch (state) {
            case BluetoothState.UNKNOWN:
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

  List<Widget> _buildActions(BuildContext context) {
    final Widget inject = Offstage(
      offstage: Config.of(context).debug,
      child: IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          int len = BluetoothDeviceRecord.of(context).length;
          Bloc.of(context).inject(
            BluetoothDevice(
              name: DeviceCategory.names[len % 3],
              address: '00:11:22:33:44:55',
            ),
            BluetoothDeviceState.CONNECTED,
          );
        },
      ),
    );
    if (DeviceType.of(context).isPhone) {
      final S s = S.of(context);
      return [
        inject,
        PopupMenuButton<int>(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 0,
              child: IconText(
                text: s.action_settings,
                gap: 12,
                leading: const Icon(Icons.settings, size: 20),
              ),
            ),
            PopupMenuItem(
              value: 1,
              child: IconText(
                text: s.action_about,
                gap: 12,
                leading: const Icon(Icons.help, size: 20),
              ),
            ),
          ],
          onSelected: (i) {
            if (i == 0)
              _showOption(context);
            else if (i == 1) _buildAboutDialog(context);
          },
        ),
      ];
    }
    return [
      inject,
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () => _showOption(context),
      ),
      IconButton(
        icon: const Icon(Icons.help_outline),
        onPressed: () => _buildAboutDialog(context),
      ),
    ];
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
  AnimationController _rotateController;
  AnimationController _scaleController;
  CurvedAnimation _curve;
  Tween<double> _rotate;
  Tween<double> _scale;

  bool get discovering => widget.discovering;

  bool get disabled => widget.disabled;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleController = AnimationController(vsync: this, duration: kDuration);
    _rotate = Tween<double>(begin: 0, end: 2 * pi);
    _scale = Tween<double>(begin: disabled ? 0 : 1);
    _curve = CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('_DiscoveryWidget -> didChangeDependencies');
  }

  @override
  Widget build(BuildContext context) {
    print('_DiscoveryWidget -> build');
    return ScaleTransition(
      scale: _scale.animate(_scaleController),
      child: FloatingActionButton(
        tooltip: 'discovery',
        child: RotationTransition(
          turns: _rotate.animate(_curve),
          child: const Icon(Icons.refresh),
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
        _rotateController.repeat();
      else
        _rotateController.animateTo(1);
    }
    if (oldWidget.disabled != disabled) {
      if (disabled)
        _scale.end = 0;
      else
        _scale.end = 1;
      _scaleController.reset();
      _scaleController.forward();
    }
  }
}

class _DeviceCard extends StatefulWidget {
  final BluetoothDevice device;
  final BluetoothDeviceState state;

  const _DeviceCard(this.device, this.state, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<_DeviceCard>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _fadeIn, _fadeOut;
  CurvedAnimation _curve;
  ColorTween _color;
  String _lastState;
  String _thisState;
  Widget _lastTailing;
  Widget _thisTailing;
  VoidCallback _open;

  BluetoothDevice get _device => widget.device;

  BluetoothDeviceState get _state => widget.state;

  Widget get _pairedTrailing => const Icon(Icons.bluetooth_connected);

  Widget get _connectedTrailing => IconButton(
        icon: const Icon(Icons.close),
        onPressed: _disconnect,
      );

  Widget get _waitingTrailing => const SizedBox(
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
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(_curve);
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(_curve);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DeviceCard oldWidget) {
    print('_DeviceCard -> didUpdateWidget');
    if (_state != oldWidget.state) {
      _lastTailing = _getStateTrailing(_state);
      _thisTailing = _getStateTrailing(_state);
      _lastState = _getStateString(oldWidget.state);
      _thisState = _getStateString(_state);
      _color.begin = _getStateColor(oldWidget.state);
      _color.end = _getStateColor(_state);
      _controller.reset();
      _controller.forward();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('_DeviceCard -> didChangeDependencies');
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
    print('_DeviceCard -> build');
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
            Icon(CommunityMaterialIcons.circle_small, color: contentColor),
            RepaintBoundary(child: _buildState()),
          ],
        ),
        onTap: () => _open(),
        trailing: RepaintBoundary(child: _buildTrailing()),
      ),
    );
    final Widget to = DeviceWidget(device: _device);
    return _buildContainer(context, from, to);
  }

  Widget _buildContainer(BuildContext context, Widget from, Widget to) {
    return OpenContainer(
      //tappable: true,
      //transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: kDuration,
      closedShape: _cardBorder,
      closedColor: _color.evaluate(_curve),
      closedElevation: 0,
      closedBuilder: (_, open) {
        //print('closedBuilder');
        _open = open;
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
          FadeTransition(
            opacity: _fadeOut,
            child: Text(_lastState),
          ),
          FadeTransition(
            opacity: _fadeIn,
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
          FadeTransition(
            opacity: _fadeOut,
            child: _lastTailing,
          ),
          FadeTransition(
            opacity: _fadeIn,
            child: _thisTailing,
          ),
        ],
      ),
    );
  }
}

void _showOption(BuildContext context) {
  if (DeviceType.of(context).isPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      //enableDrag: false,
      builder: (context) {
        final ThemeData theme = Theme.of(context);
        return DecoratedBox(
          decoration: BoxDecoration(color: theme.primaryColor),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Text(S.of(context).option_title),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Option(color: theme.colorScheme.onPrimary),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: const BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
        ),
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (context) {
        final ThemeData theme = Theme.of(context);
        Widget dialogChild = ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: kPageMaxWidth,
            maxHeight: 490,
          ),
          child: Column(
            //mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: DefaultTextStyle(
                  style: theme.textTheme.headline6,
                  textAlign: TextAlign.center,
                  child: Semantics(
                    namesRoute: true,
                    child: Text(S.of(context).option_title),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Option(),
                ),
              ),
              SizedBox(
                height: kToolbarHeight,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 24),
                    child: FlatButton(
                      textTheme: ButtonTextTheme.primary,
                      child: Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: dialogChild,
        );
      },
    );
  }
}

library device;

import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart'
    as ext;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'bloc.dart';
import 'bluetooth/bluetooth.dart';
import 'bluetooth/controller.dart';
import 'generated/i18n.dart';

part 'device/general.dart';

part 'device/light.dart';

part 'device/rumble.dart';

part 'device/color.dart';

const double _kTabbarHeight = 48;

class DeviceWidget extends StatelessWidget {
  final BluetoothDevice device;
  final List<_WidgetHolder> _slivers = [
    _WidgetHolder(
      nameBuilder: (c) => S.of(c).bottom_label_general,
      iconData: Icons.perm_device_information,
      builder: (c) => _GeneralWidget(c),
    ),
    _WidgetHolder(
      nameBuilder: (c) => S.of(c).bottom_label_rumble,
      iconData: Icons.vibration,
      builder: (c) => _RumbleWidget(c),
    ),
    _WidgetHolder(
      nameBuilder: (c) => S.of(c).bottom_label_light,
      iconData: Icons.highlight,
      builder: (c) => _LightWidget(c),
    ),
    _WidgetHolder(
      nameBuilder: (c) => S.of(c).bottom_label_color,
      iconData: Icons.color_lens,
      builder: (c) => _ColorWidget(c),
    ),
  ];
  final ValueNotifier<int> _index = ValueNotifier(0);
  final PageController _controller = PageController();

  DeviceWidget({Key key, @required this.device}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ValueListenableProvider.value(value: _index),
        ProxyProvider<BluetoothDeviceMap, BluetoothDeviceState>(
          lazy: false,
          update: (c, map, v) {
            final state = map[device].state;
            if (v != state && state != BluetoothDeviceState.CONNECTED) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                _showDialog(c);
              });
            }
            return state;
          },
        ),
        ProxyProvider<BluetoothDeviceState, Controller>(
          updateShouldNotify: (_, __) => false,
          update: (c, _, v) => v ?? Controller(device),
          dispose: (_, v) => v.dispose(),
        ),
      ],
      child: _build(context),
    );
  }

  Widget _build(BuildContext context) {
    print('build controller body');
    return Scaffold(
      body: ext.NestedScrollView(
        pinnedHeaderSliverHeightBuilder: () =>
            _kTabbarHeight + MediaQuery.of(context).padding.top,
        headerSliverBuilder: (context, innerScrolled) {
          //final ThemeData theme = Theme.of(context);
          return [
            SliverAppBar(
              title: Text(device.name),
              centerTitle: true,
              floating: true,
              pinned: true,
              //snap: true,
              forceElevated: innerScrolled,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(_kTabbarHeight),
                child: _buildIndicator(context),
              ),
            ),
          ];
        },
        body: Consumer<Controller>(
          builder: (context, controller, __) {
            return PageView(
              controller: _controller,
              //scrollDirection: Axis.vertical,
              children: _slivers.map((e) {
                return AliveWidgetBuilder(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: kPageConstraint,
                      child: SingleChildScrollView(
                        child: e.builder(controller),
                      ),
                    ),
                  ),
                );
              }).toList(),
              onPageChanged: (v) => _index.value = v,
            );
          },
        ),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    return Container(
      height: _kTabbarHeight,
      constraints: kPageConstraint,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Consumer<int>(
        builder: (context, index, _) {
          return GNav(
            gap: 8,
            selectedIndex: index,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3),
            activeColor: Theme.of(context).colorScheme.onPrimary,
            iconSize: 20,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            duration: kDuration,
            //backgroundColor: Theme.of(context).primaryColor,
            tabBackgroundColor: Theme.of(context).colorScheme.primaryVariant,
            tabs: _slivers.map((e) {
              return GButton(
                text: e.getName(context),
                icon: e.iconData,
              );
            }).toList(),
            onTabChange: (i) {
              _controller.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          );
        },
      ),
    );
  }

  void _showDialog(BuildContext context) {
    Navigator.of(context).push(
      DialogRoute(
        barrierDismissible: false,
        pageBuilder: (context, animation, ___) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AnimatedBuilder(
              animation: animation,
              child: Center(
                child: UnconstrainedBox(
                  child: LimitedBox(
                    maxWidth: 300,
                    maxHeight: 200,
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  S.of(context).dialog_desc_disconnected(
                                      '${device.name}(${device.address})'),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                            ),
                          ),
                          const Divider(height: 3),
                          SizedBox(
                            height: 48,
                            child: FlatButton(
                              textColor: Theme.of(context).primaryColor,
                              child: Text(S.of(context).action_ok),
                              onPressed: () {
                                Navigator.popUntil(
                                    context, ModalRoute.withName('/home'));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              builder: (_, child) {
                return Opacity(
                  opacity: animation.value,
                  child: Transform.scale(
                    scale: animation.value,
                    child: child,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

typedef _ControllerBuilder = Widget Function(Controller);
typedef _NameBuilder = String Function(BuildContext);

class _WidgetHolder {
  final String _name;
  final Widget _icon;
  final IconData iconData;
  final _NameBuilder _nameBuilder;
  final _ControllerBuilder builder;

  const _WidgetHolder(
      {String name,
      _NameBuilder nameBuilder,
      Widget icon,
      this.iconData,
      this.builder})
      : assert(name != null || nameBuilder != null),
        assert(icon != null || iconData != null),
        assert(builder != null),
        _name = name,
        _icon = icon,
        _nameBuilder = nameBuilder;

  String getName(BuildContext context) => _name ?? _nameBuilder(context);

  Widget get icon => _icon ?? Icon(iconData);
}

class DialogRoute<T> extends PopupRoute<T> {
  DialogRoute({
    @required RoutePageBuilder pageBuilder,
    bool barrierDismissible = true,
    String barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder transitionBuilder,
    RouteSettings settings,
  })  : assert(barrierDismissible != null),
        _pageBuilder = pageBuilder,
        _barrierDismissible = barrierDismissible,
        _barrierLabel = barrierLabel,
        _barrierColor = barrierColor,
        _transitionDuration = transitionDuration,
        _transitionBuilder = transitionBuilder,
        super(settings: settings);

  final RoutePageBuilder _pageBuilder;

  @override
  bool get barrierDismissible => _barrierDismissible;
  final bool _barrierDismissible;

  @override
  String get barrierLabel => _barrierLabel;
  final String _barrierLabel;

  @override
  Color get barrierColor => _barrierColor;
  final Color _barrierColor;

  @override
  Duration get transitionDuration => _transitionDuration;
  final Duration _transitionDuration;

  final RouteTransitionsBuilder _transitionBuilder;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Semantics(
      child: _pageBuilder(context, animation, secondaryAnimation),
      scopesRoute: true,
      explicitChildNodes: true,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    if (_transitionBuilder == null) {
      return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.linear,
          ),
          child: child);
    } // Some default transition
    return _transitionBuilder(context, animation, secondaryAnimation, child);
  }
}

abstract class AliveWidget extends StatefulWidget {
  const AliveWidget();

  @override
  State<StatefulWidget> createState() => _AliveWidgetState();

  Widget build(BuildContext context);
}

class AliveWidgetBuilder extends AliveWidget {
  final Widget child;

  const AliveWidgetBuilder({@required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _AliveWidgetState extends State<AliveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.build(context);
  }
}

class _StickyBarDelegate extends SliverPersistentHeaderDelegate {
  final PreferredSizeWidget child;

  const _StickyBarDelegate({@required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return this.child;
  }

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  double get minExtent => child.preferredSize.height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

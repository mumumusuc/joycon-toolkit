import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:joycon/bloc.dart';
import 'package:joycon/bluetooth/bluetooth.dart';
import 'package:joycon/bluetooth/controller.dart';
import 'package:joycon/widgets/color.dart';
import 'package:joycon/widgets/device.dart';
import 'package:joycon/widgets/light.dart';
import 'package:joycon/widgets/rumble.dart';
import 'package:provider/provider.dart';

class ControllerWidget extends StatelessWidget {
  final BluetoothDevice device;
  final List<_WidgetHolder> _slivers = [
    _WidgetHolder(
      name: 'General',
      icon: const Icon(Icons.perm_device_information),
      builder: (c) => DeviceWidget(c),
    ),
    _WidgetHolder(
      name: 'Rumble',
      icon: const Icon(Icons.vibration),
      builder: (c) => RumbleWidget(c),
    ),
    _WidgetHolder(
      name: 'Light',
      icon: const Icon(Icons.highlight),
      builder: (c) => LightWidget(c),
    ),
    _WidgetHolder(
      name: 'Color',
      icon: const Icon(Icons.color_lens),
      builder: (c) => ColorWidget(c),
    ),
  ];
  final ValueNotifier<int> _index = ValueNotifier(0);
  final PageController _controller = PageController();

  ControllerWidget({Key key, @required this.device}) : super(key: key);

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
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 0.0,
        child: Consumer<int>(
          builder: (context, index, _) {
            return BottomNavigationBar(
              selectedItemColor: Theme.of(context).primaryColorLight,
              unselectedItemColor: Theme.of(context).unselectedWidgetColor,
              currentIndex: index,
              onTap: (i) {
                _controller.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              items: _slivers.map((e) {
                return BottomNavigationBarItem(
                  title: Text(e.name),
                  icon: e.icon,
                );
              }).toList(),
            );
          },
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) {
          final ThemeData theme = Theme.of(context);
          return [
            SliverAppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              iconTheme: theme.iconTheme,
              textTheme: theme.textTheme,
              title: Text(device.name),
              centerTitle: true,
              floating: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ];
        },
        body: Consumer<Controller>(
          builder: (_, controller, __) {
            return PageView(
              controller: _controller,
              //scrollDirection: Axis.vertical,
              children: _slivers.map((e) {
                return AliveWidgetBuilder(
                  child: SingleChildScrollView(
                    child: e.builder(controller),
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
                                  '${device.name}(${device.address}) disconnected',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.subtitle1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 48,
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: const Color(0x0F222222),
                                  ),
                                ),
                              ),
                              child: FlatButton(
                                textColor: Theme.of(context).primaryColor,
                                child: Text('OK'),
                                onPressed: () {
                                  Navigator.popUntil(
                                      context, ModalRoute.withName('/'));
                                },
                              ),
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

class _WidgetHolder {
  final String name;
  final Widget icon;
  final _ControllerBuilder builder;

  const _WidgetHolder({this.name, this.icon, this.builder});
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

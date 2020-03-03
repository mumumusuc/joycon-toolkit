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
  final Map<String, Widget> _slivers = {
    'General': AliveWidgetBuilder(child: const DeviceWidget()),
    'Rumble': AliveWidgetBuilder(child: RumbleWidget()),
    'Light': AliveWidgetBuilder(child: LightWidget()),
    'Color': AliveWidgetBuilder(child: const ColorWidget()),
  };
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
      appBar: AppBar(
        title: Consumer<int>(
          builder: (_, v, __) => Text(_slivers.keys.elementAt(v)),
        ),
      ),
      drawer: Drawer(
        child: ListTileTheme(
          style: ListTileStyle.drawer,
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: _slivers.entries.map<Widget>((it) {
              final index = _slivers.keys.toList().indexOf(it.key);
              return Consumer<int>(
                child: Text(it.key),
                builder: (_, v, child) {
                  final selected = index == v;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected ? Colors.black12 : Colors.transparent,
                      border: const Border(
                        bottom:
                            const BorderSide(color: const Color(0x0F222222)),
                      ),
                    ),
                    child: ListTile(
                      title: child,
                      onTap: () {
                        if (!selected) {
                          /*
                          _controller.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                           */
                          _controller.jumpToPage(index);
                          _index.value = index;
                          Navigator.pop(context);
                        }
                      },
                      selected: selected,
                    ),
                  );
                },
              );
            }).toList()
              ..insert(
                0,
                UserAccountsDrawerHeader(
                  accountName: Text(device.name),
                  accountEmail: Text(device.address),
                  currentAccountPicture: CircleAvatar(
                    child: Image.asset(
                      selectDeviceIcon(device),
                      color: Colors.white,
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
              ),
          ),
        ),
      ),
      body: PageView(
        controller: _controller,
        //scrollDirection: Axis.vertical,
        children: _slivers.values.toList(growable: false),
        onPageChanged: (v) => _index.value = v,
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

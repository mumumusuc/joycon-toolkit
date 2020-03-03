import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:joycon/bluetooth/controller.dart';
import 'package:provider/provider.dart';

class LightWidget extends StatelessWidget {
  final Map<String, HomeLightPattern> _patterns = const {
    'breath': _breath,
    'blink': _blink,
  };
  final List<int> _range_0F = List.generate(16, (i) => i);
  final ValueNotifier<String> _pattern = ValueNotifier('breath');
  final ValueNotifier<int> _player = ValueNotifier(0);
  final ValueNotifier<int> _flash = ValueNotifier(0);
  final ValueNotifier<int> _intensity = ValueNotifier(0);
  final ValueNotifier<int> _duration = ValueNotifier(0);
  final ValueNotifier<int> _repeat = ValueNotifier(0);
  final _Cycle _cycles = _Cycle();

  LightWidget({Key key}) : super(key: key);

  Widget _buildPlayerLightCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16),
        leading: const Icon(Icons.lightbulb_outline),
        title: Row(
          children: <Widget>[
            Expanded(
              child: _buildDropDown(context, 'player', _player, _range_0F),
            ),
            const VerticalDivider(),
            Expanded(
              child: _buildDropDown(context, 'flash', _flash, _range_0F),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.send),
          onPressed: () {
            Controller controller =
                Provider.of<Controller>(context, listen: false);
            controller.setPlayer(_player.value, _flash.value);
          },
        ),
      ),
    );
  }

  Widget _buildDropDown<T>(BuildContext context, String label,
      ValueNotifier<T> value, List<T> items) {
    return Row(
      children: <Widget>[
        label == null
            ? const SizedBox()
            : Text('$label:', style: Theme.of(context).textTheme.caption),
        Expanded(
          child: ValueListenableProvider<T>.value(
            value: value,
            child: Consumer<T>(
              builder: (_, v, __) {
                return DropdownButton<T>(
                  isDense: true,
                  isExpanded: true,
                  iconSize: 14,
                  value: v,
                  items: items
                      .map<DropdownMenuItem<T>>((e) => DropdownMenuItem<T>(
                            value: e,
                            child: Center(child: Text('$e')),
                          ))
                      .toList(growable: false),
                  onChanged: (vv) => value.value = vv,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeLightRow(BuildContext context) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            child: _buildDropDown(context, 'intensity', _intensity, _range_0F),
          ),
          const VerticalDivider(),
          Expanded(
            child: _buildDropDown(context, 'duration', _duration, _range_0F),
          ),
          const VerticalDivider(),
          Expanded(
            child: _buildDropDown(context, 'repeat', _repeat, _range_0F),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeLightCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ExpansionPanelList.radio(
        initialOpenPanelValue: 1,
        expansionCallback: (index, expanded) {},
        children: [
          ExpansionPanelRadio(
            value: 1,
            canTapOnHeader: true,
            headerBuilder: (context, expanded) {
              return const ListTile(
                leading: const Icon(Icons.local_parking),
                title: const Text('Pattern'),
              );
            },
            body: _buildHomeLightPreInstall(context),
          ),
          ExpansionPanelRadio(
            value: 2,
            canTapOnHeader: true,
            headerBuilder: (context, expanded) {
              return const ListTile(
                leading: const Icon(Icons.radio_button_unchecked),
                title: const Text('Custom'),
              );
            },
            body: _buildHomeLightCustom(context),
          ),
        ],
      ),
    );
  }

  void _sendPreInstall(BuildContext context) {
    Controller controller = Provider.of<Controller>(context, listen: false);
    controller.setHomeLight(_patterns[_pattern.value]);
  }

  void _sendCustom(BuildContext context) {
    Controller controller = Provider.of<Controller>(context, listen: false);
    controller.setHomeLight(HomeLightPattern(
      intensity: _intensity.value,
      duration: _duration.value,
      repeat: _repeat.value,
      cycles: _cycles.toIntList(),
    ));
  }

  Widget _buildHomeLightPreInstall(BuildContext context) {
    return _buildDropDown(
        context, null, _pattern, _patterns.keys.toList(growable: false));
  }

  Widget _buildHomeLightCustom(BuildContext context) {
    return ValueListenableProvider.value(
      value: _cycles,
      child: Consumer<int>(builder: (context, count, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(count, (index) {
            return DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0x0F222222)),
                ),
              ),
              child: ListTile(
                title: Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildDropDown<int>(
                        context,
                        'intensity',
                        _cycles[index].intensity,
                        _range_0F,
                      ),
                    ),
                    const VerticalDivider(),
                    Expanded(
                      child: _buildDropDown<int>(
                        context,
                        'fade',
                        _cycles[index].fade,
                        _range_0F,
                      ),
                    ),
                    const VerticalDivider(),
                    Expanded(
                      child: _buildDropDown<int>(
                        context,
                        'keep',
                        _cycles[index].keep,
                        _range_0F,
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
            ..insert(
              0,
              DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: const Color(0x0F222222)),
                  ),
                ),
                child: _buildHomeLightRow(context),
              ),
            )
            ..insert(
              count + 1,
              SizedBox(
                height: 40,
                width: double.infinity,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox.expand(
                        child: FlatButton(
                          child: const Icon(Icons.add),
                          onPressed: count < 15 ? () => _cycles.append() : null,
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: SizedBox.expand(
                        child: FlatButton(
                          child: const Icon(Icons.remove),
                          onPressed: count > 1 ? () => _cycles.remove() : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        );
      }),
    );
  }

  Widget _buildHomeLightCard2(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ChangeNotifierProvider(
        create: (_) => ValueNotifier<int>(0),
        child: Consumer<ValueNotifier<int>>(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: const Border(
                  top: const BorderSide(color: const Color(0x0F222222))),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 0),
              child: _buildHomeLightCustom(context),
            ),
          ),
          builder: (_, value, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  trailing: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        if (value.value == 0)
                          _sendPreInstall(context);
                        else
                          _sendCustom(context);
                      }),
                  title: Row(
                    children: <Widget>[
                      Expanded(
                        child: RadioListTile(
                          value: 0,
                          groupValue: value.value,
                          onChanged: (v) => value.value = v,
                          title: _buildHomeLightPreInstall(context),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          value: 1,
                          groupValue: value.value,
                          onChanged: (v) => value.value = v,
                          title: Text('custom'),
                        ),
                      ),
                    ],
                  ),
                ),
                Offstage(
                  offstage: value.value == 0,
                  child: child,
                ),
              ],
            );
          },
        ),
      ),
    );
/*
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(0),
        trailing: IconButton(
          icon: Icon(Icons.send),
          onPressed: () {},
        ),
        title: ChangeNotifierProvider(
          create: (_) => ValueNotifier<int>(0),
          child: Consumer<ValueNotifier<int>>(
            child: SizedBox(
              width: double.infinity,
              child: _buildHomeLightCustom(context),
            ),
            builder: (_, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: RadioListTile(
                          value: 0,
                          groupValue: value.value,
                          onChanged: (v) => value.value = v,
                          title: _buildHomeLightPreInstall(context),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile(
                          value: 1,
                          groupValue: value.value,
                          onChanged: (v) => value.value = v,
                          title: Text('custom'),
                        ),
                      ),
                    ],
                  ),
                  Offstage(
                    offstage: value.value == 0,
                    child: child,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
 */
  }

  @override
  Widget build(BuildContext context) {
    print('build light widget');
    return ListView(
      children: <Widget>[
        const ListTile(title: Text('Player & Flash')),
        _buildPlayerLightCard(context),
        const ListTile(title: Text('Home Ring')),
        _buildHomeLightCard2(context),
      ],
    );
  }
}

const HomeLightPattern _breath = HomeLightPattern(
  intensity: 0x0,
  duration: 0x2,
  repeat: 0x3,
  cycles: [0xF, 0xF, 0xF, 0x0, 0xF, 0xF],
);
const HomeLightPattern _blink = HomeLightPattern(
  intensity: 0x0,
  duration: 0x2,
  repeat: 0x3,
  cycles: [0xF, 3, 3, 0, 3, 3, 0xF, 3, 3, 0, 3, 3, 0, 0x6, 0x6],
);

class _Cycle extends ChangeNotifier implements ValueListenable<int> {
  static List<_Cycle> _cycles = [_Cycle()];
  final ValueNotifier<int> intensity = ValueNotifier(0);
  final ValueNotifier<int> fade = ValueNotifier(0);
  final ValueNotifier<int> keep = ValueNotifier(0);

  @override
  int get value => _cycles.length;

  void append() {
    _cycles.add(_Cycle());
    notifyListeners();
  }

  void remove() {
    _cycles.removeLast();
    notifyListeners();
  }

  _Cycle operator [](int index) => _cycles[index];

  List<int> toIntList() => _cycles
      .expand((e) => [e.intensity.value, e.fade.value, e.keep.value])
      .toList(growable: false);
}

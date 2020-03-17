part of device;

typedef _Select = int Function(HomeLightPattern);
typedef _Notify = void Function(_PatternNotifier, int);

class _LightWidget extends StatelessWidget {
  static const List<HomeLightPattern> _patterns = const [_breath, _blink];
  static List<int> _range_0F = List.generate(16, (i) => i);
  final ValueNotifier<int> _player = ValueNotifier(0);
  final ValueNotifier<int> _flash = ValueNotifier(0);
  final Controller controller;

  _LightWidget(this.controller, {Key key}) : super(key: key);

  Widget _buildPlayerLightCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        //contentPadding: const EdgeInsets.only(left: 16),
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

  Widget _buildPatternSelector(
      BuildContext context, String label, _Select select, _Notify notify) {
    final TextStyle style = Theme.of(context).textTheme.caption;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: style)),
        Selector<_PatternNotifier, int>(
          selector: (_, p) => select(p.value),
          builder: (c, value, __) {
            return DropdownButton<int>(
              value: value,
              items: _range_0F
                  .map(
                      (e) => DropdownMenuItem<int>(value: e, child: Text('$e')))
                  .toList(),
              onChanged: (v) => notify(_PatternNotifier.of(c), v),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeLightRow(BuildContext context) {
    return ListTile(
      title: Row(
        children: <Widget>[
          Expanded(
            child: _buildPatternSelector(
              context,
              'intensity',
              (p) => p.intensity,
              (n, v) {
                n.value = n.value.copyWith(intensity: v);
              },
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: _buildPatternSelector(
              context,
              'duration',
              (p) => p.duration,
              (n, v) {
                n.value = n.value.copyWith(duration: v);
              },
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: _buildPatternSelector(
              context,
              'repeat',
              (p) => p.repeat,
              (n, v) {
                n.value = n.value.copyWith(repeat: v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeLightCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ChangeNotifierProvider(
        create: (_) => _PatternNotifier(_patterns[0]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked),
              trailing: Consumer<_PatternNotifier>(
                child: const Icon(Icons.send),
                builder: (_, pattern, child) {
                  return IconButton(
                    icon: child,
                    onPressed: () => controller.setHomeLight(pattern.value),
                  );
                },
              ),
              title: Consumer<_PatternNotifier>(
                child: const Text('custom'),
                builder: (_, pattern, child) {
                  HomeLightPattern pv = pattern.value;
                  if (!_patterns.contains(pv)) pv = null;
                  return DropdownButton<HomeLightPattern>(
                    value: pv,
                    isDense: true,
                    isExpanded: true,
                    iconSize: 14,
                    hint: child,
                    items: _patterns.map((e) {
                      return DropdownMenuItem<HomeLightPattern>(
                        value: e,
                        child: Text(e.name),
                      );
                    }).toList(),
                    onChanged: (value) => pattern.value = value,
                  );
                },
              ),
            ),
            Selector<_PatternNotifier, int>(
              selector: (_, p) => p.value.cycles.length,
              child: _buildHomeLightRow(context),
              builder: (context, length, child) {
                return DecoratedBox(
                  decoration: const BoxDecoration(
                    border: const Border(
                      top: const BorderSide(color: const Color(0x0F222222)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      length,
                      (index) {
                        return DecoratedBox(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: const Color(0x0F222222)),
                            ),
                          ),
                          child: ListTile(
                            title: Row(
                              children: <Widget>[
                                Expanded(
                                  child: _buildPatternSelector(
                                    context,
                                    'intensity',
                                    (p) => p.cycles[index].intensity,
                                    (n, v) {
                                      final c = List<HomeLightCycle>.from(
                                          n.value.cycles);
                                      c[index] =
                                          c[index].copyWith(intensity: v);
                                      n.value = n.value.copyWith(cycles: c);
                                    },
                                  ),
                                ),
                                const VerticalDivider(),
                                Expanded(
                                  child: _buildPatternSelector(
                                    context,
                                    'fade',
                                    (p) => p.cycles[index].intensity,
                                    (n, v) {
                                      final c = List<HomeLightCycle>.from(
                                          n.value.cycles);
                                      c[index] =
                                          c[index].copyWith(intensity: v);
                                      n.value = n.value.copyWith(cycles: c);
                                    },
                                  ),
                                ),
                                const VerticalDivider(),
                                Expanded(
                                  child: _buildPatternSelector(
                                    context,
                                    'keep',
                                    (p) => p.cycles[index].intensity,
                                    (n, v) {
                                      final c = List<HomeLightCycle>.from(
                                          n.value.cycles);
                                      c[index] =
                                          c[index].copyWith(intensity: v);
                                      n.value = n.value.copyWith(cycles: c);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                      ..insert(0, child)
                      ..add(
                        SizedBox(
                          height: 40,
                          width: double.infinity,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: SizedBox.expand(
                                  child: FlatButton(
                                    child: const Icon(Icons.add),
                                    onPressed: length < 15
                                        ? () => _PatternNotifier.of(context)
                                            .append()
                                        : null,
                                  ),
                                ),
                              ),
                              const VerticalDivider(width: 1),
                              Expanded(
                                child: SizedBox.expand(
                                  child: FlatButton(
                                    child: const Icon(Icons.remove),
                                    onPressed: length > 1
                                        ? () => _PatternNotifier.of(context)
                                            .remove()
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('build light widget');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const ListTile(title: Text('Player & Flash')),
        _buildPlayerLightCard(context),
        const ListTile(title: Text('Home Ring')),
        _buildHomeLightCard(context),
      ],
    );
  }
}

const HomeLightPattern _breath = HomeLightPattern(
  name: 'breath',
  intensity: 0x0,
  duration: 0x2,
  repeat: 0x3,
  cycles: [
    HomeLightCycle(intensity: 0xF, fade: 0xF, keep: 0xF),
    HomeLightCycle(intensity: 0x0, fade: 0xF, keep: 0xF),
  ],
);
const HomeLightPattern _blink = HomeLightPattern(
  name: 'blink',
  intensity: 0x0,
  duration: 0x2,
  repeat: 0x3,
  cycles: [
    HomeLightCycle(intensity: 0xF, fade: 0x3, keep: 0x3),
    HomeLightCycle(intensity: 0x0, fade: 0x3, keep: 0x3),
    HomeLightCycle(intensity: 0xF, fade: 0x3, keep: 0x3),
    HomeLightCycle(intensity: 0x0, fade: 0x3, keep: 0x3),
    HomeLightCycle(intensity: 0x0, fade: 0x6, keep: 0x6),
  ],
);

class _PatternNotifier extends ChangeNotifier
    implements ValueListenable<HomeLightPattern> {
  HomeLightPattern _value;

  _PatternNotifier(HomeLightPattern pattern) : _value = pattern;

  @override
  HomeLightPattern get value => _value;

  set value(HomeLightPattern v) {
    _value = v;
    notifyListeners();
  }

  static _PatternNotifier of(BuildContext context) =>
      Provider.of<_PatternNotifier>(context, listen: false);

  void append() {
    value = value.copyWith(
      cycles: List<HomeLightCycle>.from(_value.cycles)
        ..add(HomeLightCycle.zero),
    );
  }

  void remove() {
    value = value.copyWith(
      cycles: List<HomeLightCycle>.from(_value.cycles)..removeLast(),
    );
  }
}

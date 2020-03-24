part of device;

const List<HomeLightPattern> _patterns = [_breath, _blink];
final List<int> _range_0F = List.generate(16, (i) => i);

class _PlayerHolder extends ChangeNotifier {
  int _player;
  int _flash;

  _PlayerHolder(int player, int flash)
      : _player = player,
        _flash = flash;

  int get player => _player;

  set player(value) {
    if (_player != value) {
      _player = value;
      notifyListeners();
    }
  }

  int get flash => _flash;

  set flash(value) {
    if (_flash != value) {
      _flash = value;
      notifyListeners();
    }
  }

  static _PlayerHolder of(BuildContext context) =>
      Provider.of<_PlayerHolder>(context, listen: false);
}

class _DevicePlayerLight extends StatelessWidget {
  final Controller controller;

  _DevicePlayerLight(this.controller);

  @override
  Widget build(BuildContext context) {
    print('_DevicePlayerLight -> build');
    return ListenableProvider(
      create: (_) => _PlayerHolder(0, 0),
      dispose: (_, h) => h.dispose(),
      child: ListTile(
        leading: const Icon(Icons.lightbulb_outline),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Selector<_PlayerHolder, int>(
                selector: (_, h) => h.player,
                builder: (context, value, _) {
                  return LabeledDropDown<int>(
                    label: 'player',
                    items: _range_0F,
                    value: value,
                    onChanged: (v) => _PlayerHolder.of(context).player = v,
                  );
                },
              ),
            ),
            const VerticalDivider(),
            Expanded(
              child: Selector<_PlayerHolder, int>(
                selector: (_, h) => h.flash,
                builder: (context, value, _) {
                  return LabeledDropDown<int>(
                    label: 'flash',
                    items: _range_0F,
                    value: value,
                    onChanged: (v) => _PlayerHolder.of(context).flash = v,
                  );
                },
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.send),
          onPressed: () {
            final holder = _PlayerHolder.of(context);
            controller.setPlayer(holder.player, holder.flash);
          },
        ),
      ),
    );
  }
}

class _DeviceHomeLight extends StatelessWidget {
  final Controller controller;

  _DeviceHomeLight(this.controller);

  @override
  Widget build(BuildContext context) {
    print('_DeviceLight -> build');
    return ChangeNotifierProvider(
      create: (_) => _PatternNotifier(_patterns[0]),
      child: LabeledDropDownStyle(
        singleLine: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPatternSelector(context),
            const Divider(height: 1),
            Selector<_PatternNotifier, int>(
              selector: (_, p) => p.value.cycles.length,
              builder: (context, length, _) {
                return ListBody(
                  children: List.generate(
                    length,
                    (index) => _buildCycleRow(context, length, index),
                  )..insert(0, _buildGeneralRow(context, length)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternSelector(BuildContext context) {
    return ListTile(
      leading: const Icon(CommunityMaterialIcons.home_circle),
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
        child: const Text('Custom'),
        builder: (_, pattern, child) {
          HomeLightPattern pv = pattern.value;
          if (!_patterns.contains(pv)) pv = null;
          return BoxedDropDown<HomeLightPattern>(
            items: _patterns,
            value: pv,
            hint: child,
            onChanged: (value) => pattern.value = value,
          );
        },
      ),
    );
  }

  Widget _buildGeneralRow(BuildContext context, int length) {
    return ListTile(
      trailing: Builder(
        builder: (context) => IconButton(
          padding: const EdgeInsets.all(0),
          iconSize: 18,
          icon: const Icon(Icons.add),
          onPressed:
              length > 14 ? null : () => _PatternNotifier.of(context).append(),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Selector<_PatternNotifier, int>(
              selector: (_, p) => p.value.intensity,
              builder: (context, value, _) {
                return LabeledDropDown(
                  label: 'intensity',
                  items: _range_0F,
                  value: value,
                  onChanged: (v) {
                    _PatternNotifier.of(context).updateWith(intensity: v);
                  },
                );
              },
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: Selector<_PatternNotifier, int>(
              selector: (_, p) => p.value.duration,
              builder: (context, value, _) {
                return LabeledDropDown(
                  label: 'duration',
                  items: _range_0F,
                  value: value,
                  onChanged: (v) {
                    _PatternNotifier.of(context).updateWith(duration: v);
                  },
                );
              },
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: Selector<_PatternNotifier, int>(
              selector: (_, p) => p.value.repeat,
              builder: (context, value, _) {
                return LabeledDropDown(
                  label: 'repeat',
                  items: _range_0F,
                  value: value,
                  onChanged: (v) {
                    _PatternNotifier.of(context).updateWith(repeat: v);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleRow(BuildContext context, int length, int index) {
    return ListTile(
      trailing: Builder(
        builder: (context) => IconButton(
          padding: const EdgeInsets.all(0),
          iconSize: 18,
          icon: const Icon(Icons.remove),
          onPressed: length < 2
              ? null
              : () => _PatternNotifier.of(context).remove(index),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Selector<_PatternNotifier, int>(
              selector: (_, p) => p.value.cycles[index].intensity,
              builder: (context, value, _) {
                return LabeledDropDown(
                  label: 'intensity',
                  items: _range_0F,
                  value: value,
                  onChanged: (v) {
                    _PatternNotifier.of(context)
                        .updateCycle(index, intensity: v);
                  },
                );
              },
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: Selector<_PatternNotifier, int>(
              selector: (_, p) => p.value.cycles[index].fade,
              builder: (context, value, _) {
                return LabeledDropDown(
                  label: 'fade',
                  items: _range_0F,
                  value: value,
                  onChanged: (v) {
                    _PatternNotifier.of(context)
                        .updateCycle(index, intensity: v);
                  },
                );
              },
            ),
          ),
          const VerticalDivider(),
          Expanded(
            child: Selector<_PatternNotifier, int>(
              selector: (_, p) => p.value.cycles[index].keep,
              builder: (context, value, _) {
                return LabeledDropDown(
                  label: 'keep',
                  items: _range_0F,
                  value: value,
                  onChanged: (v) {
                    _PatternNotifier.of(context)
                        .updateCycle(index, intensity: v);
                  },
                );
              },
            ),
          ),
        ],
      ),
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
    if (_value != value) {
      _value = v;
      notifyListeners();
    }
  }

  static _PatternNotifier of(BuildContext context) =>
      Provider.of<_PatternNotifier>(context, listen: false);

  void updateWith({
    int intensity,
    int duration,
    int repeat,
  }) {
    value = _value.copyWith(
      intensity: intensity,
      duration: duration,
      repeat: repeat,
    );
  }

  void updateCycle(
    int index, {
    int intensity,
    int fade,
    int keep,
  }) {
    if (index >= 0 && index < _value.cycles.length) {
      final HomeLightCycle c = _value.cycles[index].copyWith(
        intensity: intensity,
        fade: fade,
        keep: keep,
      );
      if (c != _value.cycles[index]) {
        _value = _value.copyWith(
          cycles: List.from(_value.cycles)..[index] = c,
        );
        notifyListeners();
      }
    }
  }

  void append() {
    _value = _value.copyWith(
      cycles: List<HomeLightCycle>.from(_value.cycles)
        ..add(HomeLightCycle.zero),
    );
    notifyListeners();
  }

  void remove([index]) {
    _value = _value.copyWith(
      cycles: List<HomeLightCycle>.from(_value.cycles)
        ..removeAt(index ?? (value.cycles.length - 1)),
    );
    notifyListeners();
  }
}

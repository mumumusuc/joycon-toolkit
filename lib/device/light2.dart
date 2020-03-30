part of device;

const Map<String, HomeLightPattern> _patterns = const {
  'breath': _breath,
  'blink': _blink,
};
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
    return ChangeNotifierProvider<_PatternNotifier>(
      create: (_) => _PatternNotifier()..updateWith(_patterns['breath'], false),
      child: LabeledDropDownStyle(
        singleLine: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPatternSelector(context),
            const Divider(height: 1),
            Selector<_PatternNotifier, int>(
              selector: (_, p) => p.cycles.length,
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
        child: Text(S.of(context).custom),
        builder: (_, pattern, child) {
          final String name = pattern.name;
          return BoxedDropDown<String>(
            items: _patterns.keys.toList(),
            value: name,
            hint: child,
            onChanged: (value) => pattern.updateWith(_patterns[value]),
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
                  onChanged: (v) => _PatternNotifier.of(context).intensity = v,
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
                  onChanged: (v) => _PatternNotifier.of(context).duration = v,
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
                  onChanged: (v) => _PatternNotifier.of(context).repeat = v,
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
                    _PatternNotifier.of(context).updateCycle(index, fade: v);
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
                    _PatternNotifier.of(context).updateCycle(index, keep: v);
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

class _PatternNotifier extends ChangeNotifier {
  String _name;
  int _intensity;
  int _duration;
  int _repeat;
  List<HomeLightCycle> _cycles;

  _PatternNotifier({
    String name,
    int intensity = 0,
    int duration = 0,
    int repeat = 0,
    List<HomeLightCycle> cycles = const [],
  })  : _name = name,
        _intensity = intensity,
        _duration = duration,
        _repeat = repeat,
        _cycles = cycles;

  HomeLightPattern get value => HomeLightPattern(
        name: _name,
        intensity: _intensity,
        duration: _duration,
        repeat: _repeat,
        cycles: _cycles,
      );

  void updateWith(HomeLightPattern pattern, [bool notify = true]) {
    if (pattern == null) return;
    _name = pattern.name;
    _intensity = pattern.intensity;
    _duration = pattern.duration;
    _repeat = pattern.repeat;
    _cycles = List.from(pattern.cycles);
    if (notify) notifyListeners();
  }

  int get intensity => _intensity;

  int get duration => _duration;

  int get repeat => _repeat;

  String get name => _name;

  List<HomeLightCycle> get cycles => _cycles;

  set intensity(int value) {
    if (_intensity != value) {
      _name = null;
      _intensity = value;
      notifyListeners();
    }
  }

  set duration(int value) {
    if (_duration != value) {
      _name = null;
      _duration = value;
      notifyListeners();
    }
  }

  set repeat(int value) {
    if (_repeat != value) {
      _name = null;
      _repeat = value;
      notifyListeners();
    }
  }

  void updateCycle(int index, {int intensity, int fade, int keep}) {
    if (index < 0 || index > _cycles.length - 1) return;
    _name = null;
    _cycles[index] = _cycles[index].copyWith(
      intensity: intensity,
      fade: fade,
      keep: keep,
    );
    notifyListeners();
  }

  void append() {
    _name = null;
    _cycles.add(HomeLightCycle.zero);
    notifyListeners();
  }

  void remove([index]) {
    if (index > _cycles.length - 1 || index < 0) return;
    _name = null;
    _cycles.removeAt(index ?? (_cycles.length - 1));
    notifyListeners();
  }

  @override
  String toString() => _name;

  static _PatternNotifier of(BuildContext context) =>
      Provider.of<_PatternNotifier>(context, listen: false);
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joycon/bluetooth/bluetooth.dart';
import 'package:joycon/bluetooth/controller.dart';
import 'package:provider/provider.dart';

typedef OnSaved = void Function(String);

class RumbleWidget extends StatelessWidget {
  static const List<String> _musics = const [
    'custom',
    'Zelda main theme.mp3',
    'Mario main theme.mp3',
    '希望の花.mp3',
  ];
  final GlobalKey<FormState> _formKey = GlobalKey();
  final List<double> _data_l = List(4);
  final List<double> _data_r = List(4);
  final Controller controller;

  RumbleWidget(this.controller, {Key key}) : super(key: key);

  Widget _buildLimitedInput(String label, int limit, OnSaved onSaved,
      {num defaultValue}) {
    return TextFormField(
      decoration: InputDecoration(
        filled: true,
        labelText: label,
      ),
      inputFormatters: [
        WhitelistingTextInputFormatter(RegExp("[0-9.]")),
        LengthLimitingTextInputFormatter(limit + 1),
      ],
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      maxLines: 1,
      onSaved: onSaved,
      initialValue: '${defaultValue ?? 0}',
    );
  }

  Widget _buildMusicSliver(BuildContext context) {
    final style = Theme.of(context).textTheme.caption;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<_PlaybackNotifier>(
        builder: (_, v, __) {
          final pb = v.value;
          return Row(
            children: <Widget>[
              Text(pb.current.toString().split('.')[0], style: style),
              Expanded(
                child: Slider(
                  label: '${pb.percent}',
                  value: pb.progress.toDouble(),
                  min: 0,
                  max: pb.total.toDouble(),
                  divisions: pb.channel == 0 ? null : pb.channel * 4,
                  onChanged: (vv) {
                    v.update(vv.toInt());
                  },
                ),
              ),
              Text(pb.duration.toString().split('.')[0], style: style),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('build rumble widget');
    List<Widget> children = [
      ListTile(
        leading: const Icon(Icons.vibration),
        trailing: Consumer2<ValueNotifier<String>, ValueNotifier<Timer>>(
            builder: (context, asset, timer, __) {
          VoidCallback onPressed;
          if (asset.value == 'custom' && timer.value == null) {
            // send custom
            onPressed = () {
              if (!_formKey.currentState.validate()) return;
              _formKey.currentState.save();
              controller.enableRumble(true);
              timer.value = Timer.periodic(
                const Duration(milliseconds: 31),
                (_) => controller
                    .rumblef(List<double>()..addAll(_data_l)..addAll(_data_r)),
              );
            };
          } else if (timer.value == null) {
            // send timed data
            onPressed = () {
              controller.enableRumble(true);
              DefaultAssetBundle.of(context)
                  .load('assets/xwzh.jcm')
                  .then((value) {
                final pn = _PlaybackNotifier.of(context);
                final pb = _Playback(
                  progress: 1,
                  total: value.lengthInBytes,
                  channel: value.getUint8(0),
                  duration: const Duration(seconds: 240),
                );
                pn.value = pb;
                timer.value = Timer.periodic(
                  const Duration(milliseconds: 31),
                  (_) {
                    final pn = _PlaybackNotifier.of(context);
                    if (pn.value.percent >= 1) {
                      timer.value.cancel();
                      timer.value = null;
                      pn.update(0);
                      return;
                    }
                    List<int> data = List.generate(
                        8, (i) => value.getUint8(pn.value.progress + i),
                        growable: false);
                    controller.rumble(data);
                    pn.update(pn.value.progress + 8);
                  },
                );
              });
            };
          } else {
            // cancel send
            onPressed = () {
              timer.value.cancel();
              timer.value = null;
              controller.enableRumble(false);
            };
          }
          return IconButton(
            onPressed: onPressed,
            icon: AnimatedCrossFade(
              firstChild: const Icon(Icons.play_arrow),
              secondChild: const Icon(Icons.pause),
              crossFadeState: timer.value == null
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),
          );
        }),
        title: Consumer<ValueNotifier<String>>(
          child: const Icon(Icons.send),
          builder: (_, asset, child) {
            String v = asset.value;
            return DropdownButton<String>(
              isDense: true,
              isExpanded: true,
              value: v,
              items: _musics
                  .map(
                      (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: (vv) => asset.value = vv,
            );
          },
        ),
      ),
      const Divider(),
      Selector<ValueNotifier<String>, bool>(
        selector: (_, n) => n.value == _musics[0],
        builder: (context, custom, _) {
          if (custom) return _buildRumbleInputs(context);
          return _buildMusicSliver(context);
        },
      ),
    ];

    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(8),
        child: MultiProvider(
          providers: [
            ListenableProvider(
              create: (_) => ValueNotifier<String>(_musics[0]),
              dispose: (_, v) => v.dispose(),
            ),
            ListenableProvider(
              create: (_) => ValueNotifier<Timer>(null),
              dispose: (_, v) {
                v.value?.cancel();
                v.dispose();
              },
            ),
            ListenableProvider(
              create: (_) => _PlaybackNotifier(_Playback.zero),
              dispose: (_, v) => v.dispose(),
            ),
          ],
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRumbleInputs(BuildContext context) {
    switch (controller.category) {
      case DeviceCategory.JoyCon_L:
        return _buildRumbleWidget(
          context,
          _data_l,
          leading: const CircleAvatar(
            child: Text('L'),
            radius: 18,
          ),
        );
      case DeviceCategory.JoyCon_R:
        return _buildRumbleWidget(
          context,
          _data_r,
          leading: const CircleAvatar(
            child: Text('R'),
            radius: 18,
          ),
        );
      case DeviceCategory.ProController:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildRumbleWidget(
              context,
              _data_l,
              leading: const CircleAvatar(
                child: Text('L'),
                radius: 18,
              ),
            ),
            _buildRumbleWidget(
              context,
              _data_r,
              leading: const CircleAvatar(
                child: Text('R'),
                radius: 18,
              ),
            ),
          ],
        );
      default:
        return SizedBox();
    }
  }

  Widget _buildRumbleWidget(BuildContext context, List<double> data,
      {Widget leading}) {
    return ListTile(
      leading: leading,
      title: Row(
        children: <Widget>[
          Expanded(
              child: _buildLimitedInput(
            'HF',
            4,
            (s) => data[0] = double.parse(s),
            defaultValue: 320,
          )),
          const VerticalDivider(width: 3),
          Expanded(
              child: _buildLimitedInput(
            'HA',
            3,
            (s) => data[1] = double.parse(s),
            defaultValue: 0.0,
          )),
          const VerticalDivider(width: 3),
          Expanded(
              child: _buildLimitedInput(
            'LF',
            3,
            (s) => data[2] = double.parse(s),
            defaultValue: 160,
          )),
          const VerticalDivider(width: 3),
          Expanded(
              child: _buildLimitedInput(
            'LA',
            3,
            (s) => data[3] = double.parse(s),
            defaultValue: 0.0,
          )),
        ],
      ),
    );
  }
}

class _Playback {
  final int progress;
  final int total;
  final int channel;
  final Duration duration;

  const _Playback({
    @required this.progress,
    @required this.total,
    @required this.channel,
    @required this.duration,
  });

  static _Playback get zero =>
      _Playback(progress: 0, total: 0, channel: 0, duration: const Duration());

  double get percent => progress.toDouble() / total;

  Duration get current => duration;

  _Playback copyWith({
    int progress,
    int total,
    int channel,
    Duration duration,
  }) {
    return _Playback(
      progress: progress ?? this.progress,
      total: total ?? this.total,
      channel: channel ?? this.channel,
      duration: duration ?? this.duration,
    );
  }
}

class _PlaybackNotifier extends ChangeNotifier
    implements ValueListenable<_Playback> {
  _Playback _value;

  _PlaybackNotifier(_Playback value) : _value = value;

  @override
  _Playback get value => _value;

  set value(_Playback v) {
    _value = v;
    notifyListeners();
  }

  void update(int progress) {
    value = value.copyWith(progress: progress);
  }

  static _PlaybackNotifier of(BuildContext context) =>
      Provider.of<_PlaybackNotifier>(context, listen: false);
}

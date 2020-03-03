import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:joycon/bluetooth/controller.dart';
import 'package:provider/provider.dart';

typedef OnSaved = void Function(String);

class RumbleWidget extends StatelessWidget {
  final List<String> musics = const [
    'Select',
    'Zelda main theme.mp3',
    'Mario main theme.mp3',
    '希望の花.mp3',
  ];
  final ValueNotifier<String> selected = ValueNotifier<String>('Select');
  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  final ValueNotifier<Timer> _timer = ValueNotifier<Timer>(null);
  final GlobalKey<FormState> formKey = GlobalKey();
  final List<double> _rumbleData = List(8);

  RumbleWidget({Key key}) : super(key: key);

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

  void _beginRumbleTimed(VoidCallback cb) {
    _endRumbleTimed();
    _timer.value = Timer.periodic(
      const Duration(milliseconds: 31),
      (_) => cb(),
    );
  }

  void _endRumbleTimed() {
    if (_timerRunning) {
      _timer.value.cancel();
      _timer.value = null;
    }
  }

  bool get _timerRunning => _timer.value?.isActive == true;

  Widget _buildMusicWidget(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: DropdownButton<String>(
            value: Provider.of<String>(context),
            isExpanded: true,
            icon: const SizedBox(),
            onChanged: (value) => selected.value = value,
            items: musics
                .map((value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, textAlign: TextAlign.center),
                    ))
                .toList(),
          ),
          trailing: IconButton(
            icon: AnimatedCrossFade(
              firstChild: const Icon(Icons.play_arrow),
              secondChild: const Icon(Icons.pause),
              crossFadeState: Provider.of<Timer>(context)?.isActive == true
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
            onPressed: () async {
              if (_timerRunning) {
                _endRumbleTimed();
                return;
              }
              Controller controller =
                  Provider.of<Controller>(context, listen: false);
              controller.enableRumble(true);
              DefaultAssetBundle.of(context)
                  .load('assets/xwzh.jcm')
                  .then((value) {
                final int length = value.lengthInBytes;
                int cursor = 0;
                int chan = value.getUint8(cursor++);
                //print('read length=$length, channels=$chan');
                _beginRumbleTimed(() {
                  if (cursor >= length) {
                    _endRumbleTimed();
                    cursor = 0;
                    return;
                  }
                  List<int> data = List.generate(
                      8, (i) => value.getUint8(cursor + i),
                      growable: false);
                  controller.rumble(data);
                  progress.value = cursor / length;
                  //print('cursor = $cursor');
                  cursor += 8;
                });
              });
            },
          ),
        ),
        Offstage(
          offstage: Provider.of<double>(context) == 0,
          child: SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: Provider.of<double>(context),
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSendWidget(BuildContext context) {
    return ListTile(
      title: Form(
        key: formKey,
        child: Row(
          children: <Widget>[
            Expanded(
                child: _buildLimitedInput(
              'HF',
              4,
              (s) => _rumbleData[0] = double.parse(s),
              defaultValue: 320,
            )),
            const VerticalDivider(width: 3),
            Expanded(
                child: _buildLimitedInput(
              'HA',
              3,
              (s) => _rumbleData[1] = double.parse(s),
              defaultValue: 0.0,
            )),
            const VerticalDivider(width: 3),
            Expanded(
                child: _buildLimitedInput(
              'LF',
              3,
              (s) => _rumbleData[2] = double.parse(s),
              defaultValue: 160,
            )),
            const VerticalDivider(width: 3),
            Expanded(
                child: _buildLimitedInput(
              'LA',
              3,
              (s) => _rumbleData[3] = double.parse(s),
              defaultValue: 0.0,
            )),
          ],
        ),
      ),
      trailing: GestureDetector(
        onLongPressStart: (_) {
          print('onLongPressStart');
          if (!formKey.currentState.validate()) {
            return;
          }
          _rumbleData.fillRange(0, _rumbleData.length - 1, 0);
          formKey.currentState.save();
          _rumbleData.setRange(4, 8, _rumbleData.sublist(0, 4));
          Controller controller =
              Provider.of<Controller>(context, listen: false);
          controller.enableRumble(true);
          print(_rumbleData);
          _beginRumbleTimed(() {
            controller.rumblef(_rumbleData);
          });
        },
        onLongPressEnd: (_) {
          print('onLongPressEnd');
          _endRumbleTimed();
        },
        child: InkResponse(onTap: () {}, child: const Icon(Icons.send)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('build rumble widget');
    return MultiProvider(
      providers: [
        ValueListenableProvider<String>.value(value: selected),
        ValueListenableProvider<double>.value(value: progress),
        ValueListenableProvider<Timer>.value(value: _timer),
      ],
      child: Builder(
        builder: (context) => SingleChildScrollView(
          child: ExpansionPanelList.radio(
            initialOpenPanelValue: 1,
            children: [
              ExpansionPanelRadio(
                value: 1,
                canTapOnHeader: true,
                headerBuilder: (_, __) => ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text('Music'),
                ),
                body: _buildMusicWidget(context),
              ),
              ExpansionPanelRadio(
                value: 2,
                canTapOnHeader: true,
                headerBuilder: (_, __) => ListTile(
                  leading: Icon(Icons.vibration),
                  title: Text('Test'),
                ),
                body: _buildSendWidget(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

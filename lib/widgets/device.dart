import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:joycon/bluetooth/bluetooth.dart';
import 'package:joycon/bluetooth/controller.dart';

class DeviceWidget extends StatelessWidget {
  final Controller controller;

  const DeviceWidget(this.controller, {Key key}) : super(key: key);

  Widget _buildStateText(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(const Size(160, kToolbarHeight)),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            filled: false,
            isDense: true,
            enabled: true,
            focusedBorder: const UnderlineInputBorder(
              borderSide: const BorderSide(
                style: BorderStyle.none,
              ),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: const BorderSide(
                style: BorderStyle.none,
              ),
            ),
          ),
          readOnly: true,
          showCursor: false,
          initialValue: value,
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    BluetoothDevice device = controller.device;
    return Card(
      margin: const EdgeInsets.all(8),
      child: Wrap(
        direction: Axis.horizontal,
        children: <Widget>[
          _buildStateText(context, 'name', device.name),
          _buildStateText(context, 'mac', device.address),
          _buildStateText(context, 'S/N', '0123456789ABCDEF'),
          _buildStateText(context, 'battery', 'placeholder'),
        ],
      ),
    );
  }

  Widget _buildButtonCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: SvgPicture.asset('assets/image/empty.svg'),
    );
  }

  Widget _buildIMUCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: SvgPicture.asset('assets/image/empty.svg'),
    );
  }

  Widget _buildMemoryCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: SvgPicture.asset('assets/image/empty.svg'),
    );
  }

  @override
  Widget build(BuildContext context) {
    //print('build device widget');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const ListTile(title: const Text('Info')),
        Hero(
          tag: controller.device,
          child: _buildStatusCard(context),
        ),
        const ListTile(title: const Text('Button')),
        _buildButtonCard(context),
        const ListTile(title: const Text('6-Axis')),
        _buildIMUCard(context),
        const ListTile(title: const Text('Memory')),
        _buildMemoryCard(context),
      ],
    );
  }
}

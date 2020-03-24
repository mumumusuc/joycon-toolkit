part of device;

class _DeviceInfo extends StatelessWidget {
  final Controller controller;

  const _DeviceInfo(this.controller);

  BluetoothDevice get device => controller.device;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        direction: Axis.horizontal,
        children: [
          _buildTextWithLabel(context, 'name', device.name),
          _buildTextWithLabel(context, 'mac', device.address),
          _buildTextWithLabel(context, 'S/N', 'placeholder'),
          _buildTextWithLabel(context, 'battery', 'placeholder'),
        ],
      ),
    );
  }

  Widget _buildTextWithLabel(BuildContext context, String label, String text) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text.rich(
        TextSpan(
          text: '$label\n',
          style: theme.textTheme.caption,
          children: [
            TextSpan(
              text: text,
              style: theme.textTheme.subtitle1.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceButton extends _Unimplemented {}

class _DeviceAxes extends _Unimplemented {}

class _DeviceMemory extends _Unimplemented {}

class _Unimplemented extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/image/empty.svg'),
        Text('Unimplemented'),
        const SizedBox(height: 36),
      ],
    );
  }
}

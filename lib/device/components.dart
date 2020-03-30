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
          _buildTextWithLabel(context, 'Name', device.name),
          _buildTextWithLabel(context, 'MAC', device.address),
          _buildTextWithLabel(context, 'S/N', 'XBW17006642912'),
          _buildTextWithLabel(context, 'Battery', '65%, 3.90V, 17.6\u2103'),
          _buildTextWithLabel(context, 'FW Version', '3.86'),
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

class _DeviceButton extends StatelessWidget {
  final Controller controller;

  const _DeviceButton(this.controller);

  String get title => 'Button';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(CommunityMaterialIcons.gamepad_variant_outline),
          title: Text('$title (unimplemented)'),
        ),
        const Divider(height: 1),
        if (controller.category == DeviceCategory.ProController)
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                  child: _ControllerStick(),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(4, 8, 8, 8),
                  child: _ControllerStick(),
                ),
              ),
            ],
          ),
        if (controller.category != DeviceCategory.ProController)
          Container(
            margin: const EdgeInsets.all(8),
            child: _ControllerStick(),
          ),
        const Divider(height: 1),
        const _ControllerInput(),
      ],
    );
  }
}

class _DeviceAxis extends _Unimplemented {
  @override
  String get title => 'Axis';

  @override
  Widget get icon => const Icon(CommunityMaterialIcons.axis_arrow);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(leading: icon, title: Text('$title (unimplemented)')),
        const Divider(height: 1),
        AspectRatio(
          aspectRatio: 1,
          child: Center(
            child: IconButton(
              iconSize: 48,
              icon: const Icon(Icons.play_circle_outline),
              onPressed: () {},
            ),
          ),
        ),
        const Divider(height: 1),
        DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyText2,
          textAlign: TextAlign.center,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(
              color: kDividerColor.withOpacity(0.3),
              width: 0,
            ),
            children: [
              TableRow(
                children: [
                  Text('X:0.01(0x00FE)'),
                  Text('Y:0.01(0x00FE)'),
                  Text('Z:0.01(0x00FE)'),
                ]
                    .map(
                      (e) => SizedBox(height: 30, child: Center(child: e)),
                    )
                    .toList(),
              ),
              TableRow(
                children: [
                  Text('X:0.01(0x00FE)'),
                  Text('Y:0.01(0x00FE)'),
                  Text('Z:0.01(0x00FE)'),
                ]
                    .map(
                      (e) => SizedBox(height: 30, child: Center(child: e)),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceMemory extends _Unimplemented {
  @override
  String get title => 'Memory';

  @override
  Widget get icon => const Icon(CommunityMaterialIcons.content_save);
}

class _DeviceLogger extends _Unimplemented {
  @override
  String get title => 'Logger';

  @override
  Widget get icon => const Icon(CommunityMaterialIcons.note_outline);
}

abstract class _Unimplemented extends StatelessWidget {
  String get title;

  Widget get icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(leading: icon, title: Text('$title (unimplemented)')),
        const Divider(height: 1),
        SvgPicture.asset('assets/image/empty.svg'),
      ],
    );
  }
}

class _StickNormalizer {
  static const double _Threshold = 0.03;
  static const double _CursorRadius = 0.07;
  static const double _CursorBoundary = 0.09;
  static const double _StrokeWidth = 0.05;
  static const double _StrokeBoundary = 0.08;
  final Size size;
  final Offset position;

  const _StickNormalizer(this.size, this.position);

  double get radius => size.shortestSide / 2;

  Offset get center => size.bottomRight(Offset.zero) / 2;

  Offset get offset => position * (1 - _CursorRadius) * radius + center;

  double get distance => position.distance;

  double get boundary => (1 - _CursorRadius * 2) * radius;

  double get _cursorRadius => _CursorRadius * radius;

  double get _cursorBoundaryRadius => _CursorBoundary * radius;

  double get strokeWidth => _StrokeWidth * radius;

  double get strokeBoundary => _StrokeBoundary * radius;

  Path get crossLine => (Path()
        ..moveTo(-radius, 0)
        ..relativeLineTo(2 * radius, 0)
        ..moveTo(0, -radius)
        ..relativeLineTo(0, 2 * radius))
      .shift(center);

  Path get crossCursor => (Path()
        ..moveTo(-_cursorRadius, 0)
        ..relativeLineTo(2 * _cursorRadius, 0)
        ..moveTo(0, -_cursorRadius)
        ..relativeLineTo(0, 2 * _cursorRadius))
      .shift(offset);

  Path get crossCursorBoundary => (Path()
        ..moveTo(-_cursorBoundaryRadius, 0)
        ..relativeLineTo(2 * _cursorBoundaryRadius, 0)
        ..moveTo(0, -_cursorBoundaryRadius)
        ..relativeLineTo(0, 2 * _cursorBoundaryRadius))
      .shift(offset);

  bool get atOrigin => distance < _Threshold;

  bool get atBoundary => distance > 1 - _Threshold;
}

class _ControllerStickPainter extends CustomPainter {
  final Color bgColor;
  final Paint _paint;
  final Offset position;

  _ControllerStickPainter(this.position, this.bgColor)
      : _paint = Paint()..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final _StickNormalizer normalizer = _StickNormalizer(size, position);
    _drawBoundary(canvas, normalizer);
    if (normalizer.atOrigin)
      _drawCross(canvas, normalizer);
    else
      _drawDot(canvas, normalizer);
  }

  void _drawBoundary(Canvas canvas, _StickNormalizer n) {
    _paint
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // outer ring
    if (n.atBoundary)
      _paint.color = Colors.indigoAccent;
    else
      _paint.color = Colors.grey;
    canvas.drawCircle(n.center, n.boundary, _paint);
    // cross line
    if (n.atOrigin)
      _paint.color = Colors.indigoAccent;
    else
      _paint.color = Colors.grey;
    canvas.drawPath(n.crossLine, _paint);
  }

  void _drawCross(Canvas canvas, _StickNormalizer n) {
    // boundary
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = n.strokeBoundary
      ..color = bgColor;
    canvas.drawPath(n.crossCursorBoundary, _paint);
    // cross
    _paint
      ..strokeWidth = n.strokeWidth
      ..color = Colors.indigoAccent;
    canvas.drawPath(n.crossCursor, _paint);
  }

  void _drawDot(Canvas canvas, _StickNormalizer n) {
    // boundary
    _paint
      ..style = PaintingStyle.fill
      ..color = bgColor;
    canvas.drawCircle(n.offset, n._cursorBoundaryRadius, _paint);
    // dot
    _paint.color = Colors.indigoAccent;
    canvas.drawCircle(n.offset, n._cursorRadius, _paint);
  }

  @override
  bool shouldRepaint(_ControllerStickPainter oldDelegate) {
    return position != oldDelegate.position;
  }
}

class _ControllerStick extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ControllerStickState();
}

class _ControllerStickState extends State<_ControllerStick> {
  static const double _radius = 100;
  Offset offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).cardColor;
    // TODO: for debug, remove this when release
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          offset = (details.localPosition - context.size.center(Offset.zero)) /
              context.size.shortestSide *
              2;
        });
      },
      child: RepaintBoundary(
        child: CustomPaint(
          isComplex: true,
          size: const Size.fromRadius(_radius),
          painter: _ControllerStickPainter(offset, color),
        ),
      ),
    );
  }
}

const List<Widget> _Children = const [
  const Icon(CommunityMaterialIcons.gamepad_circle_left),
  const Icon(CommunityMaterialIcons.gamepad_circle_up),
  const Icon(CommunityMaterialIcons.gamepad_circle_right),
  const Icon(CommunityMaterialIcons.gamepad_circle_down),
  const Icon(CommunityMaterialIcons.alpha_x_circle),
  const Icon(CommunityMaterialIcons.alpha_y_circle),
  const Icon(CommunityMaterialIcons.alpha_a_circle),
  const Icon(CommunityMaterialIcons.alpha_b_circle),
  const Icon(CommunityMaterialIcons.plus_circle),
  const Icon(CommunityMaterialIcons.minus_circle),
  //const Icon(CommunityMaterialIcons.minus_circle),
];

class _ControllerInput extends StatefulWidget {
  const _ControllerInput();

  @override
  State<StatefulWidget> createState() => _ControllerInputState();
}

class _ControllerInputState extends State<_ControllerInput> {
  List<Widget> _children = [];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // TODO: remove GestureDetector
    return GestureDetector(
      onTap: () {
        setState(() {
          int index = Random().nextInt(_Children.length);
          _children.add(_Children[index]);
        });
      },
      onLongPress: () {
        setState(() {
          _children.clear();
        });
      },
      child: Container(
        height: kTextTabBarHeight,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        //padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
            color: _children.isNotEmpty ? Colors.indigoAccent : kDividerColor,
            width: 2,
          )),
        ),
        child: IconTheme(
          data: theme.iconTheme.copyWith(color: Colors.indigoAccent),
          child: Stack(
            children: [
              Flow(
                delegate: _InputDelegate(
                  onOverflow: (count) {
                    _children.removeRange(0, count);
                  },
                ),
                children: _children,
              ),
              Offstage(
                offstage: _children.isNotEmpty,
                child: Align(
                  alignment: Alignment.center,
                  child: Text('Test button', style: theme.textTheme.caption),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputDelegate extends FlowDelegate {
  final double spacing;
  final ValueChanged<int> onOverflow;

  const _InputDelegate({this.spacing = 24, this.onOverflow});

  @override
  void paintChildren(FlowPaintingContext context) {
    if (context.childCount == 0) return;
    final double childWidth = context.getChildSize(0).width;
    final double childHeight = context.getChildSize(0).height;
    final double width = childWidth + spacing;
    final double h = context.size.height / 2 - childHeight / 2;
    int count = (context.size.width / width).floor();
    double remain = context.size.width - count * width;
    double margin = 0;
    if (remain >= childWidth) {
      if (count < context.childCount) count++;
      remain -= childWidth;
    } else {
      remain += spacing;
    }
    if (context.childCount > count) {
      onOverflow?.call(context.childCount - count);
    }
    margin = remain / 2;
    for (int i = max(0, context.childCount - count);
        i < context.childCount;
        i++) {
      context.paintChild(i, transform: Matrix4.translationValues(margin, h, 0));
      margin += width;
    }
  }

  @override
  bool shouldRepaint(_InputDelegate context) {
    return false;
  }
}

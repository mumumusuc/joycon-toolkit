import 'package:flutter/material.dart';

class CardLayout extends StatelessWidget {
  final List<Widget> _children = [];
  final double interval;

  CardLayout({@required List<Widget> children, this.interval = 0}) {
    _children.addAll(children
        .map((it) => LayoutId(
              id: 'child_${children.indexOf(it)}',
              child: it,
            ))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return CustomMultiChildLayout(
      delegate:
          _CardLayoutDelegate(childCount: _children.length, interval: interval),
      children: _children,
    );
  }
}

class _CardLayoutDelegate extends MultiChildLayoutDelegate {
  static const kItemHeight = 80.0;
  final double _interval;
  final int childCount;
  List<Rect> colRects = [];
  List<Rect> rowRects = [];
  _CardLayoutDelegate({this.childCount, double interval = 0.5})
      : _interval = interval.clamp(0, 1);

  @override
  void performLayout(Size size) {
    final double expandHeight = kItemHeight * childCount;
    final double expandWidth = size.width;
    final double anchorY = (size.height - expandHeight) / 2;
    for (int i = 0; i < childCount; ++i) {
      final Rect begin =
          Rect.fromLTWH(0, anchorY + i * kItemHeight, size.width, kItemHeight);
      final Rect end = Rect.fromLTWH(i * (expandWidth / childCount), 0,
          expandWidth / childCount, kItemHeight);
      final Offset offset =
          begin.topLeft * (1.0 - _interval) + end.topLeft * _interval;
      final Size aa = begin.size * (1.0 - _interval);
      final Size bb = end.size * _interval;
      final Size ss = Size(aa.width + bb.width, aa.height + bb.height);
      final String id = 'child_$i';
      layoutChild(id, BoxConstraints.tight(ss));
      positionChild(id, offset);
    }
  }

  @override
  bool shouldRelayout(_CardLayoutDelegate oldDelegate) {
    return oldDelegate._interval != _interval ||
        oldDelegate.childCount != childCount;
  }
}

class CardItem extends StatelessWidget {
  final Widget leading;
  final Widget child;
  final VoidCallback onPressed;

  const CardItem({this.leading, this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                child: Icon(Icons.gamepad),
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text('device name'),
                subtitle: Text('11:22:33:44:55:66'),
                trailing: IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

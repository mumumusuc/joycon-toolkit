import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const Duration _kDuration = const Duration(milliseconds: 300);

class ExpandWidget extends StatefulWidget {
  final bool expand;
  final bool withOpacity;
  final Widget child;

  const ExpandWidget({
    @required this.expand,
    @required this.child,
    this.withOpacity = false,
  });

  @override
  State<StatefulWidget> createState() => _ExpandWidgetState();
}

class _ExpandWidgetState extends State<ExpandWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _height;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: _kDuration);
    _height = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.value = widget.expand ? 1 : 0;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ExpandWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expand != widget.expand) {
      if (widget.expand)
        _controller.forward();
      else
        _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ExpandWidget -> build');
    /*
    Widget fade = _Fade(
      heightFactor: _height.value,
      child: child,
    );
    if (opacity) fade = FadeTransition(opacity: _height, child: fade);
     */
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (_height.value == 0) return const SizedBox();
        return _Expand(
          heightFactor: _height.value,
          child: child,
        );
      },
    );
  }
}

class _Expand extends SingleChildRenderObjectWidget {
  final double heightFactor;
  final Widget child;

  const _Expand({@required this.heightFactor, @required this.child})
      : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ExpandRenderObject(heightFactor: heightFactor);

  @override
  void updateRenderObject(
      BuildContext context, _ExpandRenderObject renderObject) {
    renderObject..heightFactor = heightFactor;
  }
}

class _ExpandRenderObject extends RenderProxyBox {
  double _heightFactor;

  _ExpandRenderObject({
    double heightFactor = 1.0,
    RenderBox child,
  })  : assert(heightFactor != null),
        assert(heightFactor >= 0.0 && heightFactor <= 1.0),
        _heightFactor = heightFactor,
        super(child);

  double get heightFactor => _heightFactor;

  set heightFactor(double value) {
    assert(value != null);
    assert(value >= 0.0 && value <= 1.0);
    if (_heightFactor == value) return;
    _heightFactor = value;
    markNeedsLayout();
    markNeedsPaint();
  }

  @override
  void performLayout() {
    if (child != null) {
      child.layout(constraints, parentUsesSize: true);
      size = Size(child.size.width, child.size.height * _heightFactor);
    } else {
      performResize();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      layer = context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromLTWH(
          paintBounds.left,
          paintBounds.top,
          paintBounds.width,
          paintBounds.height * _heightFactor,
        ),
        super.paint,
        oldLayer: layer,
      );
    } else {
      layer = null;
    }
  }
}

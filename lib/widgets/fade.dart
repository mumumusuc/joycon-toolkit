import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const Duration _kDuration = const Duration(milliseconds: 300);

class FadeWidget extends StatefulWidget {
  final bool fade;
  final Widget child;

  const FadeWidget({@required this.fade, @required this.child});

  @override
  State<StatefulWidget> createState() => _FadeWidgetState();
}

class _FadeWidgetState extends State<FadeWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _height;

  bool get fade => widget.fade;

  Widget get child => widget.child;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: _kDuration);
    _height = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.value = fade ? 0 : 1;
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FadeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fade != fade) {
      if (fade)
        _controller.reverse();
      else
        _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: child,
      builder: (context, child) {
        return FadeTransition(
          opacity: _height,
          child: _Fade(
            heightFactor: _height.value,
            child: child,
          ),
        );
      },
    );
  }
}

class _Fade extends SingleChildRenderObjectWidget {
  final double heightFactor;
  final Widget child;

  const _Fade({@required this.heightFactor, @required this.child})
      : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _FadeRenderObject(heightFactor: heightFactor);

  @override
  void updateRenderObject(
      BuildContext context, _FadeRenderObject renderObject) {
    renderObject..heightFactor = heightFactor;
  }
}

class _FadeRenderObject extends RenderProxyBox {
  double _heightFactor;

  _FadeRenderObject({
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
}

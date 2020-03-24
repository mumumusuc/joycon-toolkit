import 'package:flutter/material.dart';

class KeepAliveWidgetBuilder extends KeepAliveWidget {
  final Widget child;

  const KeepAliveWidgetBuilder({@required this.child});

  @override
  Widget build(BuildContext context) => child;
}

abstract class KeepAliveWidget extends StatefulWidget {
  const KeepAliveWidget();

  @override
  State<StatefulWidget> createState() => _KeepAliveWidgetState();

  Widget build(BuildContext context);
}

class _KeepAliveWidgetState extends State<KeepAliveWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.build(context);
  }
}

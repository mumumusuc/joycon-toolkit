import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'bloc.dart';

class Splash extends StatelessWidget {
  const Splash();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = Theme.of(context).textTheme.headline6;
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Material(
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                child: ClipOval(
                  child: CircleAvatar(
                    radius: 60,
                    child: SvgPicture.asset(
                      'assets/image/icon.svg',
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    'Joy-Con toolkit',
                    style: style.copyWith(
                      color: style.color.withOpacity(0.3),
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashRoute<T> extends PageRoute<T> {
  @override
  Color get barrierColor => Colors.white12;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    print('build splash page');
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1.0).animate(animation),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
        child: const Splash(),
      ),
    );
  }
}

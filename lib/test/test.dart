import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../bluetooth/bluetooth.dart';
import '../generated/i18n.dart';
import '../bloc.dart';

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('build app root');
    return BlocProvider(
      child: Consumer<Config>(
        builder: (context, config, __) {
          print('build test');
          return MaterialApp(
            title: 'test',
            showPerformanceOverlay: true,
            //config.showPerformanceOverlay,
            checkerboardOffscreenLayers: true,
            //config.showOffscreenLayersCheckerboard,
            checkerboardRasterCacheImages: true,
            //config.showRasterCacheImagesCheckerboard,
            theme: config.lightTheme,
            darkTheme: config.darkTheme,
            themeMode: config.themeMode,
            locale: config.locale,
            localizationsDelegates: Config.localizationsDelegates,
            supportedLocales: Config.supportedLocales,
            localeResolutionCallback: config.localeResolutionCallback,
            home: _ContainerHome(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: config.textScale.scale,
                ),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}

class _SvgHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Svg'),
          bottom: TabBar(
            tabs: [Text('path'), Text('svg')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPath(),
            _buildSvg(),
          ],
        ),
      ),
    );
  }

  Widget _buildPath() {
    return CustomScrollView(
      slivers: [
        _PathDrawer(pro, prov),
        _PathDrawer(jcl, jcv),
        _PathDrawer(jcr, jcv),
      ].map((e) {
        return SliverToBoxAdapter(
          child: RepaintBoundary(
            child: Center(
              child: Container(
                color: Colors.grey,
                child: CustomPaint(
                  painter: e,
                  isComplex: true,
                  size: const Size(350, 350),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSvg() {
    return FutureProvider<List<DrawableRoot>>(
      create: (_) => Future.wait([
        'assets/image/pro_controller.svg',
        'assets/image/joycon_l.svg',
        'assets/image/joycon_r.svg',
      ].map(
        (e) => rootBundle.loadString(e).then((v) => svg.fromSvgString(v, '')),
      )),
      child: Consumer<List<DrawableRoot>>(
        builder: (_, values, __) {
          return CustomScrollView(
              slivers: values.map((e) {
            return SliverToBoxAdapter(
              child: RepaintBoundary(
                child: Center(
                  child: Container(
                    color: Colors.grey,
                    child: CustomPaint(
                      painter: _SvgDrawer(e),
                      isComplex: true,
                      size: const Size(350, 350),
                    ),
                  ),
                ),
              ),
            );
          }).toList());
        },
      ),
    );
  }
}

const Size viewPort = jcv;
const List<String> paths = jcr;

const Size prov = Size(505.47, 445.0875);
const List<String> pro = [
  '''m 357.8418,49.244141 c -7.99629,0.03942 -15.1435,3.801946 -21.92774,7.720703 -3.26295,1.179461 -4.79011,1.997242 -5.06054,2.558594 -24.01001,-1.232215 -51.04063,-1.853516 -78.09571,-1.853516 -26.39388,0 -52.74251,0.595239 -76.30664,1.767578 -0.008,5e-4 -0.0154,0.0035 -0.0234,0.0039 -0.59805,0.02972 -1.17112,0.0652 -1.76562,0.0957 -9.1162,-4.272679 -17.63241,-10.902172 -28.23242,-10.214843 -1.69547,-0.06106 -3.39208,-0.05606 -5.08789,-0.01172 -24.73118,1.802246 -52.452406,4.907566 -71.470706,22.431641 -5.194207,4.933884 -9.255046,11.037873 -11.841797,17.716796 -8.202123,6.454237 -13.314739,12.498926 -14.720703,16.021486 -1.317073,3.28314 -6.784358,25.25058 -13.210938,54.34961 15.242585,24.69889 38.123607,58.08229 59.041016,85.83008 17.418708,23.10404 33.434208,42.22608 42.406248,49.01172 24.09003,-2.02924 72.42171,-3.03126 120.74219,-3.03126 48.91653,0 97.85268,1.0209 121.68164,3.03126 8.97682,-6.80327 24.96797,-25.89969 42.36914,-48.98047 20.9286,-27.76263 43.81231,-61.17029 59.05469,-85.88282 -6.42342,-29.07715 -11.88543,-51.02797 -13.19531,-54.32812 -1.40596,-3.52252 -6.51884,-9.56735 -14.72071,-16.021486 -7.58713,-20.294711 -28.51011,-31.390045 -48.63281,-35.550781 -13.00353,-2.685061 -26.18266,-4.766272 -39.39063,-4.621094 -0.54075,-0.03151 -1.07824,-0.04557 -1.61132,-0.04297 z m 28.02539,49.447265 h 0.0215 c 5.47146,0.0058 10.43425,2.233074 14.01953,5.818364 l 0.0996,0.10156 c 3.53,3.58 5.73047,8.52945 5.73047,13.93945 0,5.48 -2.23055,10.44883 -5.81055,14.04883 l -0.0996,0.10156 c -3.58999,3.54 -8.53117,5.72852 -13.95117,5.72852 -5.47,0 -10.44906,-2.23008 -14.03906,-5.83008 -3.59,-3.59 -5.82031,-8.55906 -5.82031,-14.03906 0,-5.47 2.23008,-10.44907 5.83008,-14.03907 3.58528,-3.58528 8.54807,-5.824198 14.01953,-5.830074 z M 113.62695,120.86133 c 8.62,0 16.44157,3.50015 22.10157,9.16015 5.65,5.65 9.16015,13.47961 9.16015,22.09961 0,8.62 -3.50015,16.44961 -9.16015,22.09961 l -0.10157,0.0996 c -5.65,5.59 -13.41828,9.06055 -21.98828,9.06055 -8.62,0 -16.441795,-3.51039 -22.091795,-9.15039 -5.65,-5.65 -9.148437,-13.47961 -9.148437,-22.09961 0,-8.61 3.498437,-16.43961 9.148437,-22.09961 5.65,-5.65 13.471795,-9.16016 22.091795,-9.16016 z m 233.16993,11.50976 c 5.47,0 10.45101,2.23008 14.04101,5.83008 3.59,3.59 5.83008,8.55906 5.83008,14.03906 0,5.48 -2.23031,10.45102 -5.82031,14.04102 l -0.0996,0.0996 c -3.59,3.54 -8.53117,5.73047 -13.95117,5.73047 -5.48001,0 -10.44907,-2.23031 -14.03907,-5.82031 l -0.0996,-0.0996 c -3.54,-3.59 -5.73047,-8.53141 -5.73047,-13.94141 0,-5.47 2.23008,-10.44906 5.83008,-14.03906 3.59,-3.59 8.55906,-5.83008 14.03907,-5.83008 z m 78.32031,0 c 5.48,0 10.45101,2.23032 14.04101,5.82032 l 0.0996,0.0996 c 3.53,3.59 5.73047,8.52921 5.73047,13.94921 0,5.47 -2.23008,10.45102 -5.83008,14.04102 -3.58,3.59 -8.56101,5.83008 -14.04101,5.83008 -5.48,0 -10.44906,-2.23055 -14.03907,-5.81055 -3.58999,-3.59 -5.82031,-8.57078 -5.82031,-14.05078 0,-5.48 2.23031,-10.44883 5.82031,-14.04883 3.59,-3.59 8.55907,-5.82031 14.03907,-5.82031 z m -39.24024,34.83008 -0.01,0.01 c 5.48,0 10.46078,2.23054 14.05078,5.81054 l 0.0996,0.0996 c 3.53,3.59 5.7207,8.51922 5.7207,13.94922 0,5.48 -2.23055,10.45102 -5.81055,14.04102 -3.59,3.59 -8.57078,5.80859 -14.05078,5.80859 -5.48,0 -10.44883,-2.22859 -14.04883,-5.80859 -3.58999,-3.59 -5.81054,-8.56102 -5.81054,-14.04102 0,-5.48 2.23054,-10.44883 5.81054,-14.04883 3.59,-3.59 8.56883,-5.82031 14.04883,-5.82031 z m -220.64843,15.16992 0.01,0.01 h 19.61914 c 1.53,0 2.92946,0.63062 3.93946,1.64062 l 0.10156,0.10938 c 0.95,0.99 1.53906,2.35008 1.53906,3.83008 v 19.20898 h 19.99023 c 1.31,0 2.53086,0.55039 3.38086,1.40039 l 0.14844,0.16992 c 0.77,0.85 1.26172,1.98118 1.26172,3.20118 v 21.21875 c 0,1.3 -0.55039,2.50109 -1.40039,3.37109 -0.89,0.88 -2.10704,1.54834 -3.39063,1.41992 H 190.4375 v 19.20899 c 0,1.52 -0.63063,2.91968 -1.64062,3.92968 -1.02001,1.01 -2.41922,1.64063 -3.94922,1.64063 h -19.61914 c -1.53,0 -2.94141,-0.64063 -3.94141,-1.64063 -1.01,-1.01 -1.64844,-2.40945 -1.64844,-3.93945 v -19.20898 h -19.99023 c -1.31,0 -2.50133,-0.54039 -3.36133,-1.40039 -0.88,-0.89 -1.41992,-2.09063 -1.41992,-3.39063 v -21.2207 c 0,-1.31 0.55039,-2.51914 1.40039,-3.36914 l 0.18945,-0.16016 c 0.85,-0.76 1.97747,-1.11878 3.19141,-1.24023 h 19.99023 V 187.9514 c 0,-1.53 0.62867,-2.9314 1.63867,-3.9414 l 0.13086,-0.11915 c 1,-0.93 2.35032,-1.51953 3.82032,-1.51953 z m 153.54882,8.21875 c 8.61,0 16.43961,3.50016 22.09961,9.16016 5.66,5.66 9.16016,13.46961 9.16016,22.09961 0,8.62 -3.49844,16.4418 -9.14844,22.0918 l -0.10156,0.0996 c -5.65,5.59 -13.42,9.04882 -22,9.04882 -8.61,0 -16.42008,-3.49843 -22.08008,-9.14843 -5.67,-5.66 -9.16015,-13.47008 -9.16015,-22.08008 0,-8.63 3.50039,-16.45156 9.15039,-22.10156 5.65,-5.65 13.45984,-9.16016 22.08984,-9.16016 z''',
  '''m 346.79,132.37 c 5.47,0 10.45,2.23 14.04,5.83 3.59,3.59 5.83,8.56 5.83,14.04 0,5.48 -2.23,10.45 -5.82,14.04 l -0.1,0.1 c -3.59,3.54 -8.53,5.73 -13.95,5.73 -5.48,0 -10.45,-2.23 -14.04,-5.82 l -0.1,-0.1 c -3.54,-3.59 -5.73,-8.53 -5.73,-13.94 0,-5.47 2.23,-10.45 5.83,-14.04 3.59,-3.59 8.56,-5.83 14.04,-5.83 z m 39.07,34.84 c 5.48,0 10.46,2.23 14.05,5.81 l 0.1,0.1 c 3.53,3.59 5.72,8.52 5.72,13.95 0,5.48 -2.23,10.45 -5.81,14.04 -3.59,3.59 -8.57,5.81 -14.05,5.81 -5.48,0 -10.45,-2.23 -14.05,-5.81 -3.59,-3.59 -5.81,-8.56 -5.81,-14.04 0,-5.48 2.23,-10.45 5.81,-14.05 3.59,-3.59 8.57,-5.82 14.05,-5.82 z m 39.25,-34.84 c 5.48,0 10.45,2.23 14.04,5.82 l 0.1,0.1 c 3.53,3.59 5.73,8.53 5.73,13.95 0,5.47 -2.23,10.45 -5.83,14.04 -3.58,3.59 -8.56,5.83 -14.04,5.83 -5.48,0 -10.45,-2.23 -14.04,-5.81 -3.59,-3.59 -5.82,-8.57 -5.82,-14.05 0,-5.48 2.23,-10.45 5.82,-14.05 3.59,-3.59 8.56,-5.82 14.04,-5.82 z M 385.86,98.69 c 5.48,0 10.45,2.23 14.04,5.82 l 0.1,0.1 c 3.53,3.58 5.73,8.53 5.73,13.94 0,5.48 -2.23,10.45 -5.81,14.05 l -0.1,0.1 c -3.59,3.54 -8.53,5.73 -13.95,5.73 -5.47,0 -10.45,-2.23 -14.04,-5.83 -3.59,-3.59 -5.82,-8.56 -5.82,-14.04 0,-5.47 2.23,-10.45 5.83,-14.04 3.59,-3.59 8.56,-5.83 14.04,-5.83 z m -220.63,83.69 h 19.62 c 1.53,0 2.93,0.63 3.94,1.64 l 0.1,0.11 c 0.95,0.99 1.54,2.35 1.54,3.83 v 19.21 h 19.99 c 1.31,0 2.53,0.55 3.38,1.4 l 0.15,0.17 c 0.77,0.85 1.26,1.98 1.26,3.2 v 21.22 c 0,1.3 -0.55,2.5 -1.4,3.37 -0.89,0.88 -2.10641,1.54842 -3.39,1.42 h -19.99 v 19.21 c 0,1.52 -0.63,2.92 -1.64,3.93 -1.02,1.01 -2.42,1.64 -3.95,1.64 h -19.62 c -1.53,0 -2.94,-0.64 -3.94,-1.64 -1.01,-1.01 -1.65,-2.41 -1.65,-3.94 v -19.21 h -19.99 c -1.31,0 -2.5,-0.54 -3.36,-1.4 -0.88,-0.89 -1.42,-2.09 -1.42,-3.39 v -21.22 c 0,-1.31 0.55,-2.52 1.4,-3.37 l 0.19,-0.16 c 0.85,-0.76 1.97606,-1.11855 3.19,-1.24 h 19.99 v -19.21 c 0,-1.53 0.63,-2.93 1.64,-3.94 l 0.13,-0.12 c 1,-0.93 2.35,-1.52 3.82,-1.52 z m 153.54,8.21 c 8.61,0 16.44,3.5 22.1,9.16 5.66,5.66 9.16,13.47 9.16,22.1 0,8.62 -3.5,16.44 -9.15,22.09 l -0.1,0.1 c -5.65,5.59 -13.42,9.05 -22,9.05 -8.61,0 -16.42,-3.5 -22.08,-9.15 -5.67,-5.66 -9.16,-13.47 -9.16,-22.08 0,-8.63 3.5,-16.45 9.15,-22.1 5.65,-5.65 13.46,-9.16 22.09,-9.16 z M 113.62,120.86 c 8.62,0 16.44,3.5 22.1,9.16 5.65,5.65 9.16,13.48 9.16,22.1 0,8.62 -3.5,16.45 -9.16,22.1 l -0.1,0.1 c -5.65,5.59 -13.42,9.06 -21.99,9.06 -8.62,0 -16.44,-3.51 -22.09,-9.15 -5.65,-5.65 -9.15,-13.48 -9.15,-22.1 0,-8.61 3.5,-16.44 9.15,-22.1 5.65,-5.65 13.47,-9.16 22.09,-9.16 z''',
  '''m 28.908203,165.29888 c 15.240461,24.39432 37.044054,56.10152 57.109375,82.72265 16.318612,21.62807 31.481292,39.85896 41.033202,48.0293 -7.5603,4.52626 -15.41029,19.97781 -24.36328,37.60938 -15.21,29.96 -33.810234,66.55023 -56.240234,62.74023 -19,-3.23 -30.518907,-11.47953 -36.6289066,-26.26953 -6.27,-15.16 -7.0798438,-37.27008 -4.5898438,-67.83008 1.89,-23.2 7.3100004,-55.74094 13.5000004,-87.71094 3.320879,-17.17034 6.840524,-33.99231 10.179687,-49.29101 z''',
  '''m 476.58008,165.27148 c 3.34432,15.31767 6.87178,32.16521 10.19726,49.35938 6.19,31.95 11.61,64.47992 13.5,87.66992 2.49,30.56 1.68016,52.67008 -4.58984,67.83008 -6.11,14.79 -17.62891,23.04953 -36.62891,26.26953 -22.43,3.81 -41.02023,-32.77023 -56.24023,-62.74023 -8.95891,-17.6518 -16.82213,-33.10433 -24.38281,-37.61719 9.56767,-8.18862 24.72065,-26.39521 41.02148,-48.01172 20.07546,-26.62511 41.88255,-58.3597 57.12305,-82.75977 z''',
  '''m 362.52148,44.507812 c -1.07798,-0.01084 -2.11226,-0.0028 -3.10351,0.02344 -8.14,0.22 -13.5011,1.698984 -17.12109,3.958984 -1.39001,0.87 -3.32875,1.931016 -5.46876,3.041016 l -8.12109,3.988281 c -23.52614,-1.166606 -49.73629,-1.759765 -75.96875,-1.759765 -26.24113,0 -52.46006,0.59499 -75.99219,1.763672 l -8.08789,-3.982422 c -2.14,-1.11 -4.07093,-2.16125 -5.46093,-3.03125 -3.62,-2.25 -8.9804,-3.738985 -17.15039,-3.958985 -7.91,-0.22 -18.53946,0.739297 -32.93946,3.279297 -14.489996,2.55 -26.689061,6.840858 -36.289061,13.13086 -9.558847,6.251151 -16.542648,14.513631 -20.65039,25.005859 -9.131053,7.123084 -14.862513,14.010749 -16.490235,18.083981 -1.354813,3.39025 -6.975281,25.94942 -13.533203,55.625 -0.01264,0.047 -0.02012,0.0948 -0.0293,0.14258 C 22.46831,176.32625 18.538884,194.96181 14.87695,213.87109 8.6669532,245.96109 3.2183594,278.65 1.3183594,302 c -2.53,31.15 -1.66109375,53.81109 4.8789062,69.62109 6.6800004,16.16 19.1198434,25.15891 39.5898434,28.62891 25.24,4.3 44.551565,-33.70031 60.351561,-64.82031 9.91,-19.51 18.39875,-36.20906 24.96875,-36.78907 23.66,-2.04999 72.39016,-3.06054 121.16016,-3.06054 49.37,0 98.70984,1.04054 122.08984,3.06054 6.56,0.58 15.06071,17.26907 24.9707,36.78907 15.81001,31.11 35.10961,69.12031 60.34961,64.82031 20.47,-3.48 32.90985,-12.46891 39.58985,-28.62891 6.54,-15.81 7.42086,-38.46109 4.88086,-69.62109 -1.91,-23.35 -7.35055,-56.01961 -13.56055,-88.09961 -3.64944,-18.86673 -7.56548,-37.45779 -11.20508,-53.94141 -0.0149,-0.1236 -0.0403,-0.24489 -0.0781,-0.36328 -6.54938,-29.63868 -12.16421,-52.16158 -13.5176,-55.55468 C 464.15419,99.982275 458.44452,93.105152 449.3418,85.992188 445.21679,75.492625 438.22785,67.219239 428.6582,60.951172 l 0.0195,-0.0098 c -9.6,-6.29 -21.78906,-10.580859 -36.28906,-13.130859 -12.6,-2.2225 -22.32127,-3.226855 -29.86719,-3.302735 z m -4.67968,4.736329 c 0.53308,-0.0026 1.07056,0.01146 1.61132,0.04297 13.20796,-0.145178 26.3871,1.936033 39.39063,4.621094 20.1227,4.160736 41.04568,15.25607 48.63281,35.550781 8.20187,6.454136 13.31475,12.498964 14.72071,16.021484 1.30988,3.30015 6.77189,25.25097 13.19531,54.32812 -15.24238,24.71253 -38.12609,58.12019 -59.05469,85.88282 -17.40117,23.08078 -33.39232,42.1772 -42.36914,48.98047 -23.82896,-2.01036 -72.76511,-3.03126 -121.68164,-3.03126 -48.32048,0 -96.65216,1.00202 -120.74219,3.03126 -8.97204,-6.78563 -24.98754,-25.90768 -42.406248,-49.01172 -20.917409,-27.74779 -43.798431,-61.13119 -59.041016,-85.83008 6.42658,-29.09903 11.893865,-51.06647 13.210938,-54.34961 1.405964,-3.52256 6.51858,-9.567247 14.720703,-16.021484 2.586751,-6.678923 6.64759,-12.782912 11.841797,-17.716796 19.0183,-17.524075 46.739526,-20.629395 71.470706,-22.431641 1.69581,-0.04434 3.39242,-0.04934 5.08789,0.01172 10.60001,-0.687329 19.11622,5.942164 28.23242,10.214843 0.5945,-0.0305 1.16757,-0.06598 1.76562,-0.0957 0.008,-4.56e-4 0.0155,-0.0034 0.0234,-0.0039 23.56413,-1.172339 49.91276,-1.767578 76.30664,-1.767578 27.05508,0 54.0857,0.621302 78.09571,1.853516 0.27043,-0.561351 1.79759,-1.379133 5.06054,-2.558594 6.78424,-3.918757 13.93145,-7.681279 21.92774,-7.720703 z M 476.58008,165.27148 c 3.34432,15.31767 6.87178,32.16521 10.19726,49.35938 6.19,31.95 11.61,64.47992 13.5,87.66992 2.49,30.56 1.68016,52.67008 -4.58984,67.83008 -6.11,14.79 -17.62891,23.04953 -36.62891,26.26953 -22.43,3.81 -41.02023,-32.77023 -56.24023,-62.74023 -8.95891,-17.6518 -16.82213,-33.10433 -24.38281,-37.61719 9.56767,-8.18862 24.72065,-26.39521 41.02148,-48.01172 20.07546,-26.62511 41.88255,-58.3597 57.12305,-82.75977 z m -447.671877,0.0274 c 15.240461,24.39432 37.044054,56.10152 57.109375,82.72265 16.318612,21.62807 31.481292,39.85896 41.033202,48.0293 -7.5603,4.52626 -15.41029,19.97781 -24.36328,37.60938 -15.21,29.96 -33.810234,66.55023 -56.240234,62.74023 -19,-3.23 -30.518907,-11.47953 -36.6289066,-26.26953 -6.27,-15.16 -7.0798438,-37.27008 -4.5898438,-67.83008 1.89,-23.2 7.3100004,-55.74094 13.5000004,-87.71094 3.320879,-17.17034 6.840524,-33.99231 10.179687,-49.29101 z''',
];
const Size jcv = Size(166.23, 221.81);
const List<String> jcl = [
  '''M 118.8,0 H 90.17 C 66.63,0 47.43,19.2 47.43,42.67 v 136.47 c 0,23.48 19.2,42.67 42.67,42.67 h 28.7 z M 85.38,39.2 c 9.44,0 17.1,7.65 17.1,17.09 0,9.44 -7.66,17.09 -17.1,17.09 -9.44,0 -17.09,-7.65 -17.09,-17.09 0,-9.44 7.66,-17.09 17.09,-17.09 z m 16.1,-19.13 h 12.03 c 0.28,0 0.5,0.22 0.5,0.5 v 2.96 c 0,0.28 -0.23,0.5 -0.5,0.5 H 101.48 c -0.28,0 -0.5,-0.22 -0.5,-0.5 v -2.96 c 0,-0.28 0.22,-0.5 0.5,-0.5 z m -7.37,132.49 h 6.47 c 1.81,0 3.28,1.47 3.28,3.28 v 6.48 c 0,1.8 -1.47,3.28 -3.28,3.28 h -6.47 c -1.81,0 -3.28,-1.48 -3.28,-3.28 v -6.48 c 0,-1.8 1.47,-3.28 3.28,-3.28 z m -16.53,-35 c 0,4.45 -3.61,8.07 -8.06,8.07 -4.45,0 -8.07,-3.62 -8.07,-8.07 0,-4.45 3.62,-8.06 8.07,-8.06 4.45,0 8.06,3.61 8.06,8.06 z m 8.28,8.28 c 4.45,0 8.06,3.62 8.06,8.07 0,4.46 -3.61,8.07 -8.06,8.07 -4.45,0 -8.07,-3.61 -8.07,-8.07 0,-4.45 3.61,-8.07 8.07,-8.07 z m 24.41,-8.28 c 0,4.45 -3.62,8.07 -8.07,8.07 -4.46,0 -8.07,-3.62 -8.07,-8.07 0,-4.45 3.61,-8.06 8.07,-8.06 4.45,0 8.07,3.61 8.07,8.06 z M 85.86,93.15 c 4.45,0 8.06,3.61 8.06,8.07 0,4.45 -3.61,8.07 -8.06,8.07 -4.45,0 -8.07,-3.62 -8.07,-8.07 0,-4.45 3.61,-8.07 8.07,-8.07 z''',
  '''m 118.8,221.81 c -97.726667,0 -48.863333,0 0,0 z M 85.38,39.2 c 9.44,0 17.1,7.65 17.1,17.09 0,9.44 -7.66,17.09 -17.1,17.09 -9.44,0 -17.09,-7.65 -17.09,-17.09 0,-9.44 7.66,-17.09 17.09,-17.09 z m 16.1,-19.13 h 12.03 c 0.28,0 0.5,0.22 0.5,0.5 v 2.96 c 0,0.28 -0.23,0.5 -0.5,0.5 H 101.48 c -0.28,0 -0.5,-0.22 -0.5,-0.5 v -2.96 c 0,-0.28 0.22,-0.5 0.5,-0.5 z m -7.37,132.49 h 6.47 c 1.81,0 3.28,1.47 3.28,3.28 v 6.48 c 0,1.8 -1.47,3.28 -3.28,3.28 h -6.47 c -1.81,0 -3.28,-1.48 -3.28,-3.28 v -6.48 c 0,-1.8 1.47,-3.28 3.28,-3.28 z m -16.53,-35 c 0,4.45 -3.61,8.07 -8.06,8.07 -4.45,0 -8.07,-3.62 -8.07,-8.07 0,-4.45 3.62,-8.06 8.07,-8.06 4.45,0 8.06,3.61 8.06,8.06 z m 8.28,8.28 c 4.45,0 8.06,3.62 8.06,8.07 0,4.46 -3.61,8.07 -8.06,8.07 -4.45,0 -8.07,-3.61 -8.07,-8.07 0,-4.45 3.61,-8.07 8.07,-8.07 z m 24.41,-8.28 c 0,4.45 -3.62,8.07 -8.07,8.07 -4.46,0 -8.07,-3.62 -8.07,-8.07 0,-4.45 3.61,-8.06 8.07,-8.06 4.45,0 8.07,3.61 8.07,8.06 z M 85.86,93.15 c 4.45,0 8.06,3.61 8.06,8.07 0,4.45 -3.61,8.07 -8.06,8.07 -4.45,0 -8.07,-3.62 -8.07,-8.07 0,-4.45 3.61,-8.07 8.07,-8.07 z''',
  '''M 90.10,0 C 66.63,0 47.43,19.20 47.43,42.67 V 179.14 c 0,23.48 19.20,42.70 42.67,42.70 h 28.70 V 0 Z m 12.81,2.00 c 4.63,0.00 9.26,0.01 13.88,0.00 V 219.80 h -23.67 c -21.20,1.83 -41.77,-15.22 -43.48,-36.50 -0.51,-46.19 -0.06,-92.41 -0.21,-138.62 -1.46,-22.12 17.42,-42.57 39.60,-42.68 4.63,-0.02 9.26,-0.012 13.88,-0.01 z''',
];
const List<String> jcr = [
  '''m 47.43,0 h 28.7 C 99.6,0 118.8,19.2 118.8,42.67 v 136.47 c 0,23.48 -19.2,42.67 -42.67,42.67 h -28.7 z m 6.17,20.07 h 4.04 v -4.05 c 0,-0.28 0.23,-0.5 0.5,-0.5 h 2.95 c 0.28,0 0.5,0.22 0.5,0.5 v 4.05 h 4.04 c 0.27,0 0.5,0.22 0.5,0.5 v 2.96 c 0,0.27 -0.22,0.49 -0.5,0.49 h -4.04 v 4.04 c 0,0.27 -0.23,0.5 -0.5,0.5 h -2.95 c -0.28,0 -0.5,-0.23 -0.5,-0.5 V 24.02 H 53.6 c -0.27,0 -0.5,-0.22 -0.5,-0.49 v -2.96 c 0,-0.28 0.23,-0.5 0.5,-0.5 z m 15.95,130.94 c 4.46,0 8.07,3.62 8.07,8.06 0,4.46 -3.61,8.07 -8.07,8.07 -4.45,0 -8.06,-3.61 -8.06,-8.07 0,-4.45 3.62,-8.06 8.06,-8.06 z m 3.58,-94.83 c 0,4.46 -3.61,8.07 -8.06,8.07 -4.45,0 -8.06,-3.61 -8.06,-8.07 0,-4.45 3.61,-8.06 8.06,-8.06 4.45,0 8.06,3.62 8.06,8.06 z m 8.28,8.29 c 4.45,0 8.07,3.61 8.07,8.06 0,4.46 -3.62,8.07 -8.07,8.07 -4.45,0 -8.06,-3.61 -8.06,-8.07 0,-4.45 3.61,-8.06 8.06,-8.06 z m 24.42,-8.29 c 0,4.46 -3.61,8.07 -8.07,8.07 -4.45,0 -8.06,-3.61 -8.06,-8.07 0,-4.45 3.62,-8.06 8.06,-8.06 4.46,0 8.07,3.62 8.07,8.06 z M 81.41,31.77 c 4.45,0 8.07,3.61 8.07,8.07 0,4.45 -3.62,8.06 -8.07,8.06 -4.45,0 -8.06,-3.61 -8.06,-8.06 0,-4.45 3.61,-8.07 8.06,-8.07 z m -0.1,69.19 c 9.44,0 17.09,7.66 17.09,17.09 0,9.44 -7.65,17.09 -17.09,17.09 -9.43,0 -17.09,-7.65 -17.09,-17.09 0,-9.44 7.66,-17.09 17.09,-17.09 z''',
  '''m 47.43,221.81 c -50.1466667,0 -25.073333,0 0,0 z M 53.6,20.07 h 4.04 v -4.05 c 0,-0.28 0.23,-0.5 0.5,-0.5 h 2.95 c 0.28,0 0.5,0.22 0.5,0.5 v 4.05 h 4.04 c 0.27,0 0.5,0.22 0.5,0.5 v 2.96 c 0,0.27 -0.22,0.49 -0.5,0.49 h -4.04 v 4.04 c 0,0.27 -0.23,0.5 -0.5,0.5 h -2.95 c -0.28,0 -0.5,-0.23 -0.5,-0.5 V 24.02 H 53.6 c -0.27,0 -0.5,-0.22 -0.5,-0.49 v -2.96 c 0,-0.28 0.23,-0.5 0.5,-0.5 z m 15.95,130.94 c 4.46,0 8.07,3.62 8.07,8.06 0,4.46 -3.61,8.07 -8.07,8.07 -4.45,0 -8.06,-3.61 -8.06,-8.07 0,-4.45 3.62,-8.06 8.06,-8.06 z m 3.58,-94.83 c 0,4.46 -3.61,8.07 -8.06,8.07 -4.45,0 -8.06,-3.61 -8.06,-8.07 0,-4.45 3.61,-8.06 8.06,-8.06 4.45,0 8.06,3.62 8.06,8.06 z m 8.28,8.29 c 4.45,0 8.07,3.61 8.07,8.06 0,4.46 -3.62,8.07 -8.07,8.07 -4.45,0 -8.06,-3.61 -8.06,-8.07 0,-4.45 3.61,-8.06 8.06,-8.06 z m 24.42,-8.29 c 0,4.46 -3.61,8.07 -8.07,8.07 -4.45,0 -8.06,-3.61 -8.06,-8.07 0,-4.45 3.62,-8.06 8.06,-8.06 4.46,0 8.07,3.62 8.07,8.06 z M 81.41,31.77 c 4.45,0 8.07,3.61 8.07,8.07 0,4.45 -3.62,8.06 -8.07,8.06 -4.45,0 -8.06,-3.61 -8.06,-8.06 0,-4.45 3.61,-8.07 8.06,-8.07 z m -0.1,69.19 c 9.44,0 17.09,7.66 17.09,17.09 0,9.44 -7.65,17.09 -17.09,17.09 -9.43,0 -17.09,-7.65 -17.09,-17.09 0,-9.44 7.66,-17.09 17.09,-17.09 z''',
  '''M 47.43 0 L 47.43 221.81 L 76.13 221.81 C 99.60,221.81 118.80,202.62 118.80,179.14 L 118.80 42.67 C 118.80,19.20 99.60,0.0 76.13,0 L 47.43 0 z M 77.00 1.88 C 96.42,2.31 114.41,17.95 116.47,37.53 C 117.25,82.36 116.57,127.26 116.80,172.11 C 118.43,187.62 112.22,204.17 98.84,212.83 C 84.44,223.25 65.89,218.94 49.43,219.81 C 49.43,147.21 49.43,74.60 49.43,2.00 L 73.11 2.00 C 74.41,1.89 75.71,1.85 77.00,1.88 z''',
];
const List<Color> colors = [
  Colors.white,
  Colors.black,
  Colors.yellow,
  Colors.blue,
  Colors.purple
];

class _PathDrawer extends CustomPainter {
  final Size viewPort;
  final Paint _paint = Paint();
  final List<Path> _paths;

  _PathDrawer(List<String> path, this.viewPort)
      : _paths = path.map((e) => parseSvgPathData(e)).toList();

  @override
  void paint(Canvas canvas, Size size) {
    final dx = size.width / viewPort.width;
    final dy = size.height / viewPort.height;
    final dd = min(dx, dy);
    final Offset tr = size - viewPort * dd;
    canvas.translate(tr.dx / 2, tr.dy / 2);
    canvas.scale(dd);
    _paths.asMap().forEach((i, e) {
      _paint.color = colors[i];
      canvas.drawPath(e, _paint);
    });
  }

  @override
  bool shouldRepaint(_PathDrawer oldDelegate) {
    return false;
  }
}

class _SvgDrawer extends CustomPainter {
  final DrawableRoot drawable;

  _SvgDrawer(this.drawable);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint p = Paint();
    print('$size , ${drawable.children.length}');
    drawable.scaleCanvasToViewBox(canvas, size);
    drawable.children.asMap().forEach((i, e) {
      Color color = colors[i];
      if (color != null) {
        p.colorFilter = ColorFilter.mode(color, BlendMode.srcIn);
        canvas.saveLayer(null, p);
      }
      e.draw(canvas, rect);
      if (color != null) {
        canvas.restore();
      }
    });
  }

  @override
  bool shouldRepaint(_PathDrawer oldDelegate) {
    return false;
  }
}

class _Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('_Home -> build');
    final Widget child = Center(
      child: Column(
        children: [
          PopupMenuButton<Locale>(
            initialValue: Config.of(context).locale,
            child: Text(kLanguages[Config.of(context).locale]),
            onSelected: (locale) => Bloc.of(context).config =
                Config.of(context).copyWith(locale: locale),
            itemBuilder: (context) {
              return S.delegate.supportedLocales
                  .map((e) => PopupMenuItem<Locale>(
                        value: e,
                        child: Text(kLanguages[e]),
                      ))
                  .toList(growable: false);
            },
          ),
          PopupMenuButton<TextScale>(
            initialValue: Config.of(context).textScale,
            child: Text(Config.of(context).textScale.label),
            onSelected: (value) => Bloc.of(context).config =
                Config.of(context).copyWith(textScale: value),
            itemBuilder: (context) {
              return kTextScales
                  .map((e) => PopupMenuItem<TextScale>(
                        value: e,
                        child: Text(e.label),
                      ))
                  .toList(growable: false);
            },
          ),
          Switch(
            value: Config.of(context).themeMode == ThemeMode.dark,
            onChanged: (v) {
              Bloc.of(context).config = Config.of(context).copyWith(
                themeMode: v ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
          Switch(
            value: Config.of(context).timeDilation,
            onChanged: (v) {
              Bloc.of(context).config = Config.of(context).copyWith(
                timeDilation: v,
              );
            },
          ),
          Selector<BluetoothDeviceRecord, int>(
            selector: (_, r) => r.records.length,
            builder: (context, length, _) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: length,
                itemBuilder: (context, index) {
                  return Selector<BluetoothDeviceRecord, DeviceState>(
                    selector: (_, r) => r[index],
                    builder: (context, state, _) {
                      final bundle =
                          BluetoothDeviceRecord.of(context).records[index];
                      final Widget child = ListTile(
                        leading: const Icon(Icons.games),
                        title: Text(bundle.name),
                        subtitle: Text(bundle.address),
                      );
                      final Widget open = _Detail(device: bundle);
                      return OpenContainer(
                        transitionDuration: const Duration(seconds: 5),
                        closedBuilder: (context, open) => child,
                        openBuilder: (context, _) => open,
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
    Widget body;
    final DeviceType type = DeviceType.of(context);
    if (type.isPhone) body = _Phone(child: child);
    if (type.isTable) body = _Tablet(child: child);
    if (type.isDesktop) body = _Desktop(child: child);
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).app_title)),
      body: body,
      floatingActionButton: _DiscoveryWidget(
        false,
        onPressed: () {
          Bloc.of(context).inject(
              BluetoothDevice.test('device', '0'), DeviceState.CONNECTED);
        },
      ),
    );
  }
}

class _DiscoveryWidget extends StatefulWidget {
  final bool discovering;
  final VoidCallback onPressed;

  const _DiscoveryWidget(this.discovering, {this.onPressed});

  bool get disabled => onPressed == null;

  @override
  State<StatefulWidget> createState() => _DiscoveryWidgetState();
}

class _DiscoveryWidgetState extends State<_DiscoveryWidget>
    with TickerProviderStateMixin {
  AnimationController _rotateController;
  AnimationController _scaleController;
  CurvedAnimation _curve;
  Tween<double> _rotate;
  Tween<double> _scale;

  bool get discovering => widget.discovering;

  bool get disabled => widget.disabled;

  @override
  void initState() {
    super.initState();
    /*
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleController = AnimationController(vsync: this, duration: kDuration);

    _rotate = Tween<double>(begin: 0, end: 2 * 3.14);
    _scale = Tween<double>(begin: disabled ? 0 : 1);
    _curve = CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut);

     */
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('_DiscoveryWidget -> didChangeDependencies');
  }

  @override
  Widget build(BuildContext context) {
    print('_DiscoveryWidget -> build');
    return FloatingActionButton(
      child: const Icon(Icons.refresh),
      onPressed: widget.onPressed,
    );
    return ScaleTransition(
      scale: _scale.animate(_scaleController),
      child: FloatingActionButton(
        tooltip: 'discovery',
        child: RotationTransition(
          turns: _rotate.animate(_curve),
          child: const Icon(Icons.refresh),
        ),
        onPressed: widget.onPressed,
      ),
    );
  }

  @override
  void didUpdateWidget(_DiscoveryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discovering != discovering) {
      if (discovering)
        _rotateController.repeat();
      else
        _rotateController.animateTo(1);
    }
    if (oldWidget.disabled != disabled) {
      if (disabled)
        _scale.end = 0;
      else
        _scale.end = 1;
      _scaleController.reset();
      _scaleController.forward();
    }
  }
}

class _Phone extends StatelessWidget {
  final Widget child;

  const _Phone({@required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(Size.fromWidth(400)),
          child: child,
        ),
      ),
    );
  }
}

class _Tablet extends StatelessWidget {
  final Widget child;

  const _Tablet({@required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(Size.fromWidth(800)),
          child: child,
        ),
      ),
    );
  }
}

class _Desktop extends StatelessWidget {
  final Widget child;

  const _Desktop({@required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(Size.fromWidth(1200)),
          child: child,
        ),
      ),
    );
  }
}

class _Detail extends StatefulWidget {
  final BluetoothDevice device;

  const _Detail({@required this.device});

  @override
  State<StatefulWidget> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  @override
  Widget build(BuildContext context) {
    print('_Detail -> build');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Selector<BluetoothDeviceRecord, DeviceState>(
        selector: (_, r) =>
            r.records.firstWhere((e) => e == widget.device).state,
        child: Center(child: Text(widget.device.toString())),
        builder: (context, state, child) {
          print('check device state');
          if (state != DeviceState.CONNECTED) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text('disconnected'),
                      actions: [
                        FlatButton(
                          onPressed: () {
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  });
            });
          }
          return child;
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.close),
        onPressed: () {
          Bloc.of(context).inject(
              BluetoothDevice.test('device', '0'), DeviceState.DISCONNECTING);
        },
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('_Detail -> didChangeDependencies');
  }
}

const String kInitPage = '''
<!DOCTYPE HTML>
<html>
<body>
<canvas id="my-canvas" width="300" height="300"></canvas>
</body>
</html>
''';

class _WebHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Completer<WebViewController> _controller =
        Completer<WebViewController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView'),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.restore),
        onPressed: () {
          _controller.future.then((value) {
            value.evaluateJavascript('window.resetModel();');
          });
        },
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (detail) {
          _controller.future.then((value) {
            value.evaluateJavascript(
                'window.rotateY(${detail.delta.dx / pi / 2});\nwindow.render();');
          });
        },
        onVerticalDragUpdate: (detail) {
          _controller.future.then((value) {
            value.evaluateJavascript(
                'window.rotateX(${detail.delta.dy / pi / 2});\nwindow.render();');
          });
        },
        child: WebView(
          initialUrl:
              'data:text/html;base64,${base64Encode(const Utf8Encoder().convert(kInitPage))}',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            _controller.complete(webViewController);
          },
          onPageStarted: (url) => print('Page started loading: $url'),
          onPageFinished: (url) {
            print('Page finished loading: $url');
            _controller.future.then((value) async {
              var s = DateTime.now().millisecondsSinceEpoch;
              String js = await rootBundle.loadString('assets/webgl/main.js');
              var obj = await rootBundle.load('assets/webgl/model/jc_l.glb');
              var e = DateTime.now().millisecondsSinceEpoch;
              print('load string use ${e - s} ms');
              value.evaluateJavascript('''$js
              window.parse(${obj.buffer.asUint8List()});
              window.render();''').then((value) {
                var t = DateTime.now().millisecondsSinceEpoch;
                print('execute js use ${t - s} ms');
              });
              var t = DateTime.now().millisecondsSinceEpoch;
              print('load js use ${t - s} ms');
            });
          },
          gestureNavigationEnabled: false,
        ),
      ),
    );
  }
}

// test OpenContainer performance
class _ContainerHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget from = ListTile(title: Text('from'));
    Widget to = Scaffold(
      appBar: AppBar(),
      body: Text('to'),
    );
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: <Widget>[
          OpenContainer(
            tappable: true,
            //transitionType: ContainerTransitionType.fadeThrough,
            transitionDuration: kDuration,
            closedShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            closedColor: Theme.of(context).accentColor,
            closedElevation: 4,
            closedBuilder: (_, open) {
              return from;
            },
            openElevation: 0,
            openBuilder: (c, __) {
              //print('openBuilder');
              return to;
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent/android_intent.dart';
import 'widgets/fade.dart';
import 'dart:io';

const String _permissionUrl =
    'https://developer.android.google.cn/guide/topics/connectivity/bluetooth?hl=en#Permissions';
const String _locationUrl =
    'http://aospxref.com/android-10.0.0_r2/xref/packages/apps/Bluetooth/src/com/android/bluetooth/btservice/AdapterService.java#1944';
const MethodChannel _versionChannel =
    const MethodChannel('com.mumumusuc.libjoycon/version');
final EventChannel _locationEvent = Platform.isAndroid
    ? const EventChannel('com.mumumusuc.libjoycon/location/state')
    : null;

Future<bool> _isAndroidQ() async {
  if (!Platform.isAndroid) return false;
  return _versionChannel
      .invokeMethod('isAndroidQ')
      .then((value) => value as bool);
}

Future<PermissionStatus> _getLocationPermissionStatus() {
  return _isAndroidQ().then((Q) {
    if (!Q) return PermissionStatus.granted;
    return PermissionHandler().checkPermissionStatus(PermissionGroup.location);
  });
}

Future<PermissionStatus> _requestLocationPermission() {
  return _isAndroidQ().then((Q) {
    if (!Q) return PermissionStatus.granted;
    final PermissionHandler lp = PermissionHandler();
    return lp
        .shouldShowRequestPermissionRationale(PermissionGroup.location)
        .then((value) {
      if (value)
        return lp.openAppSettings().then((value) => PermissionStatus.unknown);
      else
        return lp.requestPermissions([PermissionGroup.location]).then((value) {
          return value[PermissionGroup.location];
        });
    });
  });
}

Future<ServiceStatus> _getLocationServiceStatus() {
  return PermissionHandler().checkServiceStatus(PermissionGroup.location);
}

Future<ServiceStatus> _requestLocationService() async {
  if (Platform.isAndroid) {
    AndroidIntent(action: 'action_location_source_settings').launch();
  }
  return ServiceStatus.unknown;
}

Stream<ServiceStatus> get _serviceStatus =>
    _locationEvent?.receiveBroadcastStream()?.map((dynamic status) {
      return status ? ServiceStatus.enabled : ServiceStatus.disabled;
    });

class _PermissionStatus extends ChangeNotifier
    implements ValueListenable<bool> {
  PermissionStatus _status;
  bool _ignore;

  _PermissionStatus({
    PermissionStatus status = PermissionStatus.unknown,
    bool ignore = false,
  })  : _status = status,
        _ignore = ignore;

  bool get abnormal => _status != PermissionStatus.granted;

  bool get value => abnormal && !_ignore;

  set ignore(bool value) {
    if (_ignore != value) {
      _ignore = value;
      notifyListeners();
    }
  }

  Future<bool> update() {
    return _getLocationPermissionStatus().then((value) {
      if (value != _status) {
        _status = value;
        notifyListeners();
      }
      return abnormal;
    });
  }

  void request() {
    _requestLocationPermission().then((value) {
      if (value != _status) {
        _status = value;
        notifyListeners();
      }
    });
  }
}

class _ServiceStatus extends ChangeNotifier implements ValueListenable<bool> {
  ServiceStatus _status;
  bool _ignore;

  _ServiceStatus({
    ServiceStatus status = ServiceStatus.unknown,
    bool ignore = false,
  }) {
    _status = status;
    _ignore = ignore;
    _serviceStatus?.listen((event) {
      if (_status != event) {
        _status = event;
        notifyListeners();
      }
    });
  }

  bool get abnormal => _status != ServiceStatus.enabled;

  bool get value => abnormal && !_ignore;

  set ignore(bool value) {
    if (_ignore != value) {
      _ignore = value;
      notifyListeners();
    }
  }

  Future<bool> update() {
    return _getLocationServiceStatus().then((value) {
      if (value != _status) {
        _status = value;
        notifyListeners();
      }
      return abnormal;
    });
  }

  void request() => _requestLocationService();
}

abstract class PermissionState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  final _PermissionStatus _permission = _PermissionStatus();
  final _ServiceStatus _service = _ServiceStatus();

  void ignorePermission(bool ignore) => _permission.ignore = ignore;

  void ignoreService(bool ignore) => _service.ignore = ignore;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _permission.update();
      _service.update();
    }
  }

  void initState() {
    super.initState();
    _permission.update();
    _service.update();
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _permission.dispose();
    _service.dispose();
  }

  Future<bool> isPermissionReady({bool showBanner = false}) =>
      _isAndroidQ().then((Q) {
        if (!Q) return true;
        return Future.wait([_permission.update(), _service.update()]).then(
          (values) {
            if (values[0] && showBanner) {
              _permission.ignore = false;
            }
            if (values[1] && showBanner) {
              _service.ignore = false;
            }
            return !values[0] && !values[1];
          },
        );
      });

  Widget get permissionBanner {
    return ValueListenableProvider.value(
      value: _permission,
      child: Consumer<bool>(
        child: _permissionBannerWidget,
        builder: (context, abnormal, child) {
          return FadeWidget(
            fade: !abnormal,
            child: child,
          );
        },
      ),
    );
  }

  Widget get serviceBanner {
    return ValueListenableProvider.value(
      value: _service,
      child: Consumer<bool>(
        child: _serviceBannerWidget,
        builder: (context, abnormal, child) {
          return FadeWidget(
            fade: !abnormal,
            child: child,
          );
        },
      ),
    );
  }

  TextStyle get _hyperLinkTextStyle => const TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.blue,
        decoration: TextDecoration.underline,
      );

  Widget get _permissionBannerWidget {
    return MaterialBanner(
      leading: const CircleAvatar(
        child: const Icon(Icons.launch),
      ),
      leadingPadding: const EdgeInsets.only(
        right: 16,
        top: 16,
        bottom: 16,
      ),
      content: Text.rich(
        TextSpan(
          text: 'Android 10 (or higher) need ',
          children: [
            TextSpan(
                text: 'ACCESS_FINE_LOCATION',
                style: _hyperLinkTextStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    if (await canLaunch(_permissionUrl)) launch(_permissionUrl);
                  }),
            TextSpan(text: ' permission to start bluetooth discovery.'),
          ],
        ),
      ),
      actions: [
        FlatButton(
          child: Text('OK'),
          onPressed: _permission.request,
        ),
        FlatButton(
          child: Text('DISMISS'),
          onPressed: () => ignorePermission(true),
        ),
      ],
    );
  }

  Widget get _serviceBannerWidget {
    return MaterialBanner(
      leading: const CircleAvatar(
        child: const Icon(Icons.location_on),
      ),
      leadingPadding: const EdgeInsets.only(
        right: 16,
        top: 16,
        bottom: 16,
      ),
      content: Text.rich(
        TextSpan(
          text: 'Android 10 (or higher) need  ',
          children: [
            TextSpan(
              text: 'ENABLE LOCATION',
              style: _hyperLinkTextStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  if (await canLaunch(_locationUrl)) launch(_locationUrl);
                },
            ),
            TextSpan(text: ' to start bluetooth discovery'),
          ],
        ),
      ),
      actions: [
        FlatButton(
          child: Text('OK'),
          onPressed: _service.request,
        ),
        FlatButton(
          child: Text('DISMISS'),
          onPressed: () => ignoreService(true),
        ),
      ],
    );
  }
}

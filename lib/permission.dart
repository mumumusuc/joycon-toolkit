import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

typedef bool Check();

class Permission extends StatelessWidget {
  static const EdgeInsets _cardMargin =
      const EdgeInsets.symmetric(vertical: 4, horizontal: 4);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            _buildOpenBluetoothCard(context),
            _buildPermissionCard(context),
            _buildOpenLocationCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Widget leading, Widget title, Widget child, Check check,
      String label, VoidCallback onPressed) {
    final bool ok = check();
    return Card(
      clipBehavior: Clip.hardEdge,
      margin: _cardMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ExpansionTile(
            backgroundColor: Colors.transparent,
            leading: leading,
            title: title,
            trailing: Icon(Icons.help),
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                alignment: Alignment.center,
                height: 100,
                child: child,
              ),
            ],
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 4, top: 4),
            child: RaisedButton(
              child: ok ? Icon(Icons.check) : Text(label.toUpperCase()),
              elevation: 0,
              disabledColor: Colors.lightGreen,
              onPressed: ok ? null : onPressed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenBluetoothCard(BuildContext context) {
    return _buildCard(
      Icon(Icons.bluetooth),
      Text("open bluetooth"),
      Text.rich(
        TextSpan(text: "Obviously..."),
        style: Theme.of(context).textTheme.bodyText1,
      ),
      () => false,
      'enable',
      () {},
    );
  }

  Widget _buildPermissionCard(BuildContext context) {
    return _buildCard(
      Icon(Icons.add_location),
      Text("location permission"),
      Text.rich(
        TextSpan(
          text: "Android need permission",
          children: [
            TextSpan(
                text: " ACCESS_FINE_LOCATION ",
                style: Theme.of(context)
                    .textTheme
                    .bodyText1
                    .copyWith(fontStyle: FontStyle.italic, color: Colors.blue)),
            TextSpan(
              text:
                  "to access bluetooth operations.\n\nFor more details, please visit ",
            ),
            TextSpan(
              text: "Google's document",
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  const url =
                      'https://developer.android.google.cn/guide/topics/connectivity/bluetooth.html#Permissions';
                  if (await canLaunch(url))
                    await launch(url);
                  else
                    throw 'cound not launch $url';
                },
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                  decoration: TextDecoration.underline),
            ),
          ],
        ),
        style: Theme.of(context).textTheme.bodyText1,
      ),
      () => false,
      'acquire',
      () => PermissionHandler().requestPermissions(
          [PermissionGroup.locationWhenInUse]).then((permissions) {
        print(permissions[PermissionGroup.locationWhenInUse]);
        if (permissions[PermissionGroup.locationWhenInUse] ==
            PermissionStatus.granted) {
          Navigator.pop(context);
        }
      }),
    );
  }

  Widget _buildOpenLocationCard(BuildContext context) {
    return _buildCard(
      Icon(Icons.location_on),
      Text("open location"),
      Text.rich(
        TextSpan(
          text:
              "Android require location opened when access bluetooth operations.\n\nFor more details, please visit ",
          children: [
            TextSpan(
              text: "Google's document",
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  const url =
                      'https://developer.android.google.cn/guide/topics/connectivity/bluetooth.html#Permissions';
                  if (await canLaunch(url))
                    await launch(url);
                  else
                    throw 'cound not launch $url';
                },
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                  decoration: TextDecoration.underline),
            ),
          ],
        ),
        style: Theme.of(context).textTheme.bodyText1,
      ),
      () => false,
      'setting',
      () {},
    );
  }
}

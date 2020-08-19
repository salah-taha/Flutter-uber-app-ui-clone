import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutteruberapp/pages/index.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with WidgetsBindingObserver {
  PermissionHandler _permissionHandler = PermissionHandler();

  var isChecking = true;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _check();
    super.initState();
  }

  _check() async {
    final status = await _permissionHandler
        .checkPermissionStatus(PermissionGroup.locationWhenInUse);
    if (status == PermissionStatus.granted) {
      _getInitialPosition();
    } else {
      setState(() {
        isChecking = false;
      });
    }
  }

  _request() async {
    final result = await _permissionHandler
        .requestPermissions([PermissionGroup.locationWhenInUse]);
    if (result.containsKey(PermissionGroup.locationWhenInUse)) {
      final status = result[PermissionGroup.locationWhenInUse];
      if (status == PermissionStatus.granted) {
        _getInitialPosition();
      } else if (status == PermissionStatus.denied) {
        final result = await _permissionHandler.openAppSettings();
        print('result $result');
      }
    }
  }

  _getInitialPosition() async {
    final geolocator = Geolocator();
    final position = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    CameraPosition _userPos = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 14.4746,
    );
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => HomePage(initialPos: _userPos)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _check();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isChecking
          ? SafeArea(
              child: Center(
                child: CupertinoActivityIndicator(
                  radius: 15,
                  animating: true,
                ),
              ),
            )
          : SafeArea(
              child: Container(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Missing Permission',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 10),
                    CupertinoButton(
                      child: Text(
                        'ALLOW',
                      ),
                      color: Colors.blue,
                      onPressed: _request,
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'home/map_utils.dart';

class HomePage extends StatefulWidget {
  final initialPos;

  HomePage({this.initialPos});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController _mapController;
  Uint8List _carPin;
  Marker _myMarker;

  StreamSubscription<Position> _positionStream;
  Map<MarkerId, Marker> _markers = Map();
  Map<PolylineId, Polyline> _polylines = Map();
  List<LatLng> _myRoute = List();

  Position _lastPosition;

  @override
  void initState() {
    _loadCarPin();
    super.initState();
  }

  @override
  void dispose() {
    if (_positionStream != null) {
      _positionStream.cancel();
      _positionStream = null;
    }
    super.dispose();
  }

  _loadCarPin() async {
    _carPin =
        await MapUtils.loadPinFromAssets('assets/icons/car-pin.png', width: 60);
    _startTracking();
  }

  _startTracking() async {
    final geolocator = Geolocator();
    final locationOptions =
        LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 5);

    _positionStream =
        geolocator.getPositionStream(locationOptions).listen(_onLocationUpdate);
  }

  _onLocationUpdate(Position position) {
    if (position != null) {
      final myPosition = LatLng(position.latitude, position.longitude);
      _myRoute.add(myPosition);
      final myPolyline = Polyline(
        polylineId: PolylineId('me'),
        points: _myRoute,
        color: Colors.amber,
        width: 8,
      );

      if (_myMarker == null) {
        final markerId = MarkerId('me');
        final bitmap = BitmapDescriptor.fromBytes(_carPin);
        _myMarker = Marker(
          markerId: markerId,
          position: myPosition,
          rotation: 0,
          icon: bitmap,
          anchor: Offset(0.5, 0.5),
        );
      } else {
        final rotation = _getMyBearing(_lastPosition, position);
        _myMarker = _myMarker.copyWith(
            positionParam: myPosition, rotationParam: rotation);
      }
      setState(() {
        _markers[_myMarker.markerId] = _myMarker;
        _polylines[myPolyline.polylineId] = myPolyline;
      });
      _lastPosition = position;
      _move(position);
    }
  }

  double _getMyBearing(Position lastPosition, Position currentPosition) {
    final dx = math.cos(math.pi / 180 * lastPosition.latitude) *
        (currentPosition.longitude - lastPosition.longitude);
    final dy = currentPosition.latitude - lastPosition.latitude;
    final angle = math.atan2(dy, dx);
    return 90 - angle * 180 / math.pi;
  }

  _updateMarkerPosition(MarkerId id, LatLng np) {
    setState(() {
      _markers[id] = _markers[id].copyWith(positionParam: np);
    });
  }

  _onTap(LatLng p) {
    final id = '${_markers.length}';
    final markerId = MarkerId(id);
    final infoWindow = InfoWindow(
        title: 'Marker $id',
        snippet: '${p.longitude},${p.latitude}',
        anchor: Offset(0.5, 0),
        onTap: () {
          print(p.longitude);
        });
    final marker = new Marker(
        markerId: markerId,
        position: p,
        infoWindow: infoWindow,
        draggable: true,
        onDragEnd: (np) => _updateMarkerPosition(markerId, np));

    setState(() {
      _markers[markerId] = marker;
    });
  }

  _move(Position position) {
    final cameraUpdate =
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude));
    _mapController.animateCamera(cameraUpdate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: widget.initialPos,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController.setMapStyle(jsonEncode(mapStyle));
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: true,
              markers: Set.of(_markers.values),
              polylines: Set.of(_polylines.values),
            ),
            Positioned(
              right: MediaQuery.of(context).size.width / 2 - 95,
              bottom: 20,
              child: CupertinoButton(
                child: Text('Click Me'),
                onPressed: () {
                  _myRoute.clear();
                },
                color: Colors.blue,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

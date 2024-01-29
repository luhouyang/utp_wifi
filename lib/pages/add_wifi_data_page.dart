import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class AddWifiDataPage extends StatefulWidget {
  const AddWifiDataPage({super.key});

  @override
  State<AddWifiDataPage> createState() => _AddWifiDataPageState();
}

class _AddWifiDataPageState extends State<AddWifiDataPage> {
  Location _locationController = Location();

  static const CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(37.42796133580664, -122.085749655962), zoom: 13);
  LatLng? _livePostion;

  @override
  void initState() {
    super.initState();
    getLiveLocation();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: _livePostion == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _livePostion!, zoom: 15),
              markers: {
                Marker(
                    markerId: MarkerId("user"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _livePostion!),
                Marker(
                    markerId: MarkerId("start"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: LatLng(37.42796133580664, -122.085749655962)),
                Marker(
                    markerId: MarkerId("dest"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: LatLng(37.40296000000000, -122.08832357078792))
              },
            ),
    ));
  }

  Future<void> getLiveLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _livePostion =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        debugPrint(_livePostion.toString());
      }
    });
  }
}

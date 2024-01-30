import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class AddWifiDataPage extends StatefulWidget {
  const AddWifiDataPage({super.key});

  @override
  State<AddWifiDataPage> createState() => _AddWifiDataPageState();
}

class _AddWifiDataPageState extends State<AddWifiDataPage> {
  Location _locationController = Location();
  FlutterInternetSpeedTest speedTest = FlutterInternetSpeedTest();

  static const CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(37.42796133580664, -122.085749655962), zoom: 13);
  LatLng? _livePostion;

  @override
  void initState() {
    super.initState();
    getLiveLocation();
  }

  @override
  void dispose() {
    // TODO: save data
    super.dispose();
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
              },
            ),
    ));
  }

  Future getInternetSpeed() async {
    speedTest.startTesting(
        onStarted: () {
          // TODO
        },
        onCompleted: (TestResult download, TestResult upload) {
          // TODO
        },
        onProgress: (double percent, TestResult data) {
          // TODO
        },
        onError: (String errorMessage, String speedTestError) {
          // TODO
        },
        onDefaultServerSelectionInProgress: () {
          // TODO
          //Only when you use useFastApi parameter as true(default)
        },
        onDefaultServerSelectionDone: (Client? client) {
          // TODO
          //Only when you use useFastApi parameter as true(default)
        },
        onDownloadComplete: (TestResult data) {
          // TODO
        },
        onUploadComplete: (TestResult data) {
          // TODO
        },
        onCancel: () {
        // TODO Request cancelled callback
        });
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
        if (!mounted) return;
        setState(() {
          _livePostion =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        debugPrint(_livePostion.toString());
      }
    });
  }
}

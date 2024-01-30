import 'dart:async';
import 'dart:js_util';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';

class AddWifiDataPage extends StatefulWidget {
  const AddWifiDataPage({super.key});

  @override
  State<AddWifiDataPage> createState() => _AddWifiDataPageState();
}

class _AddWifiDataPageState extends State<AddWifiDataPage> {
  Timer? timer;

  Location _locationController = Location();
  LatLng? _livePostion;

  FlutterInternetSpeedTest speedTest = FlutterInternetSpeedTest();
  double _downloadRate = 0;
  double _uploadRate = 0;
  String _downloadUnitText = 'Mbps';
  String _uploadUnitText = 'Mbps';

  WifiHeatmapEntity wifiHeatmapEntity = WifiHeatmapEntity(wifiHeatmap: []);

  void _intervalTimer() {
    timer = Timer(const Duration(seconds: 20), () {
      getLiveLocation();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reset();
    });
    _intervalTimer();
  }

  @override
  void dispose() {
    debugPrint(wifiHeatmapEntity.toString());
    timer!.cancel();
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
    speedTest.startTesting(onStarted: () {
      debugPrint("Starting speed test");
    }, onCompleted: (TestResult download, TestResult upload) {
      setState(() {
        _downloadRate = download.transferRate;
        _downloadUnitText = download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
        debugPrint("Download: $_downloadRate | $_downloadUnitText");
      });
      setState(() {
        _uploadRate = upload.transferRate;
        _uploadUnitText = upload.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
        debugPrint("Upload: $_uploadRate | $_uploadUnitText");
      });
    }, onProgress: (double percent, TestResult data) {
      debugPrint(
          "Load : ${"#" * (percent / 10).floor()}${"-" * (100 - percent / 10).floor()}");
    }, onError: (String errorMessage, String speedTestError) {
      debugPrint("Error: $errorMessage");
    }, onDefaultServerSelectionInProgress: () {
      // TODO
      //Only when you use useFastApi parameter as true(default)
    }, onDefaultServerSelectionDone: (Client? client) {
      // TODO
      //Only when you use useFastApi parameter as true(default)
    });
  }

  Future<void> getLiveLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        getInternetSpeed().then((value) {
          if (!mounted) return;
          setState(() {
            _livePostion =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            int indexSame = wifiHeatmapEntity.wifiHeatmap.indexOf(
                [currentLocation.latitude, currentLocation.longitude, int]);
            if (indexSame == -1) {
              wifiHeatmapEntity.wifiHeatmap.add([
                currentLocation.latitude,
                currentLocation.longitude,
                _downloadRate
              ]);
            } else {
              wifiHeatmapEntity.wifiHeatmap[indexSame] =
                  min(wifiHeatmapEntity.wifiHeatmap[indexSame][2] as double, _downloadRate);
            }
          });
          debugPrint(_livePostion.toString());
        }); // get current internet speed
      }
    });
  }

  void reset() {
    setState(() {
      {
        _downloadRate = 0;
        _uploadRate = 0;
        _downloadUnitText = 'Mbps';
        _uploadUnitText = 'Mbps';
      }
    });
  }
}

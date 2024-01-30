import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';

class ShowWifiDataPage extends StatefulWidget {
  const ShowWifiDataPage({super.key});

  @override
  State<ShowWifiDataPage> createState() => _ShowWifiDataPageState();
}

class _ShowWifiDataPageState extends State<ShowWifiDataPage> {
  final Location _locationController = Location();
  LatLng? _livePostion;

  WifiHeatmapEntity wifiHeatmapEntity = WifiHeatmapEntity(wifiHeatmap: []);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    debugPrint("$wifiHeatmapEntity show page");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      body: Center(
                    child: Text("testing"))/*_livePostion == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _livePostion!, zoom: 15),
              markers: {
                Marker(
                    markerId: const MarkerId("user"),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _livePostion!),
              },
            ),*/
    ));
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
          if (!mounted) return;
          setState(() {
            _livePostion = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          });
          debugPrint(_livePostion.toString());
      }
    });
  }
}

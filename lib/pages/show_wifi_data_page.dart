import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';
import 'package:utp_wifi/services/storage_services.dart';

class ShowWifiDataPage extends StatefulWidget {
  const ShowWifiDataPage({super.key});

  @override
  State<ShowWifiDataPage> createState() => _ShowWifiDataPageState();
}

class _ShowWifiDataPageState extends State<ShowWifiDataPage> {
  // geo location
  final Location _locationController = Location();
  LatLng? _livePostion;
  PermissionStatus? permissionGranted;
  bool? serviceEnabled;

  // update stream
  final StreamController<void> _rebuildStream = StreamController.broadcast();

  // heatmap
  List<WeightedLatLng> data = [];
  List<Map<double, MaterialColor>> gradients = [
    HeatMapOptions.defaultGradient,
    {
      0.25: Colors.purple,
      0.5: Colors.pink,
      0.75: Colors.blue,
      1.0: Colors.yellow,
    }
  ];
  WifiHeatmapEntity? wifiHeatmapEntity;

  // hybrid map
  FlutterMap? map;

  @override
  void initState() {
    _loadData(); // initialize data
    super.initState();
  }

  @override
  void dispose() {
    _rebuildStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _rebuildStream.add(null);
    });

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Container(
              child: map ??
                  const CircularProgressIndicator(
                    color: Colors.amber,
                  )),
        ),
      ),
    );
  }

  // initialize heatmap, geo location, hybrid map
  _loadData() async {
    // load today's heatmap data fropm firebase storage
    wifiHeatmapEntity = await StorageServices().fetchData();

    // decode string to list "[[], [], []]" => [[], [], []]
    List<dynamic> result =
        jsonDecode(wifiHeatmapEntity!.wifiHeatmap.toString());

    // add latitude, longitude, weight to heatmap data
    result.asMap().forEach((index, heightLocation) {
      data.add(WeightedLatLng(
          LatLng(heightLocation[0], heightLocation[1]), heightLocation[2]));
    });

    // get geo location
    await getLiveLocation();
    if (!mounted) return;
    setState(() {
      // create hybrid map
      map = FlutterMap(
        options: MapOptions(
          initialCenter: _livePostion!,
          initialZoom: 18.0,
        ),
        children: [
          TileLayer(
              retinaMode: true,
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c']),
          if (data.isNotEmpty)
            HeatMapLayer(
              maxZoom: 30.0,
              heatMapDataSource: InMemoryHeatMapDataSource(data: data),
              heatMapOptions:
                  HeatMapOptions(gradient: gradients[1], minOpacity: 0, blurFactor: 0, radius: 10),
              reset: _rebuildStream.stream,
            )
        ],
      );
    });
  }

  // get geo location
  Future getLiveLocation() async {
    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled!) {
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

    LocationData currentLocation = await _locationController.getLocation();
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      if (!mounted) return;
      setState(() {
        _livePostion =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });
    }
  }
}

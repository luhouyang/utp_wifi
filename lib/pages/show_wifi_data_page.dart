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
  final Location _locationController = Location();
  LatLng? _livePostion;

  StreamController<void> _rebuildStream = StreamController.broadcast();

  List<WeightedLatLng> data = [];
  List<Map<double, MaterialColor>> gradients = [
    HeatMapOptions.defaultGradient,
    {5.0: Colors.yellow, 3.0: Colors.blue, 1.0: Colors.pink, 0.25: Colors.purple}
  ];
  WifiHeatmapEntity? wifiHeatmapEntity;
  FlutterMap? map;

  _loadData() async {
    wifiHeatmapEntity = await StorageServices().fetchData();
    List<dynamic> result =
        jsonDecode(wifiHeatmapEntity!.wifiHeatmap.toString());
    debugPrint(result.toString());

    setState(() {
      result.asMap().forEach((index, heightLocation) {
        data.add(WeightedLatLng(
            LatLng(heightLocation[0], heightLocation[1]), heightLocation[2]));
      });
    });
    debugPrint(data.toString());

    await getLiveLocation();
    setState(() {
      map = FlutterMap(
        options: MapOptions(
          initialCenter: _livePostion!,
          initialZoom: 4.0,
        ),
        children: [
          TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c']),
          if (data.isNotEmpty)
            HeatMapLayer(
              heatMapDataSource: InMemoryHeatMapDataSource(data: data),
              heatMapOptions:
                  HeatMapOptions(gradient: gradients[0], minOpacity: 0),
              reset: _rebuildStream.stream,
            )
        ],
      );
    });
  }

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  @override
  void dispose() {
    debugPrint("$wifiHeatmapEntity show page");
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
          child: Container(child: map ?? const CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future getLiveLocation() async {
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

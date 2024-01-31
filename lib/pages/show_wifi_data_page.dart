import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';

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
    {0.25: Colors.blue, 0.55: Colors.red, 0.85: Colors.pink, 1.0: Colors.purple}
  ];
  WifiHeatmapEntity wifiHeatmapEntity = WifiHeatmapEntity(wifiHeatmap: []);

  _loadData() async {
    var str = await rootBundle.loadString('assets/initial_data.json');
    List<dynamic> result = jsonDecode(str);

    setState(() {
      data = result
          .map((e) => e as List<dynamic>)
          .map((e) => WeightedLatLng(LatLng(e[0], e[1]), 1))
          .toList();
    });
    debugPrint(data.toString());
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

    final map = FlutterMap(
      options: MapOptions(
        center: LatLng(57.8827, -6.0400),
        zoom: 8.0,
      ),
      children: [
        TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c']),
        if (data.isNotEmpty)
          HeatMapLayer(
            heatMapDataSource: InMemoryHeatMapDataSource(data: data),
            heatMapOptions:
                HeatMapOptions(gradient: gradients[0], minOpacity: 0.1),
            reset: _rebuildStream.stream,
          )
      ],
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.pink,
        body: Center(
          child: Container(child: map),
        ),
      ),
    );
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
          _livePostion =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
        debugPrint(_livePostion.toString());
      }
    });
  }
}

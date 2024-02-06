import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
  LatLng? livePostion;
  PermissionStatus? permissionGranted;
  bool? serviceEnabled;

  // update stream
  final StreamController<void> _rebuildStream = StreamController.broadcast();

  // heatmap
  List<WeightedLatLng> data = [];
  List<Map<double, MaterialColor>> gradients = [
    HeatMapOptions.defaultGradient,
    {
      0.25: Colors.red,
      0.55: Colors.yellow,
      0.85: Colors.green,
      1.0: Colors.blue
    }
  ];
  WifiHeatmapEntity? wifiHeatmapEntity;

  // hybrid map
  FlutterMap? map;

  // heatmap gradient scale
  double min = 100;
  double max = 0;

  // date filter
  DateTime dateSelection = DateTime.now();

  // floor filter

  @override
  void initState() {
    _hybridMap(); // initialize data
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
        body: Stack(
          children: [
            Center(
              child: Container(
                  child: map ??
                      LoadingAnimationWidget.beat(
                        size: 60,
                        color: Colors.amber,
                      )),
            ),
            if (map != null && data.isEmpty)
              Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                  size: 60,
                  color: Colors.amber,
                ),
              ),
            Positioned(
              top: 0,
              right: 10,
              child: Row(
                children: [
                  InkWell(
                    onTap: () async {
                      final DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024, 2, 2),
                        lastDate: DateTime(10000, 1, 1),
                      );
                      if (date != null) {
                        setState(() {
                          dateSelection = date;
                        });
                      }
                      await _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0)),
                        color: Colors.amber,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            dateSelection.toString().split(" ")[0],
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          const Icon(
                            Icons.date_range,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  InkWell(
                    onHover: (value) {},
                    onTap: () async {
                      setState(() {
                        dateSelection = DateTime(1, 1, 1);
                      });
                      await _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0)),
                        color: Colors.amber,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            "Average",
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Icon(
                            Icons.stacked_bar_chart,
                            color: Colors.black,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
                left: 10,
                top: 50,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.2,
                  width: 30,
                  child: Column(
                    children: [
                      Text(
                        max.toString(),
                        style: const TextStyle(fontSize: 7.0),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(7.5, 2.5, 7.5, 2.5),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.15,
                          decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                Colors.blue,
                                Colors.green,
                                Colors.yellow,
                                Colors.red
                              ])),
                        ),
                      ),
                      Text(
                        min.toString(),
                        style: const TextStyle(fontSize: 7.0),
                      ),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }

  // load heatmap
  Future<void> _loadData() async {
    data.clear();

    // load today's heatmap data fropm firebase storage
    wifiHeatmapEntity = await StorageServices().fetchData(dateSelection);

    // decode string to list "[[], [], []]" => [[], [], []]
    List<dynamic> result =
        jsonDecode(wifiHeatmapEntity!.wifiHeatmap.toString());

    // add latitude, longitude, weight to heatmap data
    result.asMap().forEach((index, heightLocation) {
      if (heightLocation[2] < min) {
        min = heightLocation[2];
      }
      if (heightLocation[2] > max) {
        max = heightLocation[2];
      }
      data.add(WeightedLatLng(
          LatLng(heightLocation[0], heightLocation[1]), heightLocation[2]));
    });

    if (!mounted) return;
    setState(() {});
  }

  // initialize heatmap, geo location, hybrid map
  _hybridMap() async {
    await _loadData();

    // get geo location
    await getLiveLocation();
    if (!mounted) return;
    setState(() {
      // create hybrid map
      map = FlutterMap(
        options: MapOptions(
          initialCenter: livePostion!,
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
              heatMapOptions: HeatMapOptions(
                  gradient: gradients[1],
                  minOpacity: 0.3,
                  blurFactor: 0.8,
                  radius: 3),
              reset: _rebuildStream.stream,
            )
        ],
      );
    });
    debugPrint("$min, $max");
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
        livePostion =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
      });
    }
  }
}

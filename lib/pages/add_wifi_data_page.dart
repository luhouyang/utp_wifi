import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_internet_speed_test/flutter_internet_speed_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:location/location.dart';
import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';
import 'package:utp_wifi/services/storage_services.dart';

class AddWifiDataPage extends StatefulWidget {
  const AddWifiDataPage({super.key});

  @override
  State<AddWifiDataPage> createState() => _AddWifiDataPageState();
}

class _AddWifiDataPageState extends State<AddWifiDataPage> {
  // timer to start speed test periodically
  late Timer timer;

  // geo location
  final Location _locationController = Location();
  LatLng? livePostion;
  PermissionStatus? permissionGranted;
  bool? serviceEnabled;

  // internet speed test
  FlutterInternetSpeedTest speedTest = FlutterInternetSpeedTest();
  String _speed = "waiting . . .";
  String _type = "waiting . . .";
  String _loadingText = "waiting . . .";

  double _downloadRate = 0;
  double _uploadRate = 0;
  String _downloadUnitText = 'Mbps';
  String _uploadUnitText = 'Mbps';

  // heatmap
  WifiHeatmapEntity wifiHeatmapEntity = WifiHeatmapEntity(
    wifiHeatmap: [],
    dateTime:
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
  );

  // fireabse storage
  StorageServices storageServices = StorageServices();

  // hybrid map
  FlutterMap? map;

  // uploading data
  bool _uploading = false;

  // speed test periodic timer
  void _intervalTimer() {
    timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (tmr) {
        getInternetSpeed();
      },
    );
  }

  @override
  void initState() {
    _intervalTimer();
    super.initState();
  }

  @override
  void dispose() {
    //storageServices.postToStorage(wifiHeatmapEntity);
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    ),
              ),
            ),
            if (_uploading)
              Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                  size: 60,
                  color: Colors.amber,
                ),
              ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_speed),
                        Text(_type),
                        Text(_loadingText),
                        Text(
                            "Num Data: ${wifiHeatmapEntity.wifiHeatmap.length}"),
                        const SizedBox(
                          height: 25,
                        ),
                        Text(
                          wifiHeatmapEntity.wifiHeatmap
                              .toString()
                              .lastChars(150),
                        ),
                      ],
                    ),
                    const Expanded(
                      child: SizedBox(),
                    ),
                    InkWell(
                        onHover: (value) {},
                        onTap: () async {
                          postData();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.amber),
                          margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Post Data"),
                              Icon(Icons.upload_file_rounded),
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // post data
  Future<void> postData() async {
    setState(() {
      _uploading = true;
    });

    await storageServices.postToStorage(wifiHeatmapEntity).then((value) {
      wifiHeatmapEntity.wifiHeatmap = [];
    }).onError((error, stackTrace) {
      debugPrint("Error: $error");
    });

    setState(() {
      _uploading = false;
    });
  }

  // internet speed
  Future getInternetSpeed() async {
    speedTest.startTesting(
        useFastApi: false,
        downloadTestServer: "http://speedtest.ftp.otenet.gr/files/test1Mb.db",
        uploadTestServer: "http://speedtest.ftp.otenet.gr/files/test1Mb.db",
        onStarted: () {
          if (!mounted) return;
          debugPrint("Starting speed test");
        },
        onCompleted: (TestResult download, TestResult upload) {
          if (!mounted) return;
          setState(() {
            resetOnComplete();
            _downloadRate = download.transferRate;
            _downloadUnitText =
                download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
            debugPrint("Download: $_downloadRate | $_downloadUnitText");

            _uploadRate = upload.transferRate;
            _uploadUnitText = upload.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
            debugPrint("Upload: $_uploadRate | $_uploadUnitText");
          });
        },
        onProgress: (double percent, TestResult data) {
          if (!mounted) return;

          // only get location data when return download speed
          if (data.type.toString() == "TestType.download" &&
              data.transferRate != 0) {
            getLiveLocationAndStoreData(data);
          }

          // update stats shown on screen
          setState(() {
            _speed =
                "Speed : ${data.transferRate} ${data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps'}";
            _loadingText =
                "Load : ${"#" * (percent / 10).floor()}${"-" * ((100 - percent) / 10).ceil()}";
            _type = data.type.toString().replaceAll(".", " : ");

            debugPrint("$_loadingText\t\t\t$_speed");
          });
        },
        onError: (String errorMessage, String speedTestError) {
          if (!mounted) return;
          debugPrint("Error: $errorMessage");
        });
  }

  // get location and store data
  Future<void> getLiveLocationAndStoreData(TestResult data) async {
    bool sameLocation = false;

    // request location service
    serviceEnabled ??= await _locationController.serviceEnabled().then((value) {
      return value;
    });
    if (serviceEnabled!) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    // request location permission
    permissionGranted ??= await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      debugPrint("requested permission");
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // get location
    LocationData currentLocation = await _locationController.getLocation();
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      if (!mounted) return;
      setState(() {
        livePostion =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);

        // create map (only run once for each refresh)
        if (livePostion != null && map == null) {
          _loadData();
        }

        // check if same coordinates
        wifiHeatmapEntity.wifiHeatmap.asMap().forEach((index, locationHeight) {
          if (locationHeight[0] == currentLocation.latitude &&
              locationHeight[1] == currentLocation.longitude) {
            int repetitions = wifiHeatmapEntity.wifiHeatmap[index][3];
            wifiHeatmapEntity.wifiHeatmap[index][2] =
                (((wifiHeatmapEntity.wifiHeatmap[index][2] * repetitions +
                            data.transferRate) /
                        (repetitions + 1)) as double)
                    .toPrecision(6);
            wifiHeatmapEntity.wifiHeatmap[index][3] = repetitions + 1;
            sameLocation = true;
            return;
          }
        });

        // if new coordinate
        if (!sameLocation) {
          wifiHeatmapEntity.wifiHeatmap.add([
            currentLocation.latitude,
            currentLocation.longitude,
            data.transferRate,
            1
          ]);
        }
      });

      debugPrint(wifiHeatmapEntity.wifiHeatmap.last.toString());
    }
  }

  _loadData() async {
    // get geo location
    if (!mounted) return;
    setState(() {
      // create hybrid map
      map = FlutterMap(
        options: MapOptions(
          initialCenter: livePostion!,
          initialZoom: 18.0,
        ),
        children: [
          // OSM map
          TileLayer(
              retinaMode: true,
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c']),
          // live location, orientation tracker
          currerntLocationandOrientation()
        ],
      );
    });
  }

  // reset on complete stats
  void resetOnComplete() {
    if (!mounted) return;
    setState(() {
      {
        _downloadRate = 0;
        _uploadRate = 0;
        _downloadUnitText = 'Mbps';
        _uploadUnitText = 'Mbps';
      }
    });
  }

  Widget currerntLocationandOrientation() {
    return CurrentLocationLayer(
      followOnLocationUpdate: FollowOnLocationUpdate.always,
      turnOnHeadingUpdate: TurnOnHeadingUpdate.never,
      style: LocationMarkerStyle(
        marker: const DefaultLocationMarker(
          child: Icon(
            Icons.navigation,
            color: Colors.white,
          ),
        ),
        markerSize: const Size(40, 40),
        markerDirection: MarkerDirection.heading,
      ),
    );
  }
}

extension Precision on double {
  double toPrecision(int fractionDigits) {
    num mod = pow(10, fractionDigits.toDouble());
    return ((this * mod).round().toDouble() / mod);
  }
}

extension E on String {
  String lastChars(int n) =>
      (n >= length) ? substring(1) : substring(length - n);
}

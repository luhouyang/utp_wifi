import 'dart:async';
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

  final Location _locationController = Location();
  LatLng? _livePostion;

  FlutterInternetSpeedTest speedTest = FlutterInternetSpeedTest();
  String _speed = "";
  String _type = "";
  String _loadingText = "";

  double _downloadRate = 0;
  double _uploadRate = 0;
  String _downloadUnitText = 'Mbps';
  String _uploadUnitText = 'Mbps';

  WifiHeatmapEntity wifiHeatmapEntity = WifiHeatmapEntity(wifiHeatmap: []);

  void _intervalTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 15),
      (tmr) {
        getInternetSpeed();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      reset();
    });
    getInternetSpeed();
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
                : Center(
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 25,
                        ),
                        Text(_speed),
                        Text(_type),
                        Text(_loadingText),
                        const SizedBox(
                          height: 50,
                        ),
                        Text(wifiHeatmapEntity.wifiHeatmap.toString()),
                      ],
                    ),
                  ) /*GoogleMap(
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

  Future getInternetSpeed() async {
    await speedTest.startTesting(
        useFastApi: false,
        downloadTestServer: "http://speedtest.ftp.otenet.gr/files/test1Mb.db",
        uploadTestServer: "http://speedtest.ftp.otenet.gr/files/test1Mb.db",
        onStarted: () {
          debugPrint("Starting speed test");
        },
        onCompleted: (TestResult download, TestResult upload) {
          setState(() {
            _downloadRate = download.transferRate;
            _downloadUnitText =
                download.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
            debugPrint("Download: $_downloadRate | $_downloadUnitText");
          });
          setState(() {
            _uploadRate = upload.transferRate;
            _uploadUnitText = upload.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps';
            debugPrint("Upload: $_uploadRate | $_uploadUnitText");
          });
        },
        onProgress: (double percent, TestResult data) {
          getLiveLocation(data);
          _speed =
              "Speed : ${data.transferRate} ${data.unit == SpeedUnit.kbps ? 'Kbps' : 'Mbps'}";
          _loadingText =
              "Load : ${"#" * (percent / 10).floor()}${"-" * ((100 - percent) / 10).ceil()}";
          _type = data.type.toString().replaceAll(".", " : ");
          debugPrint("$_loadingText\t\t\t$_speed");
        },
        onError: (String errorMessage, String speedTestError) {
          debugPrint("Error: $errorMessage");
        },
        onDefaultServerSelectionInProgress: () {
          // TODO
          //Only when you use useFastApi parameter as true(default)
        },
        onDefaultServerSelectionDone: (Client? client) {
          // TODO
          //Only when you use useFastApi parameter as true(default)
        });
  }

  Future<void> getLiveLocation(TestResult data) async {
    bool sameLocation = false;

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

        wifiHeatmapEntity.wifiHeatmap.asMap().forEach((index, locationHeight) {
          // check if same coordinates
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

      debugPrint(_livePostion.toString());
    }
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

extension Precision on double {
  double toPrecision(int fractionDigits) {
    num mod = pow(10, fractionDigits.toDouble());
    return ((this * mod).round().toDouble() / mod);
  }
}

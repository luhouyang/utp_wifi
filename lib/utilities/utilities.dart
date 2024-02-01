import 'dart:math';

import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';

class Utilities {
  String parseDateToString(DateTime dateTime) {
    return "${dateTime.day}_${dateTime.month}_${dateTime.year}";
  }

  WifiHeatmapEntity mergedHeatmap(
      WifiHeatmapEntity newWHE, WifiHeatmapEntity oldWHE) {
    bool sameLocation = false;

    newWHE.wifiHeatmap.asMap().forEach((newIndex, newLocationHeight) {
      oldWHE.wifiHeatmap.asMap().forEach((oldIndex, oldLocationHeight) {
        // check if same coordinates
        if (newLocationHeight[0] == oldLocationHeight[0] &&
            newLocationHeight[1] == oldLocationHeight[1]) {
          int repetitions = newLocationHeight[3] + oldLocationHeight[3];
          oldWHE.wifiHeatmap[oldIndex][2] =
              (((newLocationHeight[2] * newLocationHeight[3]) +
                          (oldLocationHeight[2] * oldLocationHeight[3])) /
                      repetitions)
                  .toPrecision(6);
          sameLocation = true;
          return;
        }
      });

      // if new coordinate
      if (!sameLocation) {
        oldWHE.wifiHeatmap.add([newLocationHeight]);
      }
    });

    return oldWHE;
  }
}

extension Precision on double {
  double toPrecision(int fractionDigits) {
    num mod = pow(10, fractionDigits.toDouble());
    return ((this * mod).round().toDouble() / mod);
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';
import 'package:utp_wifi/utilities/utilities.dart';

class StorageServices {
  Reference storageRef = FirebaseStorage.instance.ref();

  Future<void> postToStorage(WifiHeatmapEntity newWHE) async {
    final folderName = Utilities().parseDateToString(newWHE.dateTime);
    final folderRef = storageRef.child(folderName);
    final appDocDir = await getApplicationDocumentsDirectory();
    final filePath = "${appDocDir.absolute}/$folderName.json";
    final file = File(filePath);

    var result = folderRef.getDownloadURL().then((value) async {
      WifiHeatmapEntity? oldWHE =
          await tryFetchData(folderRef, file, newWHE.dateTime);
      debugPrint(oldWHE!.wifiHeatmap.toString());
    }).catchError((onError) async {
      await folderRef.putString(newWHE.wifiHeatmap.toString());
    });
  }

  Future<WifiHeatmapEntity?> tryFetchData(
      Reference folderRef, File file, DateTime dateTime) async {
    try {
      WifiHeatmapEntity? retrievedWHE;
      final downloadTask = await folderRef.writeToFile(file);
      switch (downloadTask.state) {
        case TaskState.running:
          // TODO: Handle this case.
          break;
        case TaskState.paused:
          // TODO: Handle this case.
          break;
        case TaskState.success:
          debugPrint(await file.readAsString());
          retrievedWHE = WifiHeatmapEntity(
              wifiHeatmap: jsonDecode(await file.readAsString()),
              dateTime: dateTime);
          break;
        case TaskState.canceled:
          // TODO: Handle this case.
          break;
        case TaskState.error:
          // TODO: Handle this case.
          break;
      }
      return retrievedWHE;
    } catch (e) {
      debugPrint("Error: $e");
    }
    return null;
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';
import 'package:utp_wifi/utilities/utilities.dart';
import 'package:path/path.dart' as p;

class StorageServices {
  Reference storageRef = FirebaseStorage.instance.ref();

  // used to view data
  Future<WifiHeatmapEntity> fetchData(DateTime dateTime) async {
    final String folderName = Utilities().parseDateToString(dateTime);
    final folderRef = storageRef.child(folderName);

    String? downloadDirectory;
    if (Platform.isAndroid) {
      final externalStorageFolder = await getExternalStorageDirectory();
      if (externalStorageFolder != null) {
        downloadDirectory = p.join(externalStorageFolder.path, "Downloads");
      }
    } else {
      final downloadFolder = await getDownloadsDirectory();
      if (downloadFolder != null) {
        downloadDirectory = downloadFolder.path;
      }
    }

    File(downloadDirectory! + '/$folderName')
      ..createSync(recursive: true)
      ..writeAsStringSync("placeholder");

    final file = File(downloadDirectory + '/$folderName');

    WifiHeatmapEntity retrievedWHE =
        WifiHeatmapEntity(wifiHeatmap: [], dateTime: dateTime);
    try {
      final downloadTask = await folderRef.writeToFile(file);
      switch (downloadTask.state) {
        case TaskState.running:
          debugPrint("Firebase State: ${downloadTask.state}");
          break;
        case TaskState.paused:
          debugPrint("Firebase State: ${downloadTask.state}");
          break;
        case TaskState.success:
          retrievedWHE = WifiHeatmapEntity(
              wifiHeatmap: jsonDecode(await file.readAsString()),
              dateTime: dateTime);
          break;
        case TaskState.canceled:
          debugPrint("Firebase State: ${downloadTask.state}");
          break;
        case TaskState.error:
          debugPrint("Firebase State: ${downloadTask.state}");
          break;
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    return retrievedWHE;
  }

  // used to add data
  Future<void> postToStorage(WifiHeatmapEntity newWHE) async {
    final folderName = Utilities().parseDateToString(newWHE.dateTime);
    final folderRef = storageRef.child(folderName);
    final averageName = Utilities().parseDateToString(DateTime(1, 1, 1));
    final averageFolderRef = storageRef.child("1_1_1");

    // post individual date
    try {
      await folderRef.getDownloadURL().then((value) async {
        String? downloadDirectory;
        if (Platform.isAndroid) {
          final externalStorageFolder = await getExternalStorageDirectory();
          if (externalStorageFolder != null) {
            downloadDirectory = p.join(externalStorageFolder.path, "Downloads");
          }
        } else {
          final downloadFolder = await getDownloadsDirectory();
          if (downloadFolder != null) {
            downloadDirectory = downloadFolder.path;
          }
        }

        File(downloadDirectory! + '/$folderName')
          ..createSync(recursive: true)
          ..writeAsStringSync("placeholder");

        final file = File(downloadDirectory + '/$folderName');

        WifiHeatmapEntity? oldWHE =
            await tryFetchData(folderRef, file, newWHE.dateTime);

        WifiHeatmapEntity merged =
            await Utilities().mergedHeatmap(newWHE, oldWHE!);
        await folderRef.putString(merged.wifiHeatmap.toString());
      });
    } catch (e) {
      await folderRef.putString(newWHE.wifiHeatmap.toString());
    }

    // post average
    try {
      await averageFolderRef.getDownloadURL().then((value) async {
        String? downloadDirectory;
        if (Platform.isAndroid) {
          final externalStorageFolder = await getExternalStorageDirectory();
          if (externalStorageFolder != null) {
            downloadDirectory = p.join(externalStorageFolder.path, "Downloads");
          }
        } else {
          final downloadFolder = await getDownloadsDirectory();
          if (downloadFolder != null) {
            downloadDirectory = downloadFolder.path;
          }
        }

        File(downloadDirectory! + '/$averageName')
          ..createSync(recursive: true)
          ..writeAsStringSync("placeholder");

        final file = File(downloadDirectory + '/$averageName');

        WifiHeatmapEntity? oldWHE =
            await tryFetchData(averageFolderRef, file, DateTime(1, 1, 1));

        WifiHeatmapEntity merged =
            await Utilities().mergedHeatmap(newWHE, oldWHE!);
        await averageFolderRef.putString(merged.wifiHeatmap.toString());
      });
    } catch (e) {
      await averageFolderRef.putString(newWHE.wifiHeatmap.toString());
    }
  }

  Future<WifiHeatmapEntity?> tryFetchData(
      Reference folderRef, File file, DateTime dateTime) async {
    try {
      WifiHeatmapEntity? retrievedWHE;
      final downloadTask = await folderRef.writeToFile(file);
      switch (downloadTask.state) {
        case TaskState.running:
          debugPrint("Firebase State: ${downloadTask.state}");
          break;
        case TaskState.paused:
          debugPrint("Firebase State: ${downloadTask.state}");
          break;
        case TaskState.success:
          retrievedWHE = WifiHeatmapEntity(
              wifiHeatmap: jsonDecode(await file.readAsString()),
              dateTime: dateTime);
          break;
        case TaskState.canceled:
          debugPrint("Firebase State: ${downloadTask.state}");
          break;
        case TaskState.error:
          debugPrint("Firebase State: ${downloadTask.state}");
          break;
      }
      return retrievedWHE;
    } catch (e) {
      debugPrint("Error: $e");
    }
    return null;
  }
}

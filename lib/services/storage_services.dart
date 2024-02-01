import 'package:firebase_storage/firebase_storage.dart';
import 'package:utp_wifi/entities/wifi_heatmap_entity.dart';

class StorageServices {
  Reference storageRef = FirebaseStorage.instance.ref();

  Future<void> postToStorage(WifiHeatmapEntity newWHE) async {
    WifiHeatmapEntity oldWHE = await tryFetchData(newWHE.dateTime);
  }

  Future<WifiHeatmapEntity> tryFetchData(DateTime dateTime) async {
    
  }
}

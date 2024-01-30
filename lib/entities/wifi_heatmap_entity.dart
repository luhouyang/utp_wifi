class WifiHeatmapEntity {
  List<dynamic> wifiHeatmap;
  //final DateTime dateTime;

  WifiHeatmapEntity({required this.wifiHeatmap});

  factory WifiHeatmapEntity.fromMap(Map<String, dynamic> map) {
    return WifiHeatmapEntity(
      wifiHeatmap: map['wifiHeatmap'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "wifiHeatmap": wifiHeatmap,
    };
  }
}

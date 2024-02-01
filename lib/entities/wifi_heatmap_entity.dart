class WifiHeatmapEntity {
  List<dynamic> wifiHeatmap;
  final DateTime dateTime;

  WifiHeatmapEntity({required this.wifiHeatmap, required this.dateTime});

  factory WifiHeatmapEntity.fromMap(Map<String, dynamic> map) {
    return WifiHeatmapEntity(
      wifiHeatmap: map['wifiHeatmap'],
      dateTime: map['dateTime'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "wifiHeatmap": wifiHeatmap,
      "dateTime": dateTime,
    };
  }
}

class Bin {
  final String id;
  final String location;
  final int fillLevel; // 0-100 arası
  final DateTime lastUpdate;

  Bin({
    required this.id,
    required this.location,
    required this.fillLevel,
    required this.lastUpdate,
  });
}

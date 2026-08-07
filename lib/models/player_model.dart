class PlayerModel {
  final String id;
  String name;
  bool isCaptain;
  bool isWicketKeeper;

  PlayerModel({
    required this.id,
    required this.name,
    this.isCaptain = false,
    this.isWicketKeeper = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCaptain': isCaptain,
      'isWicketKeeper': isWicketKeeper,
    };
  }

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Player',
      isCaptain: json['isCaptain'] ?? false,
      isWicketKeeper: json['isWicketKeeper'] ?? false,
    );
  }
}

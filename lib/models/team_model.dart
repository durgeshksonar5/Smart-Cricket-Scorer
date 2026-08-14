import 'player_model.dart';

class TeamModel {
  final String id;
  String name;
  List<PlayerModel> players;
  DateTime createdAt;
  DateTime updatedAt;

  TeamModel({
    required this.id,
    required this.name,
    required this.players,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'players': players.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    var rawPlayers = json['players'] as List<dynamic>? ?? [];
    List<PlayerModel> playerList = rawPlayers
        .map((p) => PlayerModel.fromJson(Map<String, dynamic>.from(p)))
        .toList();

    return TeamModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Team',
      players: playerList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  TeamModel copyWith({
    String? id,
    String? name,
    List<PlayerModel>? players,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      players: players ??
          this
              .players
              .map((p) => PlayerModel(
                    id: p.id,
                    name: p.name,
                    isCaptain: p.isCaptain,
                    isWicketKeeper: p.isWicketKeeper,
                  ))
              .toList(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Clones player list with new IDs or fresh instances for match isolation
  List<PlayerModel> clonePlayersForMatch(String prefix) {
    return List.generate(players.length, (i) {
      final p = players[i];
      return PlayerModel(
        id: '${prefix}_${i + 1}_${DateTime.now().millisecondsSinceEpoch % 10000}',
        name: p.name,
        isCaptain: p.isCaptain,
        isWicketKeeper: p.isWicketKeeper,
      );
    });
  }
}

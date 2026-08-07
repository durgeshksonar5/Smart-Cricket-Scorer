import 'ball_model.dart';

class OverModel {
  final int overNumber; // 1-indexed (Over 1, Over 2, ...)
  final List<BallModel> balls;
  String bowler;

  OverModel({
    required this.overNumber,
    List<BallModel>? balls,
    required this.bowler,
  }) : balls = balls ?? [];

  int get totalRuns => balls.fold(0, (sum, b) => sum + b.runs);
  int get wickets => balls.where((b) => b.isWicket).length;
  int get fours => balls.where((b) => b.runs == 4 || b.displayResult.contains('4')).length;
  int get sixes => balls.where((b) => b.runs == 6 || b.displayResult.contains('6')).length;
  int get extras => balls.where((b) => b.extraType != null).fold(0, (sum, b) => sum + (b.extraType == 'WD' || b.extraType == 'NB' ? 1 : 0));
  int get legalBallsCount => balls.where((b) => b.isLegal).length;
  bool get isComplete => legalBallsCount >= 6;

  Map<String, dynamic> toJson() {
    return {
      'overNumber': overNumber,
      'bowler': bowler,
      'balls': balls.map((b) => b.toJson()).toList(),
    };
  }

  factory OverModel.fromJson(Map<String, dynamic> json) {
    return OverModel(
      overNumber: json['overNumber'] ?? 1,
      bowler: json['bowler'] ?? 'Bowler',
      balls: (json['balls'] as List<dynamic>?)
              ?.map((b) => BallModel.fromJson(Map<String, dynamic>.from(b)))
              .toList() ??
          [],
    );
  }
}

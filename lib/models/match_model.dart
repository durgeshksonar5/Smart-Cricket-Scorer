import 'toss_details.dart';
import 'over_model.dart';

class MatchModel {
  final String id;
  final String teamA;
  final String teamB;
  final String matchName;
  final String venue;
  final DateTime dateTime;
  final int totalOvers;
  final int playersPerTeam;

  TossDetails? tossDetails;

  String battingTeam;
  String bowlingTeam;

  int currentInnings; // 1 or 2
  int inn1Runs;
  int inn1Wickets;
  int inn1Balls;
  List<String> inn1BallHistory;
  List<OverModel> inn1Overs;

  int inn2Runs;
  int inn2Wickets;
  int inn2Balls;
  List<String> inn2BallHistory;
  List<OverModel> inn2Overs;

  String currentStriker;
  String currentNonStriker;
  String currentBowler;

  bool isCompleted;
  bool isFreeHit;
  bool isOverCompleteWaiting;
  String? winnerTeam;
  String? winMargin;

  MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    this.matchName = '',
    this.venue = '',
    required this.dateTime,
    required this.totalOvers,
    this.playersPerTeam = 11,
    this.tossDetails,
    required this.battingTeam,
    required this.bowlingTeam,
    this.currentInnings = 1,
    this.inn1Runs = 0,
    this.inn1Wickets = 0,
    this.inn1Balls = 0,
    List<String>? inn1BallHistory,
    List<OverModel>? inn1Overs,
    this.inn2Runs = 0,
    this.inn2Wickets = 0,
    this.inn2Balls = 0,
    List<String>? inn2BallHistory,
    List<OverModel>? inn2Overs,
    this.currentStriker = 'Batsman 1',
    this.currentNonStriker = 'Batsman 2',
    this.currentBowler = 'Bowler 1',
    this.isCompleted = false,
    this.isFreeHit = false,
    this.isOverCompleteWaiting = false,
    this.winnerTeam,
    this.winMargin,
  })  : inn1BallHistory = inn1BallHistory ?? [],
        inn1Overs = inn1Overs ?? [],
        inn2BallHistory = inn2BallHistory ?? [],
        inn2Overs = inn2Overs ?? [];

  int get maxBalls => totalOvers * 6;

  int get currentRuns => currentInnings == 1 ? inn1Runs : inn2Runs;
  int get currentWickets => currentInnings == 1 ? inn1Wickets : inn2Wickets;
  int get currentBalls => currentInnings == 1 ? inn1Balls : inn2Balls;
  List<String> get currentBallHistory =>
      currentInnings == 1 ? inn1BallHistory : inn2BallHistory;

  List<OverModel> get currentOvers =>
      currentInnings == 1 ? inn1Overs : inn2Overs;

  OverModel? get currentOver =>
      currentOvers.isNotEmpty ? currentOvers.last : null;

  String get currentOversFormatted {
    int overs = currentBalls ~/ 6;
    int ballsInOver = currentBalls % 6;
    return '$overs.$ballsInOver';
  }

  static String formatOvers(int totalBalls) {
    int overs = totalBalls ~/ 6;
    int ballsInOver = totalBalls % 6;
    return '$overs.$ballsInOver';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'teamA': teamA,
      'teamB': teamB,
      'matchName': matchName,
      'venue': venue,
      'dateTime': dateTime.toIso8601String(),
      'totalOvers': totalOvers,
      'playersPerTeam': playersPerTeam,
      'tossDetails': tossDetails?.toJson(),
      'battingTeam': battingTeam,
      'bowlingTeam': bowlingTeam,
      'currentInnings': currentInnings,
      'inn1Runs': inn1Runs,
      'inn1Wickets': inn1Wickets,
      'inn1Balls': inn1Balls,
      'inn1BallHistory': inn1BallHistory,
      'inn1Overs': inn1Overs.map((o) => o.toJson()).toList(),
      'inn2Runs': inn2Runs,
      'inn2Wickets': inn2Wickets,
      'inn2Balls': inn2Balls,
      'inn2BallHistory': inn2BallHistory,
      'inn2Overs': inn2Overs.map((o) => o.toJson()).toList(),
      'currentStriker': currentStriker,
      'currentNonStriker': currentNonStriker,
      'currentBowler': currentBowler,
      'isCompleted': isCompleted,
      'isFreeHit': isFreeHit,
      'isOverCompleteWaiting': isOverCompleteWaiting,
      'winnerTeam': winnerTeam,
      'winMargin': winMargin,
    };
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      teamA: json['teamA'] ?? 'Team A',
      teamB: json['teamB'] ?? 'Team B',
      matchName: json['matchName'] ?? '',
      venue: json['venue'] ?? '',
      dateTime: json['dateTime'] != null
          ? DateTime.parse(json['dateTime'])
          : DateTime.now(),
      totalOvers: json['totalOvers'] ?? 20,
      playersPerTeam: json['playersPerTeam'] ?? 11,
      tossDetails: json['tossDetails'] != null
          ? TossDetails.fromJson(Map<String, dynamic>.from(json['tossDetails']))
          : null,
      battingTeam: json['battingTeam'] ?? json['teamA'] ?? 'Team A',
      bowlingTeam: json['bowlingTeam'] ?? json['teamB'] ?? 'Team B',
      currentInnings: json['currentInnings'] ?? 1,
      inn1Runs: json['inn1Runs'] ?? 0,
      inn1Wickets: json['inn1Wickets'] ?? 0,
      inn1Balls: json['inn1Balls'] ?? 0,
      inn1BallHistory: List<String>.from(json['inn1BallHistory'] ?? []),
      inn1Overs: (json['inn1Overs'] as List<dynamic>?)
              ?.map((o) => OverModel.fromJson(Map<String, dynamic>.from(o)))
              .toList() ??
          [],
      inn2Runs: json['inn2Runs'] ?? 0,
      inn2Wickets: json['inn2Wickets'] ?? 0,
      inn2Balls: json['inn2Balls'] ?? 0,
      inn2BallHistory: List<String>.from(json['inn2BallHistory'] ?? []),
      inn2Overs: (json['inn2Overs'] as List<dynamic>?)
              ?.map((o) => OverModel.fromJson(Map<String, dynamic>.from(o)))
              .toList() ??
          [],
      currentStriker: json['currentStriker'] ?? 'Batsman 1',
      currentNonStriker: json['currentNonStriker'] ?? 'Batsman 2',
      currentBowler: json['currentBowler'] ?? 'Bowler 1',
      isCompleted: json['isCompleted'] ?? false,
      isFreeHit: json['isFreeHit'] ?? false,
      isOverCompleteWaiting: json['isOverCompleteWaiting'] ?? false,
      winnerTeam: json['winnerTeam'],
      winMargin: json['winMargin'],
    );
  }
}


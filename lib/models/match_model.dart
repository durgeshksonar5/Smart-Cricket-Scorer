import 'toss_details.dart';
import 'over_model.dart';
import 'ball_model.dart';
import 'player_model.dart';

enum MatchStatus {
  setup,
  tossPending,
  live,
  inningsBreak,
  completed,
  abandoned,
}

class BatterStats {
  final String playerId;
  final String playerName;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final bool isOut;
  final String dismissalInfo;
  final double strikeRate;

  BatterStats({
    required this.playerId,
    required this.playerName,
    required this.runs,
    required this.balls,
    required this.fours,
    required this.sixes,
    required this.isOut,
    required this.dismissalInfo,
    required this.strikeRate,
  });
}

class BowlerStats {
  final String playerId;
  final String bowlerName;
  final int legalBalls;
  final int runsConceded;
  final int wickets;
  final int maidens;
  final int foursConceded;
  final int sixesConceded;
  final int dots;

  BowlerStats({
    required this.playerId,
    required this.bowlerName,
    required this.legalBalls,
    required this.runsConceded,
    required this.wickets,
    required this.maidens,
    required this.foursConceded,
    required this.sixesConceded,
    required this.dots,
  });

  String get oversFormatted => '${legalBalls ~/ 6}.${legalBalls % 6}';
  double get economy => legalBalls > 0 ? (runsConceded / (legalBalls / 6.0)) : 0.0;
}

class MatchModel {
  final String id;
  String teamA;
  String teamB;
  String matchName;
  String venue;
  DateTime dateTime;
  int totalOvers;
  int playersPerTeam;

  MatchStatus status;
  DateTime? matchCompletedAt;
  DateTime? editExpiresAt;
  DateTime? lastSavedAt;

  TossDetails? tossDetails;

  String battingTeam;
  String bowlingTeam;

  List<PlayerModel> teamAPlayers;
  List<PlayerModel> teamBPlayers;

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
  String currentStrikerId;
  String currentNonStriker;
  String currentNonStrikerId;
  String currentBowler;
  String currentBowlerId;

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
    this.status = MatchStatus.live,
    this.matchCompletedAt,
    this.editExpiresAt,
    this.lastSavedAt,
    this.tossDetails,
    required this.battingTeam,
    required this.bowlingTeam,
    List<PlayerModel>? teamAPlayers,
    List<PlayerModel>? teamBPlayers,
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
    this.currentStrikerId = 'bat_1',
    this.currentNonStriker = 'Batsman 2',
    this.currentNonStrikerId = 'bat_2',
    this.currentBowler = 'Bowler 1',
    this.currentBowlerId = 'bowl_1',
    this.isCompleted = false,
    this.isFreeHit = false,
    this.isOverCompleteWaiting = false,
    this.winnerTeam,
    this.winMargin,
  })  : teamAPlayers = teamAPlayers ?? List.generate(playersPerTeam, (i) => PlayerModel(id: 'a_${i + 1}', name: '$teamA Player ${i + 1}')),
        teamBPlayers = teamBPlayers ?? List.generate(playersPerTeam, (i) => PlayerModel(id: 'b_${i + 1}', name: '$teamB Player ${i + 1}')),
        inn1BallHistory = inn1BallHistory ?? [],
        inn1Overs = inn1Overs ?? [],
        inn2BallHistory = inn2BallHistory ?? [],
        inn2Overs = inn2Overs ?? [];

  int get maxBalls => totalOvers * 6;

  int get currentRuns => currentInnings == 1 ? inn1Runs : inn2Runs;
  int get currentWickets => currentInnings == 1 ? inn1Wickets : inn2Wickets;
  int get currentBalls => currentInnings == 1 ? inn1Balls : inn2Balls;
  List<String> get currentBallHistory => currentInnings == 1 ? inn1BallHistory : inn2BallHistory;

  List<OverModel> get currentOvers => currentInnings == 1 ? inn1Overs : inn2Overs;
  OverModel? get currentOver => currentOvers.isNotEmpty ? currentOvers.last : null;

  List<PlayerModel> get currentBattingSquad => battingTeam == teamA ? teamAPlayers : teamBPlayers;
  List<PlayerModel> get currentBowlingSquad => bowlingTeam == teamA ? teamAPlayers : teamBPlayers;

  bool get isEditable {
    if (status == MatchStatus.completed) {
      if (editExpiresAt != null) {
        return DateTime.now().isBefore(editExpiresAt!);
      }
      return false;
    }
    return status == MatchStatus.live ||
        status == MatchStatus.inningsBreak ||
        status == MatchStatus.tossPending ||
        status == MatchStatus.setup;
  }

  Duration get editTimeRemaining {
    if (editExpiresAt == null) return Duration.zero;
    final diff = editExpiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

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

  List<BatterStats> getBattingStatsForInnings(int innings) {
    List<OverModel> overs = innings == 1 ? inn1Overs : inn2Overs;
    List<PlayerModel> squad = (innings == 1)
        ? (battingTeam == teamA ? teamAPlayers : teamBPlayers)
        : (battingTeam == teamA ? teamBPlayers : teamAPlayers);

    List<BallModel> allBalls = [];
    for (var o in overs) {
      allBalls.addAll(o.balls);
    }

    Map<String, String> playerNamesMap = {};
    for (var p in squad) {
      playerNamesMap[p.id] = p.name;
    }

    Map<String, int> runsMap = {};
    Map<String, int> ballsMap = {};
    Map<String, int> foursMap = {};
    Map<String, int> sixesMap = {};
    Map<String, bool> isOutMap = {};
    Map<String, String> dismissalMap = {};
    Set<String> battedPlayersSet = {};

    for (var b in allBalls) {
      battedPlayersSet.add(b.strikerId);
      battedPlayersSet.add(b.nonStrikerId);
      if (playerNamesMap.containsKey(b.strikerId)) {
        playerNamesMap[b.strikerId] = b.striker;
      }
      if (playerNamesMap.containsKey(b.nonStrikerId)) {
        playerNamesMap[b.nonStrikerId] = b.nonStriker;
      }

      if (b.extraType != 'WD') {
        ballsMap[b.strikerId] = (ballsMap[b.strikerId] ?? 0) + 1;
        int runsOffBat = b.runs;
        if (b.extraType == 'NB') {
          runsOffBat = (b.runs > 1) ? (b.runs - 1) : 0;
        } else if (b.extraType == 'B' || b.extraType == 'LB') {
          runsOffBat = 0;
        }
        runsMap[b.strikerId] = (runsMap[b.strikerId] ?? 0) + runsOffBat;
        if (runsOffBat == 4) foursMap[b.strikerId] = (foursMap[b.strikerId] ?? 0) + 1;
        if (runsOffBat == 6) sixesMap[b.strikerId] = (sixesMap[b.strikerId] ?? 0) + 1;
      }

      if (b.isWicket && b.dismissedBatterId != null) {
        String outId = b.dismissedBatterId!;
        isOutMap[outId] = true;
        String type = b.dismissalType ?? 'Out';
        if (type == 'Bowled') {
          dismissalMap[outId] = 'b ${b.bowler}';
        } else if (type == 'Caught') {
          dismissalMap[outId] = 'c ${b.fielderName ?? "Fielder"} b ${b.bowler}';
        } else if (type == 'LBW') {
          dismissalMap[outId] = 'lbw b ${b.bowler}';
        } else if (type == 'Stumped') {
          dismissalMap[outId] = 'st b ${b.bowler}';
        } else if (type == 'Hit Wicket') {
          dismissalMap[outId] = 'hit wicket b ${b.bowler}';
        } else if (type == 'Run Out') {
          dismissalMap[outId] = 'run out';
        } else {
          dismissalMap[outId] = type.toLowerCase();
        }
      }
    }

    List<BatterStats> list = [];
    for (var p in squad) {
      if (battedPlayersSet.contains(p.id) || p.id == currentStrikerId || p.id == currentNonStrikerId) {
        int r = runsMap[p.id] ?? 0;
        int b = ballsMap[p.id] ?? 0;
        int f = foursMap[p.id] ?? 0;
        int s = sixesMap[p.id] ?? 0;
        bool out = isOutMap[p.id] ?? false;
        String d = out ? (dismissalMap[p.id] ?? 'out') : 'not out';
        double sr = b > 0 ? (r / b) * 100 : 0.0;
        list.add(BatterStats(
          playerId: p.id,
          playerName: p.name,
          runs: r,
          balls: b,
          fours: f,
          sixes: s,
          isOut: out,
          dismissalInfo: d,
          strikeRate: sr,
        ));
      }
    }
    return list;
  }

  List<BowlerStats> getBowlingStatsForInnings(int innings) {
    List<OverModel> overs = innings == 1 ? inn1Overs : inn2Overs;
    Map<String, String> bowlerNameMap = {};
    Map<String, int> legalBallsMap = {};
    Map<String, int> runsConcededMap = {};
    Map<String, int> wicketsMap = {};
    Map<String, int> foursMap = {};
    Map<String, int> sixesMap = {};
    Map<String, int> dotsMap = {};

    for (var o in overs) {
      for (var b in o.balls) {
        bowlerNameMap[b.bowlerId] = b.bowler;
        if (b.isLegal) {
          legalBallsMap[b.bowlerId] = (legalBallsMap[b.bowlerId] ?? 0) + 1;
        }

        if (b.extraType != 'B' && b.extraType != 'LB') {
          runsConcededMap[b.bowlerId] = (runsConcededMap[b.bowlerId] ?? 0) + b.runs;
        }

        if (b.isWicket) {
          String type = b.dismissalType ?? 'Out';
          if (type != 'Run Out' && type != 'Retired Out') {
            wicketsMap[b.bowlerId] = (wicketsMap[b.bowlerId] ?? 0) + 1;
          }
        }

        if (b.runs == 4 || b.displayResult.contains('4')) foursMap[b.bowlerId] = (foursMap[b.bowlerId] ?? 0) + 1;
        if (b.runs == 6 || b.displayResult.contains('6')) sixesMap[b.bowlerId] = (sixesMap[b.bowlerId] ?? 0) + 1;
        if (b.isLegal && b.runs == 0) dotsMap[b.bowlerId] = (dotsMap[b.bowlerId] ?? 0) + 1;
      }
    }

    Map<String, int> maidensMap = {};
    for (var o in overs) {
      if (o.isComplete && o.balls.isNotEmpty) {
        String bId = o.balls.first.bowlerId;
        int runsInOverCharged = 0;
        for (var b in o.balls) {
          if (b.extraType != 'B' && b.extraType != 'LB') {
            runsInOverCharged += b.runs;
          }
        }
        if (runsInOverCharged == 0) {
          maidensMap[bId] = (maidensMap[bId] ?? 0) + 1;
        }
      }
    }

    List<BowlerStats> list = [];
    bowlerNameMap.forEach((bId, bName) {
      list.add(BowlerStats(
        playerId: bId,
        bowlerName: bName,
        legalBalls: legalBallsMap[bId] ?? 0,
        runsConceded: runsConcededMap[bId] ?? 0,
        wickets: wicketsMap[bId] ?? 0,
        maidens: maidensMap[bId] ?? 0,
        foursConceded: foursMap[bId] ?? 0,
        sixesConceded: sixesMap[bId] ?? 0,
        dots: dotsMap[bId] ?? 0,
      ));
    });
    return list;
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
      'status': status.name,
      'matchCompletedAt': matchCompletedAt?.toIso8601String(),
      'editExpiresAt': editExpiresAt?.toIso8601String(),
      'lastSavedAt': lastSavedAt?.toIso8601String(),
      'tossDetails': tossDetails?.toJson(),
      'battingTeam': battingTeam,
      'bowlingTeam': bowlingTeam,
      'teamAPlayers': teamAPlayers.map((p) => p.toJson()).toList(),
      'teamBPlayers': teamBPlayers.map((p) => p.toJson()).toList(),
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
      'currentStrikerId': currentStrikerId,
      'currentNonStriker': currentNonStriker,
      'currentNonStrikerId': currentNonStrikerId,
      'currentBowler': currentBowler,
      'currentBowlerId': currentBowlerId,
      'isCompleted': isCompleted,
      'isFreeHit': isFreeHit,
      'isOverCompleteWaiting': isOverCompleteWaiting,
      'winnerTeam': winnerTeam,
      'winMargin': winMargin,
    };
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    int numPlayers = json['playersPerTeam'] ?? 11;
    String tA = json['teamA'] ?? 'Team A';
    String tB = json['teamB'] ?? 'Team B';

    List<PlayerModel> aPlayers = (json['teamAPlayers'] as List<dynamic>?)
            ?.map((p) => PlayerModel.fromJson(Map<String, dynamic>.from(p)))
            .toList() ??
        List.generate(numPlayers, (i) => PlayerModel(id: 'a_${i + 1}', name: '$tA Player ${i + 1}'));

    List<PlayerModel> bPlayers = (json['teamBPlayers'] as List<dynamic>?)
            ?.map((p) => PlayerModel.fromJson(Map<String, dynamic>.from(p)))
            .toList() ??
        List.generate(numPlayers, (i) => PlayerModel(id: 'b_${i + 1}', name: '$tB Player ${i + 1}'));

    MatchStatus parsedStatus = MatchStatus.live;
    if (json['status'] != null) {
      try {
        parsedStatus = MatchStatus.values.firstWhere((e) => e.name == json['status']);
      } catch (_) {}
    } else if (json['isCompleted'] == true) {
      parsedStatus = MatchStatus.completed;
    }

    return MatchModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      teamA: tA,
      teamB: tB,
      matchName: json['matchName'] ?? '',
      venue: json['venue'] ?? '',
      dateTime: json['dateTime'] != null ? DateTime.parse(json['dateTime']) : DateTime.now(),
      totalOvers: json['totalOvers'] ?? 20,
      playersPerTeam: numPlayers,
      status: parsedStatus,
      matchCompletedAt: json['matchCompletedAt'] != null ? DateTime.parse(json['matchCompletedAt']) : null,
      editExpiresAt: json['editExpiresAt'] != null ? DateTime.parse(json['editExpiresAt']) : null,
      lastSavedAt: json['lastSavedAt'] != null ? DateTime.parse(json['lastSavedAt']) : null,
      tossDetails: json['tossDetails'] != null ? TossDetails.fromJson(Map<String, dynamic>.from(json['tossDetails'])) : null,
      battingTeam: json['battingTeam'] ?? tA,
      bowlingTeam: json['bowlingTeam'] ?? tB,
      teamAPlayers: aPlayers,
      teamBPlayers: bPlayers,
      currentInnings: json['currentInnings'] ?? 1,
      inn1Runs: json['inn1Runs'] ?? 0,
      inn1Wickets: json['inn1Wickets'] ?? 0,
      inn1Balls: json['inn1Balls'] ?? 0,
      inn1BallHistory: List<String>.from(json['inn1BallHistory'] ?? []),
      inn1Overs: (json['inn1Overs'] as List<dynamic>?)?.map((o) => OverModel.fromJson(Map<String, dynamic>.from(o))).toList() ?? [],
      inn2Runs: json['inn2Runs'] ?? 0,
      inn2Wickets: json['inn2Wickets'] ?? 0,
      inn2Balls: json['inn2Balls'] ?? 0,
      inn2BallHistory: List<String>.from(json['inn2BallHistory'] ?? []),
      inn2Overs: (json['inn2Overs'] as List<dynamic>?)?.map((o) => OverModel.fromJson(Map<String, dynamic>.from(o))).toList() ?? [],
      currentStriker: json['currentStriker'] ?? 'Batsman 1',
      currentStrikerId: json['currentStrikerId'] ?? 'bat_1',
      currentNonStriker: json['currentNonStriker'] ?? 'Batsman 2',
      currentNonStrikerId: json['currentNonStrikerId'] ?? 'bat_2',
      currentBowler: json['currentBowler'] ?? 'Bowler 1',
      currentBowlerId: json['currentBowlerId'] ?? 'bowl_1',
      isCompleted: json['isCompleted'] ?? false,
      isFreeHit: json['isFreeHit'] ?? false,
      isOverCompleteWaiting: json['isOverCompleteWaiting'] ?? false,
      winnerTeam: json['winnerTeam'],
      winMargin: json['winMargin'],
    );
  }
}

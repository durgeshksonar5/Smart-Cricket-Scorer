class BallModel {
  final int overNumber; // 1-indexed over number (e.g. 1, 2, 3...)
  final int ballInOver; // legal ball number within over (1..6)
  final String ballNumberFormatted; // e.g. "0.1", "0.2", "0.3 Wd", "1.4"
  final int runs;
  final String displayResult; // e.g. "0", "1", "4", "6", "W", "Wd", "Nb", "B1", "LB2"
  final bool isLegal;
  final bool isWicket;
  final String? extraType; // 'WD', 'NB', 'BYE', 'LB'
  final String striker;
  final String strikerId;
  final String nonStriker;
  final String nonStrikerId;
  final String bowler;
  final String bowlerId;
  final String teamScoreSnapshot; // e.g. "72/2"
  final String? dismissalType; // 'Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'Hit Wicket', 'Retired Out'
  final String? dismissedBatterId;
  final String? fielderName;

  bool get isWide => extraType == 'WD';
  bool get isNoBall => extraType == 'NB';
  int get totalRuns => runs;
  int get batterRuns {
    if (extraType == 'WD' || extraType == 'BYE' || extraType == 'B' || extraType == 'LB') {
      return 0;
    } else if (extraType == 'NB') {
      return runs > 0 ? runs - 1 : 0;
    }
    return runs;
  }

  BallModel({
    required this.overNumber,
    required this.ballInOver,
    required this.ballNumberFormatted,
    required this.runs,
    required this.displayResult,
    required this.isLegal,
    required this.isWicket,
    this.extraType,
    required this.striker,
    required this.strikerId,
    required this.nonStriker,
    required this.nonStrikerId,
    required this.bowler,
    required this.bowlerId,
    required this.teamScoreSnapshot,
    this.dismissalType,
    this.dismissedBatterId,
    this.fielderName,
  });

  Map<String, dynamic> toJson() {
    return {
      'overNumber': overNumber,
      'ballInOver': ballInOver,
      'ballNumberFormatted': ballNumberFormatted,
      'runs': runs,
      'displayResult': displayResult,
      'isLegal': isLegal,
      'isWicket': isWicket,
      'extraType': extraType,
      'striker': striker,
      'strikerId': strikerId,
      'nonStriker': nonStriker,
      'nonStrikerId': nonStrikerId,
      'bowler': bowler,
      'bowlerId': bowlerId,
      'teamScoreSnapshot': teamScoreSnapshot,
      'dismissalType': dismissalType,
      'dismissedBatterId': dismissedBatterId,
      'fielderName': fielderName,
    };
  }

  factory BallModel.fromJson(Map<String, dynamic> json) {
    return BallModel(
      overNumber: json['overNumber'] ?? 1,
      ballInOver: json['ballInOver'] ?? 1,
      ballNumberFormatted: json['ballNumberFormatted'] ?? '0.1',
      runs: json['runs'] ?? 0,
      displayResult: json['displayResult'] ?? '0',
      isLegal: json['isLegal'] ?? true,
      isWicket: json['isWicket'] ?? false,
      extraType: json['extraType'],
      striker: json['striker'] ?? 'Striker',
      strikerId: json['strikerId'] ?? json['striker'] ?? 'striker_id',
      nonStriker: json['nonStriker'] ?? 'Non-Striker',
      nonStrikerId: json['nonStrikerId'] ?? json['nonStriker'] ?? 'non_striker_id',
      bowler: json['bowler'] ?? 'Bowler',
      bowlerId: json['bowlerId'] ?? json['bowler'] ?? 'bowler_id',
      teamScoreSnapshot: json['teamScoreSnapshot'] ?? '0/0',
      dismissalType: json['dismissalType'],
      dismissedBatterId: json['dismissedBatterId'],
      fielderName: json['fielderName'],
    );
  }
}

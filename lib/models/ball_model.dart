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
  final String nonStriker;
  final String bowler;
  final String teamScoreSnapshot; // e.g. "72/2"

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
    required this.nonStriker,
    required this.bowler,
    required this.teamScoreSnapshot,
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
      'nonStriker': nonStriker,
      'bowler': bowler,
      'teamScoreSnapshot': teamScoreSnapshot,
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
      nonStriker: json['nonStriker'] ?? 'Non-Striker',
      bowler: json['bowler'] ?? 'Bowler',
      teamScoreSnapshot: json['teamScoreSnapshot'] ?? '0/0',
    );
  }
}

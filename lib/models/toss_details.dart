class TossDetails {
  final String callingTeam;
  final String tossCall; // "HEADS" or "TAILS"
  final String coinResult; // "HEADS" or "TAILS"
  final bool isGuessCorrect;
  final String tossWinnerTeam;
  final String tossDecision; // "Bat First" or "Bowl First"
  final String battingTeam;
  final String bowlingTeam;

  TossDetails({
    required this.callingTeam,
    required this.tossCall,
    required this.coinResult,
    required this.isGuessCorrect,
    required this.tossWinnerTeam,
    required this.tossDecision,
    required this.battingTeam,
    required this.bowlingTeam,
  });

  Map<String, dynamic> toJson() {
    return {
      'callingTeam': callingTeam,
      'tossCall': tossCall,
      'coinResult': coinResult,
      'isGuessCorrect': isGuessCorrect,
      'tossWinnerTeam': tossWinnerTeam,
      'tossDecision': tossDecision,
      'battingTeam': battingTeam,
      'bowlingTeam': bowlingTeam,
    };
  }

  factory TossDetails.fromJson(Map<String, dynamic> json) {
    return TossDetails(
      callingTeam: json['callingTeam'] ?? '',
      tossCall: json['tossCall'] ?? 'HEADS',
      coinResult: json['coinResult'] ?? 'HEADS',
      isGuessCorrect: json['isGuessCorrect'] ?? false,
      tossWinnerTeam: json['tossWinnerTeam'] ?? '',
      tossDecision: json['tossDecision'] ?? 'Bat First',
      battingTeam: json['battingTeam'] ?? '',
      bowlingTeam: json['bowlingTeam'] ?? '',
    );
  }
}

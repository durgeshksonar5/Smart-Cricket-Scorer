import 'dart:math';
import '../models/toss_details.dart';

class TossService {
  final Random _random = Random();

  /// Randomly flips a coin using Dart's `Random().nextBool()`
  /// Returns "HEADS" if true, "TAILS" if false.
  String flipCoin() {
    bool isHeads = _random.nextBool();
    return isHeads ? 'HEADS' : 'TAILS';
  }

  /// Calculates toss winner based on call vs result and constructs [TossDetails].
  TossDetails processTossResult({
    required String callingTeam,
    required String otherTeam,
    required String tossCall,
    required String coinResult,
    required String tossDecision, // "Bat First" or "Bowl First"
  }) {
    bool isCorrect = (tossCall.toUpperCase() == coinResult.toUpperCase());
    String winnerTeam = isCorrect ? callingTeam : otherTeam;
    String tossLoserTeam = (winnerTeam == callingTeam) ? otherTeam : callingTeam;

    String battingTeam = (tossDecision == 'Bat First') ? winnerTeam : tossLoserTeam;
    String bowlingTeam = (tossDecision == 'Bat First') ? tossLoserTeam : winnerTeam;

    return TossDetails(
      callingTeam: callingTeam,
      tossCall: tossCall,
      coinResult: coinResult,
      isGuessCorrect: isCorrect,
      tossWinnerTeam: winnerTeam,
      tossDecision: tossDecision,
      battingTeam: battingTeam,
      bowlingTeam: bowlingTeam,
    );
  }

  /// Determines batting and bowling teams based on toss winner & decision.
  Map<String, String> assignTeamsBasedOnToss({
    required String teamA,
    required String teamB,
    required String tossWinnerTeam,
    required String tossDecision,
  }) {
    String tossLoserTeam = (tossWinnerTeam == teamA) ? teamB : teamA;

    if (tossDecision == 'Bat First') {
      return {
        'battingTeam': tossWinnerTeam,
        'bowlingTeam': tossLoserTeam,
      };
    } else {
      return {
        'battingTeam': tossLoserTeam,
        'bowlingTeam': tossWinnerTeam,
      };
    }
  }
}

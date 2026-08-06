import 'package:flutter_test/flutter_test.dart';
import 'package:cricket/services/toss_service.dart';
import 'package:cricket/models/toss_details.dart';

void main() {
  group('TossService Tests', () {
    late TossService tossService;

    setUp(() {
      tossService = TossService();
    });

    test('flipCoin returns HEADS or TAILS using Random()', () {
      final result = tossService.flipCoin();
      expect(result == 'HEADS' || result == 'TAILS', isTrue);
    });

    test('processTossResult correctly identifies winner when guess is correct', () {
      TossDetails details = tossService.processTossResult(
        callingTeam: 'India',
        otherTeam: 'Australia',
        tossCall: 'HEADS',
        coinResult: 'HEADS',
        tossDecision: 'Bat First',
      );

      expect(details.isGuessCorrect, isTrue);
      expect(details.tossWinnerTeam, equals('India'));
      expect(details.battingTeam, equals('India'));
      expect(details.bowlingTeam, equals('Australia'));
    });

    test('processTossResult correctly identifies winner when guess is wrong', () {
      TossDetails details = tossService.processTossResult(
        callingTeam: 'India',
        otherTeam: 'Australia',
        tossCall: 'HEADS',
        coinResult: 'TAILS',
        tossDecision: 'Bowl First',
      );

      expect(details.isGuessCorrect, isFalse);
      expect(details.tossWinnerTeam, equals('Australia'));
      expect(details.battingTeam, equals('India'));
      expect(details.bowlingTeam, equals('Australia'));
    });

    test('assignTeamsBasedOnToss assigns correct batting/bowling team for Bat First', () {
      var teams = tossService.assignTeamsBasedOnToss(
        teamA: 'India',
        teamB: 'Australia',
        tossWinnerTeam: 'India',
        tossDecision: 'Bat First',
      );

      expect(teams['battingTeam'], equals('India'));
      expect(teams['bowlingTeam'], equals('Australia'));
    });

    test('assignTeamsBasedOnToss swaps teams when toss winner chooses Bowl First', () {
      var teams = tossService.assignTeamsBasedOnToss(
        teamA: 'India',
        teamB: 'Australia',
        tossWinnerTeam: 'India',
        tossDecision: 'Bowl First',
      );

      expect(teams['battingTeam'], equals('Australia'));
      expect(teams['bowlingTeam'], equals('India'));
    });
  });
}

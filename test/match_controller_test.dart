import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket/controllers/match_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MatchController Tests', () {
    late MatchController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = MatchController();
    });

    test('setupMatch initializes match model correctly', () {
      controller.setupMatch(
        teamA: 'India',
        teamB: 'Australia',
        dateTime: DateTime.now(),
        totalOvers: 20,
      );

      expect(controller.currentMatch, isNotNull);
      expect(controller.currentMatch!.teamA, equals('India'));
      expect(controller.currentMatch!.teamB, equals('Australia'));
      expect(controller.currentMatch!.totalOvers, equals(20));
    });

    test('finalizeTossDecision applies team assignment properly', () {
      controller.setupMatch(
        teamA: 'India',
        teamB: 'Australia',
        dateTime: DateTime.now(),
        totalOvers: 20,
      );

      controller.finalizeTossDecision(
        callingTeam: 'India',
        tossCall: 'HEADS',
        coinResult: 'HEADS',
        tossDecision: 'Bowl First',
      );

      expect(controller.currentMatch!.tossDetails!.tossWinnerTeam, equals('India'));
      expect(controller.currentMatch!.battingTeam, equals('Australia'));
      expect(controller.currentMatch!.bowlingTeam, equals('India'));
    });

    test('recordBall updates score and handles innings transition', () {
      controller.setupMatch(
        teamA: 'India',
        teamB: 'Australia',
        dateTime: DateTime.now(),
        totalOvers: 1, // 6 balls
      );

      controller.finalizeTossDecision(
        callingTeam: 'India',
        tossCall: 'HEADS',
        coinResult: 'HEADS',
        tossDecision: 'Bat First',
      );

      // Score 6 runs
      controller.recordBall(runs: 6);
      expect(controller.currentMatch!.inn1Runs, equals(6));
      expect(controller.currentMatch!.inn1Balls, equals(1));

      // Score 4 runs
      controller.recordBall(runs: 4);
      expect(controller.currentMatch!.inn1Runs, equals(10));
      expect(controller.currentMatch!.inn1Balls, equals(2));
    });

    test('setOpeningPlayers sets active players and clears opening selection pending flag', () {
      controller.setupMatch(
        teamA: 'India',
        teamB: 'Australia',
        dateTime: DateTime.now(),
        totalOvers: 20,
      );
      controller.finalizeTossDecision(
        callingTeam: 'India',
        tossCall: 'HEADS',
        coinResult: 'HEADS',
        tossDecision: 'Bat First',
      );

      final batSquad = controller.currentMatch!.currentBattingSquad;
      final bowlSquad = controller.currentMatch!.currentBowlingSquad;

      controller.setOpeningPlayers(
        striker: batSquad[0],
        nonStriker: batSquad[1],
        bowler: bowlSquad[0],
      );

      expect(controller.currentMatch!.isOpeningSelectionPending, isFalse);
      expect(controller.currentMatch!.currentStrikerId, equals(batSquad[0].id));
      expect(controller.currentMatch!.currentNonStrikerId, equals(batSquad[1].id));
      expect(controller.currentMatch!.currentBowlerId, equals(bowlSquad[0].id));
    });

    test('strike rotation swaps striker on 1 run and at end of over', () {
      controller.setupMatch(
        teamA: 'India',
        teamB: 'Australia',
        dateTime: DateTime.now(),
        totalOvers: 20,
      );
      controller.finalizeTossDecision(
        callingTeam: 'India',
        tossCall: 'HEADS',
        coinResult: 'HEADS',
        tossDecision: 'Bat First',
      );

      final batSquad = controller.currentMatch!.currentBattingSquad;
      final bowlSquad = controller.currentMatch!.currentBowlingSquad;

      controller.setOpeningPlayers(
        striker: batSquad[0],
        nonStriker: batSquad[1],
        bowler: bowlSquad[0],
      );

      String s1 = batSquad[0].id;
      String s2 = batSquad[1].id;

      // 1 run: should swap striker
      controller.recordBall(runs: 1);
      expect(controller.currentMatch!.currentStrikerId, equals(s2));
      expect(controller.currentMatch!.currentNonStrikerId, equals(s1));

      // 2 runs: should keep striker
      controller.recordBall(runs: 2);
      expect(controller.currentMatch!.currentStrikerId, equals(s2));
      expect(controller.currentMatch!.currentNonStrikerId, equals(s1));

      // Complete over (4 more legal balls)
      controller.recordBall(runs: 0);
      controller.recordBall(runs: 0);
      controller.recordBall(runs: 0);
      controller.recordBall(runs: 0); // ball 6

      // Over complete should swap striker and set previousBowlerId
      expect(controller.currentMatch!.previousBowlerId, equals(bowlSquad[0].id));
      expect(controller.currentMatch!.currentStrikerId, equals(s1));
    });
  });
}

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
  });
}

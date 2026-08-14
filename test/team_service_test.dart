import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket/models/team_model.dart';
import 'package:cricket/models/player_model.dart';
import 'package:cricket/models/match_model.dart';
import 'package:cricket/services/team_service.dart';
import 'package:cricket/controllers/match_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TeamService & Roster Tests', () {
    late TeamService teamService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      teamService = TeamService();
    });

    test('getSavedTeams returns default seeded teams on first run', () async {
      List<TeamModel> teams = await teamService.getSavedTeams();
      expect(teams.length, greaterThanOrEqualTo(2));
      expect(teams.any((t) => t.name == 'India'), isTrue);
      expect(teams.any((t) => t.name == 'Australia'), isTrue);

      final india = teams.firstWhere((t) => t.name == 'India');
      expect(india.players.length, equals(11));
      expect(india.players.first.name, equals('Rohit Sharma'));
    });

    test('saveTeam and deleteTeam persist rosters correctly', () async {
      TeamModel customTeam = TeamModel(
        id: 'team_local_xi',
        name: 'Local XI',
        players: [
          PlayerModel(id: 'p1', name: 'John Doe', isCaptain: true),
          PlayerModel(id: 'p2', name: 'Jane Smith', isWicketKeeper: true),
        ],
      );

      await teamService.saveTeam(customTeam);
      List<TeamModel> teams = await teamService.getSavedTeams();
      expect(teams.any((t) => t.id == 'team_local_xi'), isTrue);

      await teamService.deleteTeam('team_local_xi');
      teams = await teamService.getSavedTeams();
      expect(teams.any((t) => t.id == 'team_local_xi'), isFalse);
    });

    test('startRematch carries forward team names and players but resets all scoring stats to 0', () {
      final controller = MatchController();

      controller.setupMatch(
        teamA: 'India',
        teamB: 'Australia',
        dateTime: DateTime.now(),
        totalOvers: 20,
        playersPerTeam: 11,
      );

      controller.finalizeTossDecision(
        callingTeam: 'India',
        tossCall: 'HEADS',
        coinResult: 'HEADS',
        tossDecision: 'Bat First',
      );

      // Score some runs in match 1
      controller.recordBall(runs: 4);
      controller.recordBall(runs: 6);
      expect(controller.currentMatch!.inn1Runs, equals(10));
      expect(controller.currentMatch!.inn1Balls, equals(2));

      MatchModel previousMatch = controller.currentMatch!;

      // Start Rematch
      controller.startRematch(previousMatch);

      expect(controller.currentMatch, isNotNull);
      expect(controller.currentMatch!.teamA, equals('India'));
      expect(controller.currentMatch!.teamB, equals('Australia'));
      expect(controller.currentMatch!.teamAPlayers.length, equals(11));
      expect(controller.currentMatch!.teamBPlayers.length, equals(11));

      // Scoring statistics MUST be completely reset to 0
      expect(controller.currentMatch!.inn1Runs, equals(0));
      expect(controller.currentMatch!.inn1Wickets, equals(0));
      expect(controller.currentMatch!.inn1Balls, equals(0));
      expect(controller.currentMatch!.inn1BallHistory, isEmpty);
      expect(controller.currentMatch!.inn2Runs, equals(0));
      expect(controller.currentMatch!.inn2Wickets, equals(0));
      expect(controller.currentMatch!.inn2Balls, equals(0));
      expect(controller.currentMatch!.inn2BallHistory, isEmpty);
      expect(controller.currentMatch!.isCompleted, isFalse);
      expect(controller.currentMatch!.status, equals(MatchStatus.tossPending));
    });

    test('Historical match snapshot protection: editing team roster does not mutate past match', () async {
      final controller = MatchController();

      controller.setupMatch(
        teamA: 'India',
        teamB: 'Australia',
        dateTime: DateTime.now(),
        totalOvers: 20,
        teamAPlayers: [
          PlayerModel(id: 'p1', name: 'Rohit Sharma'),
          PlayerModel(id: 'p2', name: 'Virat Kohli'),
        ],
        teamBPlayers: [
          PlayerModel(id: 'p3', name: 'David Warner'),
          PlayerModel(id: 'p4', name: 'Steve Smith'),
        ],
      );

      MatchModel matchSnapshot = controller.currentMatch!;
      expect(matchSnapshot.teamAPlayers.first.name, equals('Rohit Sharma'));

      // Later user creates or edits saved team
      TeamModel modifiedTeam = TeamModel(
        id: 'team_india_default',
        name: 'India',
        players: [
          PlayerModel(id: 'p1', name: 'Rohit S'),
          PlayerModel(id: 'p2', name: 'Virat K'),
        ],
      );
      await controller.saveTeam(modifiedTeam);

      // Verify past match snapshot remains intact
      expect(matchSnapshot.teamAPlayers.first.name, equals('Rohit Sharma'));
    });

    test('Reusing previous teams with modified overs (10) and players (8) leaves previous match 20-over 11-player record completely intact', () {
      final controller = MatchController();

      // Setup Match 1 (20 overs, 11 players)
      controller.setupMatch(
        teamA: 'India',
        teamB: 'Australia',
        dateTime: DateTime.now(),
        totalOvers: 20,
        playersPerTeam: 11,
      );
      controller.finalizeTossDecision(
        callingTeam: 'India',
        tossCall: 'HEADS',
        coinResult: 'HEADS',
        tossDecision: 'Bat First',
      );
      controller.recordBall(runs: 6);
      MatchModel match1 = controller.currentMatch!;
      expect(match1.totalOvers, equals(20));
      expect(match1.playersPerTeam, equals(11));
      expect(match1.inn1Runs, equals(6));

      // Setup Match 2 by reusing India & Australia with 10 overs and 8 players
      List<PlayerModel> selected8A = match1.teamAPlayers.take(8).toList();
      List<PlayerModel> selected8B = match1.teamBPlayers.take(8).toList();

      controller.setupMatch(
        teamA: match1.teamA,
        teamB: match1.teamB,
        dateTime: DateTime.now(),
        totalOvers: 10,
        playersPerTeam: 8,
        teamAPlayers: selected8A,
        teamBPlayers: selected8B,
      );

      MatchModel match2 = controller.currentMatch!;

      // Match 2 must have new config and 0 score
      expect(match2.totalOvers, equals(10));
      expect(match2.playersPerTeam, equals(8));
      expect(match2.teamAPlayers.length, equals(8));
      expect(match2.teamBPlayers.length, equals(8));
      expect(match2.inn1Runs, equals(0));
      expect(match2.inn1Balls, equals(0));

      // Match 1 remains completely unchanged
      expect(match1.totalOvers, equals(20));
      expect(match1.playersPerTeam, equals(11));
      expect(match1.inn1Runs, equals(6));
    });
  });
}

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_model.dart';
import '../models/player_model.dart';

class TeamService {
  static const String _savedTeamsKey = 'cricket_saved_teams_v1';
  static const String _lastUsedMatchTeamsKey = 'cricket_last_used_match_teams_v1';

  /// Default predefined teams seeded on initial launch
  static List<TeamModel> get _defaultTeams => [
        TeamModel(
          id: 'team_india_default',
          name: 'India',
          players: [
            PlayerModel(id: 'ind_1', name: 'Rohit Sharma', isCaptain: true),
            PlayerModel(id: 'ind_2', name: 'Shubman Gill'),
            PlayerModel(id: 'ind_3', name: 'Virat Kohli'),
            PlayerModel(id: 'ind_4', name: 'Hardik Pandya'),
            PlayerModel(id: 'ind_5', name: 'KL Rahul', isWicketKeeper: true),
            PlayerModel(id: 'ind_6', name: 'Rishabh Pant'),
            PlayerModel(id: 'ind_7', name: 'Ravindra Jadeja'),
            PlayerModel(id: 'ind_8', name: 'Jasprit Bumrah'),
            PlayerModel(id: 'ind_9', name: 'Mohammed Siraj'),
            PlayerModel(id: 'ind_10', name: 'Mohammed Shami'),
            PlayerModel(id: 'ind_11', name: 'Kuldeep Yadav'),
          ],
        ),
        TeamModel(
          id: 'team_aus_default',
          name: 'Australia',
          players: [
            PlayerModel(id: 'aus_1', name: 'David Warner'),
            PlayerModel(id: 'aus_2', name: 'Travis Head'),
            PlayerModel(id: 'aus_3', name: 'Steve Smith'),
            PlayerModel(id: 'aus_4', name: 'Marnus Labuschagne'),
            PlayerModel(id: 'aus_5', name: 'Glenn Maxwell'),
            PlayerModel(id: 'aus_6', name: 'Marcus Stoinis'),
            PlayerModel(id: 'aus_7', name: 'Alex Carey', isWicketKeeper: true),
            PlayerModel(id: 'aus_8', name: 'Pat Cummins', isCaptain: true),
            PlayerModel(id: 'aus_9', name: 'Mitchell Starc'),
            PlayerModel(id: 'aus_10', name: 'Adam Zampa'),
            PlayerModel(id: 'aus_11', name: 'Josh Hazlewood'),
          ],
        ),
      ];

  /// Get all saved teams from persistent storage (with automatic seed if empty)
  Future<List<TeamModel>> getSavedTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? rawList = prefs.getStringList(_savedTeamsKey);

      if (rawList == null || rawList.isEmpty) {
        // Initialize default seed teams
        List<TeamModel> defaults = _defaultTeams;
        await _saveAllTeams(defaults);
        return defaults;
      }

      return rawList.map((str) {
        Map<String, dynamic> jsonMap = jsonDecode(str);
        return TeamModel.fromJson(jsonMap);
      }).toList();
    } catch (e) {
      return _defaultTeams;
    }
  }

  /// Save or update a team in persistent storage
  Future<void> saveTeam(TeamModel team) async {
    List<TeamModel> teams = await getSavedTeams();

    int existingIndex = teams.indexWhere((t) => t.id == team.id || t.name.trim().toLowerCase() == team.name.trim().toLowerCase());
    team.updatedAt = DateTime.now();

    if (existingIndex >= 0) {
      teams[existingIndex] = team;
    } else {
      teams.add(team);
    }

    await _saveAllTeams(teams);
  }

  /// Delete a saved team by ID
  Future<void> deleteTeam(String teamId) async {
    List<TeamModel> teams = await getSavedTeams();
    teams.removeWhere((t) => t.id == teamId);
    await _saveAllTeams(teams);
  }

  /// Get single team by ID
  Future<TeamModel?> getTeamById(String teamId) async {
    List<TeamModel> teams = await getSavedTeams();
    try {
      return teams.firstWhere((t) => t.id == teamId);
    } catch (_) {
      return null;
    }
  }

  /// Internal helper to serialize and persist all teams
  Future<void> _saveAllTeams(List<TeamModel> teams) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> rawList = teams.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_savedTeamsKey, rawList);
    } catch (_) {}
  }

  /// Save the last used teams and their rosters from a match setup
  Future<void> saveLastUsedTeams({
    required String teamA,
    required List<PlayerModel> teamAPlayers,
    required String teamB,
    required List<PlayerModel> teamBPlayers,
    int totalOvers = 20,
    int playersPerTeam = 11,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> data = {
        'teamA': teamA,
        'teamB': teamB,
        'totalOvers': totalOvers,
        'playersPerTeam': playersPerTeam,
        'teamAPlayers': teamAPlayers.map((p) => p.toJson()).toList(),
        'teamBPlayers': teamBPlayers.map((p) => p.toJson()).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_lastUsedMatchTeamsKey, jsonEncode(data));

      // Also ensure both teams exist in saved rosters for future selection
      await _autoSaveTeamRoster(teamA, teamAPlayers);
      await _autoSaveTeamRoster(teamB, teamBPlayers);
    } catch (_) {}
  }

  /// Auto save or update team roster if user customizes it
  Future<void> _autoSaveTeamRoster(String teamName, List<PlayerModel> players) async {
    if (teamName.trim().isEmpty || players.isEmpty) return;
    List<TeamModel> existing = await getSavedTeams();
    int idx = existing.indexWhere((t) => t.name.trim().toLowerCase() == teamName.trim().toLowerCase());
    if (idx >= 0) {
      // Keep existing team id, update roster
      TeamModel current = existing[idx];
      current.players = players.map((p) => PlayerModel(
        id: p.id,
        name: p.name,
        isCaptain: p.isCaptain,
        isWicketKeeper: p.isWicketKeeper,
      )).toList();
      current.updatedAt = DateTime.now();
      await saveTeam(current);
    } else {
      // Create new team
      TeamModel newTeam = TeamModel(
        id: 'team_${DateTime.now().millisecondsSinceEpoch}_${teamName.toLowerCase().replaceAll(' ', '_')}',
        name: teamName.trim(),
        players: players.map((p) => PlayerModel(
          id: p.id,
          name: p.name,
          isCaptain: p.isCaptain,
          isWicketKeeper: p.isWicketKeeper,
        )).toList(),
      );
      await saveTeam(newTeam);
    }
  }

  /// Retrieve the last used match setup & team rosters
  Future<Map<String, dynamic>?> getLastUsedTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? raw = prefs.getString(_lastUsedMatchTeamsKey);
      if (raw == null || raw.trim().isEmpty) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

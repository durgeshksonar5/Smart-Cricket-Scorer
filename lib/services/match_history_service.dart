import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_model.dart';

class MatchHistoryService {
  static const String _storageKey = 'cricket_match_history_v1';

  /// Save a completed or updated match into SharedPreferences
  Future<void> saveMatch(MatchModel match) async {
    final prefs = await SharedPreferences.getInstance();
    List<MatchModel> currentMatches = await getMatchHistory();

    // Remove existing entry if updating
    currentMatches.removeWhere((m) => m.id == match.id);

    // Insert newest match at top
    currentMatches.insert(0, match);

    List<String> rawJsonList =
        currentMatches.map((m) => jsonEncode(m.toJson())).toList();

    await prefs.setStringList(_storageKey, rawJsonList);
  }

  /// Get all saved matches from history
  Future<List<MatchModel>> getMatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? rawJsonList = prefs.getStringList(_storageKey);

      if (rawJsonList == null || rawJsonList.isEmpty) {
        return [];
      }

      return rawJsonList.map((str) {
        Map<String, dynamic> jsonMap = jsonDecode(str);
        return MatchModel.fromJson(jsonMap);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete a match from history by ID
  Future<void> deleteMatch(String matchId) async {
    final prefs = await SharedPreferences.getInstance();
    List<MatchModel> currentMatches = await getMatchHistory();
    currentMatches.removeWhere((m) => m.id == matchId);

    List<String> rawJsonList =
        currentMatches.map((m) => jsonEncode(m.toJson())).toList();

    await prefs.setStringList(_storageKey, rawJsonList);
  }
}

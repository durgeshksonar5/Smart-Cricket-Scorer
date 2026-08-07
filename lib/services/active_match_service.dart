import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_model.dart';

class ActiveMatchService {
  static const String _activeMatchKey = 'cricket_active_match_v1';

  /// Save live active match to local storage immediately
  Future<void> saveActiveMatch(MatchModel match) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      match.lastSavedAt = DateTime.now();
      String rawJson = jsonEncode(match.toJson());
      await prefs.setString(_activeMatchKey, rawJson);
    } catch (e) {
      // Storage exception handler
    }
  }

  /// Load live active match if exists
  Future<MatchModel?> getActiveMatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? rawJson = prefs.getString(_activeMatchKey);
      if (rawJson == null || rawJson.trim().isEmpty) return null;

      Map<String, dynamic> jsonMap = jsonDecode(rawJson);
      return MatchModel.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  /// Clear active match when completed or abandoned
  Future<void> clearActiveMatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeMatchKey);
    } catch (e) {
      // Storage exception handler
    }
  }
}

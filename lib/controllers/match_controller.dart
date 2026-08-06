import 'package:flutter/foundation.dart';
import '../models/match_model.dart';
import '../models/toss_details.dart';
import '../services/toss_service.dart';
import '../services/match_history_service.dart';

class MatchController extends ChangeNotifier {
  final TossService _tossService = TossService();
  final MatchHistoryService _historyService = MatchHistoryService();

  MatchModel? _currentMatch;
  List<MatchModel> _history = [];
  bool _isLoadingHistory = false;

  // Toss flip UI state
  bool _isFlipping = false;
  String? _lastFlipResult;

  MatchModel? get currentMatch => _currentMatch;
  List<MatchModel> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isFlipping => _isFlipping;
  String? get lastFlipResult => _lastFlipResult;

  MatchController() {
    loadHistory();
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    _history = await _historyService.getMatchHistory();
    _isLoadingHistory = false;
    notifyListeners();
  }

  /// 1. Setup Screen Action
  void setupMatch({
    required String teamA,
    required String teamB,
    String matchName = '',
    String venue = '',
    required DateTime dateTime,
    required int totalOvers,
    int playersPerTeam = 11,
  }) {
    _currentMatch = MatchModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamA: teamA.trim().isEmpty ? 'Team A' : teamA.trim(),
      teamB: teamB.trim().isEmpty ? 'Team B' : teamB.trim(),
      matchName: matchName.trim(),
      venue: venue.trim(),
      dateTime: dateTime,
      totalOvers: totalOvers <= 0 ? 20 : totalOvers,
      playersPerTeam: playersPerTeam,
      battingTeam: teamA.trim().isEmpty ? 'Team A' : teamA.trim(),
      bowlingTeam: teamB.trim().isEmpty ? 'Team B' : teamB.trim(),
    );
    _lastFlipResult = null;
    _isFlipping = false;
    notifyListeners();
  }

  /// 2. Coin Toss Action
  Future<String> flipCoin() async {
    _isFlipping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 2800));

    _lastFlipResult = _tossService.flipCoin();
    _isFlipping = false;
    notifyListeners();
    return _lastFlipResult!;
  }

  /// 3 & 4. Toss Winner & Decision Action
  void finalizeTossDecision({
    required String callingTeam,
    required String tossCall, // "HEADS" or "TAILS"
    required String coinResult,
    required String tossDecision, // "Bat First" or "Bowl First"
  }) {
    if (_currentMatch == null) return;

    bool isTeamA = (_currentMatch!.teamA == callingTeam);
    String otherTeam = isTeamA ? _currentMatch!.teamB : _currentMatch!.teamA;

    TossDetails toss = _tossService.processTossResult(
      callingTeam: callingTeam,
      otherTeam: otherTeam,
      tossCall: tossCall,
      coinResult: coinResult,
      tossDecision: tossDecision,
    );

    _currentMatch!.tossDetails = toss;
    _currentMatch!.battingTeam = toss.battingTeam;
    _currentMatch!.bowlingTeam = toss.bowlingTeam;

    notifyListeners();
  }

  /// Ball Scoring Actions
  void recordBall({
    required int runs,
    bool isWicket = false,
    String? extraType, // 'WD', 'NB', 'B', 'LB'
  }) {
    if (_currentMatch == null || _currentMatch!.isCompleted) return;

    MatchModel match = _currentMatch!;
    int maxWickets = match.playersPerTeam - 1;
    int maxBalls = match.maxBalls;

    bool isLegalBall = true;
    int runsToAdd = runs;

    if (extraType == 'WD' || extraType == 'NB') {
      isLegalBall = false;
      runsToAdd += 1;
    }

    if (match.currentInnings == 1) {
      match.inn1Runs += runsToAdd;
      if (isWicket) match.inn1Wickets += 1;
      if (isLegalBall) match.inn1Balls += 1;

      String entry = _formatBallEntry(runs, isWicket, extraType);
      match.inn1BallHistory.add(entry);

      if (match.inn1Wickets >= maxWickets || match.inn1Balls >= maxBalls) {
        startSecondInnings();
      }
    } else {
      match.inn2Runs += runsToAdd;
      if (isWicket) match.inn2Wickets += 1;
      if (isLegalBall) match.inn2Balls += 1;

      String entry = _formatBallEntry(runs, isWicket, extraType);
      match.inn2BallHistory.add(entry);

      int target = match.inn1Runs + 1;

      if (match.inn2Runs >= target) {
        _completeMatch(
          winner: match.battingTeam,
          margin: '${maxWickets - match.inn2Wickets} Wickets',
        );
      } else if (match.inn2Wickets >= maxWickets || match.inn2Balls >= maxBalls) {
        if (match.inn2Runs == match.inn1Runs) {
          _completeMatch(winner: 'Match Tied', margin: 'Scores Tied');
        } else {
          _completeMatch(
            winner: match.bowlingTeam,
            margin: '${match.inn1Runs - match.inn2Runs} Runs',
          );
        }
      }
    }

    // Free Hit state management:
    // If No Ball -> Next ball is Free Hit!
    // If legal ball bowled on Free Hit -> Free Hit ends.
    // If Wide or No Ball on Free Hit -> Free Hit STAYS active!
    if (extraType == 'NB') {
      match.isFreeHit = true;
    } else if (isLegalBall) {
      match.isFreeHit = false;
    }

    notifyListeners();
  }

  String _formatBallEntry(int runs, bool isWicket, String? extraType) {
    if (isWicket) return 'W';
    if (extraType != null) {
      if (runs > 0) return '$runs$extraType';
      return extraType;
    }
    return runs.toString();
  }

  void startSecondInnings() {
    if (_currentMatch == null) return;
    _currentMatch!.currentInnings = 2;
    _currentMatch!.isFreeHit = false;
    String temp = _currentMatch!.battingTeam;
    _currentMatch!.battingTeam = _currentMatch!.bowlingTeam;
    _currentMatch!.bowlingTeam = temp;
    notifyListeners();
  }

  void forceEndInningsOrMatch() {
    if (_currentMatch == null) return;
    if (_currentMatch!.currentInnings == 1) {
      startSecondInnings();
    } else {
      int inn1 = _currentMatch!.inn1Runs;
      int inn2 = _currentMatch!.inn2Runs;
      if (inn2 > inn1) {
        _completeMatch(
          winner: _currentMatch!.battingTeam,
          margin: '${(_currentMatch!.playersPerTeam - 1) - _currentMatch!.inn2Wickets} Wickets',
        );
      } else if (inn1 > inn2) {
        _completeMatch(
          winner: _currentMatch!.bowlingTeam,
          margin: '${inn1 - inn2} Runs',
        );
      } else {
        _completeMatch(winner: 'Match Tied', margin: 'Scores Tied');
      }
    }
  }

  void _completeMatch({required String winner, required String margin}) {
    if (_currentMatch == null) return;
    _currentMatch!.isCompleted = true;
    _currentMatch!.winnerTeam = winner;
    _currentMatch!.winMargin = margin;

    _historyService.saveMatch(_currentMatch!);
    loadHistory();
  }

  void undoLastBall() {
    if (_currentMatch == null || _currentMatch!.isCompleted) return;
    MatchModel match = _currentMatch!;

    List<String> history = match.currentBallHistory;
    if (history.isEmpty) return;

    String lastEntry = history.removeLast();

    if (lastEntry == 'W') {
      if (match.currentInnings == 1) {
        match.inn1Wickets = (match.inn1Wickets - 1).clamp(0, 99);
        match.inn1Balls = (match.inn1Balls - 1).clamp(0, 999);
      } else {
        match.inn2Wickets = (match.inn2Wickets - 1).clamp(0, 99);
        match.inn2Balls = (match.inn2Balls - 1).clamp(0, 999);
      }
    } else if (lastEntry.endsWith('WD') || lastEntry.endsWith('NB')) {
      int extraRuns = 1;
      if (lastEntry.length > 2) {
        extraRuns += int.tryParse(lastEntry.substring(0, lastEntry.length - 2)) ?? 0;
      }
      if (match.currentInnings == 1) {
        match.inn1Runs = (match.inn1Runs - extraRuns).clamp(0, 9999);
      } else {
        match.inn2Runs = (match.inn2Runs - extraRuns).clamp(0, 9999);
      }
    } else {
      int runs = 0;
      if (lastEntry.endsWith('B') || lastEntry.endsWith('LB')) {
        runs = int.tryParse(lastEntry.substring(0, lastEntry.length - (lastEntry.endsWith('LB') ? 2 : 1))) ?? 0;
      } else {
        runs = int.tryParse(lastEntry) ?? 0;
      }
      if (match.currentInnings == 1) {
        match.inn1Runs = (match.inn1Runs - runs).clamp(0, 9999);
        match.inn1Balls = (match.inn1Balls - 1).clamp(0, 999);
      } else {
        match.inn2Runs = (match.inn2Runs - runs).clamp(0, 9999);
        match.inn2Balls = (match.inn2Balls - 1).clamp(0, 999);
      }
    }

    // Re-evaluate Free Hit status after undo
    if (history.isNotEmpty && history.last.contains('NB')) {
      match.isFreeHit = true;
    } else {
      match.isFreeHit = false;
    }

    notifyListeners();
  }

  Future<void> deleteHistoryItem(String matchId) async {
    await _historyService.deleteMatch(matchId);
    await loadHistory();
  }

  void resetCurrentMatch() {
    _currentMatch = null;
    _lastFlipResult = null;
    _isFlipping = false;
    notifyListeners();
  }

  void selectHistoricalMatch(MatchModel match) {
    _currentMatch = match;
    notifyListeners();
  }
}

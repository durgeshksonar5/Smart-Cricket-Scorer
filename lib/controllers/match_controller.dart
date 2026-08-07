import 'package:flutter/foundation.dart';
import '../models/match_model.dart';
import '../models/toss_details.dart';
import '../models/over_model.dart';
import '../models/ball_model.dart';
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
    String batTeam = teamA.trim().isEmpty ? 'Team A' : teamA.trim();
    String bowlTeam = teamB.trim().isEmpty ? 'Team B' : teamB.trim();

    _currentMatch = MatchModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamA: batTeam,
      teamB: bowlTeam,
      matchName: matchName.trim(),
      venue: venue.trim(),
      dateTime: dateTime,
      totalOvers: totalOvers <= 0 ? 20 : totalOvers,
      playersPerTeam: playersPerTeam,
      battingTeam: batTeam,
      bowlingTeam: bowlTeam,
      currentStriker: '$batTeam Opener 1',
      currentNonStriker: '$batTeam Opener 2',
      currentBowler: '$bowlTeam Bowler 1',
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
    _currentMatch!.currentStriker = '${toss.battingTeam} Opener 1';
    _currentMatch!.currentNonStriker = '${toss.battingTeam} Opener 2';
    _currentMatch!.currentBowler = '${toss.bowlingTeam} Bowler 1';

    notifyListeners();
  }

  /// Ball Scoring Actions
  void recordBall({
    required int runs,
    bool isWicket = false,
    String? extraType, // 'WD', 'NB', 'B', 'LB'
  }) {
    if (_currentMatch == null || _currentMatch!.isCompleted) return;
    if (_currentMatch!.isOverCompleteWaiting) return; // Wait for user to start next over

    MatchModel match = _currentMatch!;
    int maxWickets = match.playersPerTeam - 1;
    int maxBalls = match.maxBalls;

    bool isLegalBall = (extraType != 'WD' && extraType != 'NB');
    int runsToAdd = runs;

    if (extraType == 'WD' || extraType == 'NB') {
      runsToAdd += 1;
    }

    // Identify active over or create a new over
    List<OverModel> overs = match.currentOvers;
    if (overs.isEmpty || overs.last.isComplete) {
      overs.add(OverModel(
        overNumber: overs.length + 1,
        bowler: match.currentBowler,
      ));
    }
    OverModel activeOver = overs.last;

    int legalInOverBefore = activeOver.legalBallsCount;
    int currentOverNum = (match.currentBalls ~/ 6);
    int ballNumInOver = isLegalBall ? (legalInOverBefore + 1) : (legalInOverBefore == 0 ? 1 : legalInOverBefore);
    String ballFormatted = '$currentOverNum.$ballNumInOver${!isLegalBall ? (extraType == "WD" ? " Wd" : " Nb") : ""}';

    String entry = _formatBallEntry(runs, isWicket, extraType);

    // Update match cumulative totals
    if (match.currentInnings == 1) {
      match.inn1Runs += runsToAdd;
      if (isWicket) match.inn1Wickets += 1;
      if (isLegalBall) match.inn1Balls += 1;
      match.inn1BallHistory.add(entry);
    } else {
      match.inn2Runs += runsToAdd;
      if (isWicket) match.inn2Wickets += 1;
      if (isLegalBall) match.inn2Balls += 1;
      match.inn2BallHistory.add(entry);
    }

    // Create Ball object and append to active over
    BallModel ball = BallModel(
      overNumber: activeOver.overNumber,
      ballInOver: ballNumInOver,
      ballNumberFormatted: ballFormatted,
      runs: runsToAdd,
      displayResult: entry,
      isLegal: isLegalBall,
      isWicket: isWicket,
      extraType: extraType,
      striker: match.currentStriker,
      nonStriker: match.currentNonStriker,
      bowler: match.currentBowler,
      teamScoreSnapshot: '${match.currentRuns}/${match.currentWickets}',
    );
    activeOver.balls.add(ball);

    // Rotate strike on odd runs (if runs scored off bat/extras)
    if (runs % 2 != 0) {
      _swapStriker();
    }

    // Check if over is completed (6 legal deliveries)
    if (activeOver.isComplete) {
      _swapStriker(); // Automatic strike rotation at over end
      match.isOverCompleteWaiting = true;
    }

    // Free Hit state management
    if (extraType == 'NB') {
      match.isFreeHit = true;
    } else if (isLegalBall) {
      match.isFreeHit = false;
    }

    // Check match / innings completion
    if (match.currentInnings == 1) {
      if (match.inn1Wickets >= maxWickets || match.inn1Balls >= maxBalls) {
        match.isOverCompleteWaiting = false;
        startSecondInnings();
      }
    } else {
      int target = match.inn1Runs + 1;
      if (match.inn2Runs >= target) {
        match.isOverCompleteWaiting = false;
        _completeMatch(
          winner: match.battingTeam,
          margin: '${maxWickets - match.inn2Wickets} Wickets',
        );
      } else if (match.inn2Wickets >= maxWickets || match.inn2Balls >= maxBalls) {
        match.isOverCompleteWaiting = false;
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

    notifyListeners();
  }

  void _swapStriker() {
    if (_currentMatch == null) return;
    String temp = _currentMatch!.currentStriker;
    _currentMatch!.currentStriker = _currentMatch!.currentNonStriker;
    _currentMatch!.currentNonStriker = temp;
  }

  void startNextOver({String? nextBowler}) {
    if (_currentMatch == null) return;
    _currentMatch!.isOverCompleteWaiting = false;
    if (nextBowler != null && nextBowler.trim().isNotEmpty) {
      _currentMatch!.currentBowler = nextBowler.trim();
    }
    notifyListeners();
  }

  String _formatBallEntry(int runs, bool isWicket, String? extraType) {
    if (isWicket) return 'W';
    if (extraType == 'WD') {
      return runs > 0 ? '${runs + 1}WD' : 'WD';
    }
    if (extraType == 'NB') {
      return runs > 0 ? '${runs + 1}NB' : 'NB';
    }
    if (extraType == 'B' || extraType == 'LB') {
      return '$runs$extraType';
    }
    return runs.toString();
  }

  void startSecondInnings() {
    if (_currentMatch == null) return;
    _currentMatch!.currentInnings = 2;
    _currentMatch!.isFreeHit = false;
    _currentMatch!.isOverCompleteWaiting = false;
    String temp = _currentMatch!.battingTeam;
    _currentMatch!.battingTeam = _currentMatch!.bowlingTeam;
    _currentMatch!.bowlingTeam = temp;
    _currentMatch!.currentStriker = '${_currentMatch!.battingTeam} Opener 1';
    _currentMatch!.currentNonStriker = '${_currentMatch!.battingTeam} Opener 2';
    _currentMatch!.currentBowler = '${_currentMatch!.bowlingTeam} Bowler 1';
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

    // If over complete waiting was active, clear it first
    if (match.isOverCompleteWaiting) {
      match.isOverCompleteWaiting = false;
    }

    List<String> history = match.currentBallHistory;
    List<OverModel> overs = match.currentOvers;

    if (history.isEmpty && overs.isEmpty) return;

    // Remove last ball entry
    String lastEntry = history.isNotEmpty ? history.removeLast() : '';

    BallModel? lastBall;
    if (overs.isNotEmpty && overs.last.balls.isNotEmpty) {
      lastBall = overs.last.balls.removeLast();
      if (overs.last.balls.isEmpty && overs.length > 1) {
        overs.removeLast();
      }
    }

    // Revert match totals
    if (lastBall != null) {
      if (match.currentInnings == 1) {
        match.inn1Runs = (match.inn1Runs - lastBall.runs).clamp(0, 9999);
        if (lastBall.isWicket) match.inn1Wickets = (match.inn1Wickets - 1).clamp(0, 99);
        if (lastBall.isLegal) match.inn1Balls = (match.inn1Balls - 1).clamp(0, 999);
      } else {
        match.inn2Runs = (match.inn2Runs - lastBall.runs).clamp(0, 9999);
        if (lastBall.isWicket) match.inn2Wickets = (match.inn2Wickets - 1).clamp(0, 99);
        if (lastBall.isLegal) match.inn2Balls = (match.inn2Balls - 1).clamp(0, 999);
      }
      // Revert striker/non-striker
      match.currentStriker = lastBall.striker;
      match.currentNonStriker = lastBall.nonStriker;
      match.currentBowler = lastBall.bowler;
    } else if (lastEntry.isNotEmpty) {
      // Fallback for simple string history
      if (lastEntry == 'W') {
        if (match.currentInnings == 1) {
          match.inn1Wickets = (match.inn1Wickets - 1).clamp(0, 99);
          match.inn1Balls = (match.inn1Balls - 1).clamp(0, 999);
        } else {
          match.inn2Wickets = (match.inn2Wickets - 1).clamp(0, 99);
          match.inn2Balls = (match.inn2Balls - 1).clamp(0, 999);
        }
      } else if (lastEntry.contains('WD') || lastEntry.contains('NB')) {
        int extraRuns = 1;
        if (lastEntry.length > 2) {
          extraRuns += int.tryParse(lastEntry.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }
        if (match.currentInnings == 1) {
          match.inn1Runs = (match.inn1Runs - extraRuns).clamp(0, 9999);
        } else {
          match.inn2Runs = (match.inn2Runs - extraRuns).clamp(0, 9999);
        }
      } else {
        int runs = int.tryParse(lastEntry.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (match.currentInnings == 1) {
          match.inn1Runs = (match.inn1Runs - runs).clamp(0, 9999);
          match.inn1Balls = (match.inn1Balls - 1).clamp(0, 999);
        } else {
          match.inn2Runs = (match.inn2Runs - runs).clamp(0, 9999);
          match.inn2Balls = (match.inn2Balls - 1).clamp(0, 999);
        }
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


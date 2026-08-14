import 'package:flutter/widgets.dart';
import '../models/match_model.dart';
import '../models/toss_details.dart';
import '../models/over_model.dart';
import '../models/ball_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../services/toss_service.dart';
import '../services/match_history_service.dart';
import '../services/active_match_service.dart';
import '../services/team_service.dart';

class MatchController extends ChangeNotifier with WidgetsBindingObserver {
  final TossService _tossService = TossService();
  final MatchHistoryService _historyService = MatchHistoryService();
  final ActiveMatchService _activeMatchService = ActiveMatchService();
  final TeamService _teamService = TeamService();

  MatchModel? _currentMatch;
  List<MatchModel> _history = [];
  bool _isLoadingHistory = false;

  List<TeamModel> _savedTeams = [];
  Map<String, dynamic>? _lastUsedTeams;

  // Toss flip UI state
  bool _isFlipping = false;
  String? _lastFlipResult;

  MatchModel? get currentMatch => _currentMatch;
  List<MatchModel> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;
  List<TeamModel> get savedTeams => _savedTeams;
  Map<String, dynamic>? get lastUsedTeams => _lastUsedTeams;
  bool get isFlipping => _isFlipping;
  String? get lastFlipResult => _lastFlipResult;

  MatchController() {
    WidgetsBinding.instance.addObserver(this);
    loadHistory();
    loadSavedTeams();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _autoSaveActiveMatch();
    }
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    // 1. Check for active live match
    MatchModel? activeMatch = await _activeMatchService.getActiveMatch();
    if (activeMatch != null && !activeMatch.isCompleted && activeMatch.status != MatchStatus.abandoned) {
      _currentMatch = activeMatch;
    }

    // 2. Load completed matches history
    _history = await _historyService.getMatchHistory();
    _isLoadingHistory = false;
    notifyListeners();
  }

  Future<void> loadSavedTeams() async {
    _savedTeams = await _teamService.getSavedTeams();
    _lastUsedTeams = await _teamService.getLastUsedTeams();
    notifyListeners();
  }

  Future<void> saveTeam(TeamModel team) async {
    await _teamService.saveTeam(team);
    await loadSavedTeams();
  }

  Future<void> deleteTeam(String teamId) async {
    await _teamService.deleteTeam(teamId);
    await loadSavedTeams();
  }

  void _autoSaveActiveMatch() {
    if (_currentMatch != null && !_currentMatch!.isCompleted && _currentMatch!.status != MatchStatus.abandoned) {
      _activeMatchService.saveActiveMatch(_currentMatch!);
    }
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
    List<PlayerModel>? teamAPlayers,
    List<PlayerModel>? teamBPlayers,
  }) {
    String batTeam = teamA.trim().isEmpty ? 'Team A' : teamA.trim();
    String bowlTeam = teamB.trim().isEmpty ? 'Team B' : teamB.trim();

    List<PlayerModel> aPlayers = teamAPlayers ?? List.generate(playersPerTeam, (i) => PlayerModel(id: 'a_${i + 1}', name: '$batTeam Player ${i + 1}'));
    List<PlayerModel> bPlayers = teamBPlayers ?? List.generate(playersPerTeam, (i) => PlayerModel(id: 'b_${i + 1}', name: '$bowlTeam Player ${i + 1}'));

    _currentMatch = MatchModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamA: batTeam,
      teamB: bowlTeam,
      matchName: matchName.trim(),
      venue: venue.trim(),
      dateTime: dateTime,
      totalOvers: totalOvers <= 0 ? 20 : totalOvers,
      playersPerTeam: playersPerTeam,
      status: MatchStatus.tossPending,
      battingTeam: batTeam,
      bowlingTeam: bowlTeam,
      teamAPlayers: aPlayers,
      teamBPlayers: bPlayers,
      currentStriker: aPlayers.isNotEmpty ? aPlayers[0].name : '$batTeam Opener 1',
      currentStrikerId: aPlayers.isNotEmpty ? aPlayers[0].id : 'a_1',
      currentNonStriker: aPlayers.length > 1 ? aPlayers[1].name : '$batTeam Opener 2',
      currentNonStrikerId: aPlayers.length > 1 ? aPlayers[1].id : 'a_2',
      currentBowler: bPlayers.isNotEmpty ? bPlayers.last.name : '$bowlTeam Bowler 1',
      currentBowlerId: bPlayers.isNotEmpty ? bPlayers.last.id : 'b_11',
    );
    _lastFlipResult = null;
    _isFlipping = false;
    _autoSaveActiveMatch();

    // Persist last used teams & ensure roster persistence
    _teamService.saveLastUsedTeams(
      teamA: batTeam,
      teamAPlayers: aPlayers,
      teamB: bowlTeam,
      teamBPlayers: bPlayers,
      totalOvers: totalOvers <= 0 ? 20 : totalOvers,
      playersPerTeam: playersPerTeam,
    ).then((_) => loadSavedTeams());

    notifyListeners();
  }

  /// Quick Rematch directly from previous match model with 100% fresh statistics
  void startRematch(MatchModel match) {
    // Clone player rosters with fresh clean instances (preserving names and roles)
    List<PlayerModel> freshTeamAPlayers = match.teamAPlayers.map((p) => PlayerModel(
      id: 'a_${p.id}_${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: p.name,
      isCaptain: p.isCaptain,
      isWicketKeeper: p.isWicketKeeper,
    )).toList();

    List<PlayerModel> freshTeamBPlayers = match.teamBPlayers.map((p) => PlayerModel(
      id: 'b_${p.id}_${DateTime.now().millisecondsSinceEpoch % 10000}',
      name: p.name,
      isCaptain: p.isCaptain,
      isWicketKeeper: p.isWicketKeeper,
    )).toList();

    _currentMatch = MatchModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      teamA: match.teamA,
      teamB: match.teamB,
      matchName: match.matchName,
      venue: match.venue,
      dateTime: DateTime.now(),
      totalOvers: match.totalOvers,
      playersPerTeam: match.playersPerTeam,
      status: MatchStatus.tossPending,
      battingTeam: match.teamA,
      bowlingTeam: match.teamB,
      teamAPlayers: freshTeamAPlayers,
      teamBPlayers: freshTeamBPlayers,
      currentStriker: freshTeamAPlayers.isNotEmpty ? freshTeamAPlayers[0].name : '${match.teamA} Opener 1',
      currentStrikerId: freshTeamAPlayers.isNotEmpty ? freshTeamAPlayers[0].id : 'a_1',
      currentNonStriker: freshTeamAPlayers.length > 1 ? freshTeamAPlayers[1].name : '${match.teamA} Opener 2',
      currentNonStrikerId: freshTeamAPlayers.length > 1 ? freshTeamAPlayers[1].id : 'a_2',
      currentBowler: freshTeamBPlayers.isNotEmpty ? freshTeamBPlayers.last.name : '${match.teamB} Bowler 1',
      currentBowlerId: freshTeamBPlayers.isNotEmpty ? freshTeamBPlayers.last.id : 'b_11',
    );
    _lastFlipResult = null;
    _isFlipping = false;
    _autoSaveActiveMatch();
    notifyListeners();
  }

  /// Start match using persistent Saved Team models
  void startMatchWithSavedTeams({
    required TeamModel teamA,
    required TeamModel teamB,
    int totalOvers = 20,
    int playersPerTeam = 11,
  }) {
    List<PlayerModel> teamAPlayers = teamA.clonePlayersForMatch('a');
    List<PlayerModel> teamBPlayers = teamB.clonePlayersForMatch('b');

    setupMatch(
      teamA: teamA.name,
      teamB: teamB.name,
      dateTime: DateTime.now(),
      totalOvers: totalOvers,
      playersPerTeam: playersPerTeam,
      teamAPlayers: teamAPlayers,
      teamBPlayers: teamBPlayers,
    );
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
    required String tossCall,
    required String coinResult,
    required String tossDecision,
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
    _currentMatch!.status = MatchStatus.live;
    _currentMatch!.battingTeam = toss.battingTeam;
    _currentMatch!.bowlingTeam = toss.bowlingTeam;

    List<PlayerModel> batSquad = _currentMatch!.currentBattingSquad;
    List<PlayerModel> bowlSquad = _currentMatch!.currentBowlingSquad;

    _currentMatch!.currentStriker = batSquad.isNotEmpty ? batSquad[0].name : '${toss.battingTeam} Opener 1';
    _currentMatch!.currentStrikerId = batSquad.isNotEmpty ? batSquad[0].id : 'bat_1';
    _currentMatch!.currentNonStriker = batSquad.length > 1 ? batSquad[1].name : '${toss.battingTeam} Opener 2';
    _currentMatch!.currentNonStrikerId = batSquad.length > 1 ? batSquad[1].id : 'bat_2';
    _currentMatch!.currentBowler = bowlSquad.isNotEmpty ? bowlSquad.last.name : '${toss.bowlingTeam} Bowler 1';
    _currentMatch!.currentBowlerId = bowlSquad.isNotEmpty ? bowlSquad.last.id : 'bowl_1';

    _autoSaveActiveMatch();
    notifyListeners();
  }

  /// Ball Scoring Actions
  void recordBall({
    required int runs,
    bool isWicket = false,
    String? extraType,
    String? dismissalType,
    String? dismissedBatterId,
    String? fielderName,
  }) {
    if (_currentMatch == null || _currentMatch!.isCompleted) return;
    if (_currentMatch!.isOverCompleteWaiting) return;

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

    String outBatterId = dismissedBatterId ?? match.currentStrikerId;

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
      strikerId: match.currentStrikerId,
      nonStriker: match.currentNonStriker,
      nonStrikerId: match.currentNonStrikerId,
      bowler: match.currentBowler,
      bowlerId: match.currentBowlerId,
      teamScoreSnapshot: '${match.currentRuns}/${match.currentWickets}',
      dismissalType: isWicket ? (dismissalType ?? 'Bowled') : null,
      dismissedBatterId: isWicket ? outBatterId : null,
      fielderName: fielderName,
    );
    activeOver.balls.add(ball);

    // Strike Rotation
    if (runs % 2 != 0) {
      _swapStriker();
    }

    if (activeOver.isComplete) {
      _swapStriker();
      match.previousBowlerId = match.currentBowlerId;
      match.isOverCompleteWaiting = true;
    }

    if (extraType == 'NB') {
      match.isFreeHit = true;
    } else if (isLegalBall) {
      match.isFreeHit = false;
    }

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

    _autoSaveActiveMatch();
    notifyListeners();
  }

  void _swapStriker() {
    if (_currentMatch == null) return;
    String tempName = _currentMatch!.currentStriker;
    String tempId = _currentMatch!.currentStrikerId;

    _currentMatch!.currentStriker = _currentMatch!.currentNonStriker;
    _currentMatch!.currentStrikerId = _currentMatch!.currentNonStrikerId;

    _currentMatch!.currentNonStriker = tempName;
    _currentMatch!.currentNonStrikerId = tempId;
  }

  void setOpeningPlayers({
    required PlayerModel striker,
    required PlayerModel nonStriker,
    required PlayerModel bowler,
  }) {
    if (_currentMatch == null) return;
    _currentMatch!.currentStriker = striker.name;
    _currentMatch!.currentStrikerId = striker.id;
    _currentMatch!.currentNonStriker = nonStriker.name;
    _currentMatch!.currentNonStrikerId = nonStriker.id;
    _currentMatch!.currentBowler = bowler.name;
    _currentMatch!.currentBowlerId = bowler.id;
    _currentMatch!.isOpeningSelectionPending = false;
    _autoSaveActiveMatch();
    notifyListeners();
  }

  void startNextOver({PlayerModel? nextBowler}) {
    if (_currentMatch == null) return;
    _currentMatch!.isOverCompleteWaiting = false;
    if (nextBowler != null) {
      _currentMatch!.previousBowlerId = _currentMatch!.currentBowlerId;
      _currentMatch!.currentBowler = nextBowler.name;
      _currentMatch!.currentBowlerId = nextBowler.id;
    }
    _autoSaveActiveMatch();
    notifyListeners();
  }

  void updatePlayerName(String playerId, String newName) {
    if (_currentMatch == null || newName.trim().isEmpty) return;
    String name = newName.trim();

    for (var p in _currentMatch!.teamAPlayers) {
      if (p.id == playerId) p.name = name;
    }
    for (var p in _currentMatch!.teamBPlayers) {
      if (p.id == playerId) p.name = name;
    }

    if (_currentMatch!.currentStrikerId == playerId) _currentMatch!.currentStriker = name;
    if (_currentMatch!.currentNonStrikerId == playerId) _currentMatch!.currentNonStriker = name;
    if (_currentMatch!.currentBowlerId == playerId) _currentMatch!.currentBowler = name;

    _autoSaveActiveMatch();
    if (_currentMatch!.isCompleted) {
      _historyService.saveMatch(_currentMatch!);
    }
    notifyListeners();
  }

  void replaceBatter({required String dismissedBatterId, required PlayerModel incomingBatter}) {
    if (_currentMatch == null) return;
    if (_currentMatch!.currentStrikerId == dismissedBatterId) {
      _currentMatch!.currentStriker = incomingBatter.name;
      _currentMatch!.currentStrikerId = incomingBatter.id;
    } else if (_currentMatch!.currentNonStrikerId == dismissedBatterId) {
      _currentMatch!.currentNonStriker = incomingBatter.name;
      _currentMatch!.currentNonStrikerId = incomingBatter.id;
    }
    _autoSaveActiveMatch();
    notifyListeners();
  }

  void changeStriker(PlayerModel striker) {
    if (_currentMatch == null) return;
    _currentMatch!.currentStriker = striker.name;
    _currentMatch!.currentStrikerId = striker.id;
    _autoSaveActiveMatch();
    notifyListeners();
  }

  void changeNonStriker(PlayerModel nonStriker) {
    if (_currentMatch == null) return;
    _currentMatch!.currentNonStriker = nonStriker.name;
    _currentMatch!.currentNonStrikerId = nonStriker.id;
    _autoSaveActiveMatch();
    notifyListeners();
  }

  void changeBowler(PlayerModel bowler) {
    if (_currentMatch == null) return;
    _currentMatch!.currentBowler = bowler.name;
    _currentMatch!.currentBowlerId = bowler.id;
    _autoSaveActiveMatch();
    notifyListeners();
  }

  void swapStrikerAndNonStriker() {
    _swapStriker();
    _autoSaveActiveMatch();
    notifyListeners();
  }

  void setBowler(PlayerModel bowler) {
    if (_currentMatch == null) return;
    _currentMatch!.currentBowler = bowler.name;
    _currentMatch!.currentBowlerId = bowler.id;
    _autoSaveActiveMatch();
    notifyListeners();
  }

  /// Edit Past Ball & Recalculate Statistics
  void editBall({
    required int innings,
    required int overIndex,
    required int ballIndex,
    required int runs,
    bool isWicket = false,
    String? extraType,
    String? dismissalType,
    String? dismissedBatterId,
    String? fielderName,
  }) {
    if (_currentMatch == null || !_currentMatch!.isEditable) return;
    MatchModel match = _currentMatch!;

    List<OverModel> overs = (innings == 1) ? match.inn1Overs : match.inn2Overs;
    if (overIndex < 0 || overIndex >= overs.length) return;

    OverModel over = overs[overIndex];
    if (ballIndex < 0 || ballIndex >= over.balls.length) return;

    BallModel oldBall = over.balls[ballIndex];
    bool isLegalBall = (extraType != 'WD' && extraType != 'NB');
    int runsToAdd = runs;
    if (extraType == 'WD' || extraType == 'NB') runsToAdd += 1;

    String entry = _formatBallEntry(runs, isWicket, extraType);

    BallModel updatedBall = BallModel(
      overNumber: oldBall.overNumber,
      ballInOver: oldBall.ballInOver,
      ballNumberFormatted: oldBall.ballNumberFormatted,
      runs: runsToAdd,
      displayResult: entry,
      isLegal: isLegalBall,
      isWicket: isWicket,
      extraType: extraType,
      striker: oldBall.striker,
      strikerId: oldBall.strikerId,
      nonStriker: oldBall.nonStriker,
      nonStrikerId: oldBall.nonStrikerId,
      bowler: oldBall.bowler,
      bowlerId: oldBall.bowlerId,
      teamScoreSnapshot: oldBall.teamScoreSnapshot,
      dismissalType: isWicket ? (dismissalType ?? 'Bowled') : null,
      dismissedBatterId: isWicket ? (dismissedBatterId ?? oldBall.strikerId) : null,
      fielderName: fielderName,
    );

    over.balls[ballIndex] = updatedBall;

    // Recalculate complete innings totals
    _recalculateInningsTotals(match, innings);

    if (match.isCompleted) {
      _historyService.saveMatch(match);
    } else {
      _autoSaveActiveMatch();
    }
    notifyListeners();
  }

  void _recalculateInningsTotals(MatchModel match, int innings) {
    List<OverModel> overs = (innings == 1) ? match.inn1Overs : match.inn2Overs;

    int totalRuns = 0;
    int totalWickets = 0;
    int totalLegalBalls = 0;
    List<String> ballHistory = [];

    for (var o in overs) {
      for (var b in o.balls) {
        totalRuns += b.runs;
        if (b.isWicket) totalWickets += 1;
        if (b.isLegal) totalLegalBalls += 1;
        ballHistory.add(b.displayResult);
      }
    }

    if (innings == 1) {
      match.inn1Runs = totalRuns;
      match.inn1Wickets = totalWickets;
      match.inn1Balls = totalLegalBalls;
      match.inn1BallHistory = ballHistory;
    } else {
      match.inn2Runs = totalRuns;
      match.inn2Wickets = totalWickets;
      match.inn2Balls = totalLegalBalls;
      match.inn2BallHistory = ballHistory;
    }
  }

  String _formatBallEntry(int runs, bool isWicket, String? extraType) {
    if (isWicket) return 'W';
    if (extraType == 'WD') return runs > 0 ? '${runs + 1}WD' : 'WD';
    if (extraType == 'NB') return runs > 0 ? '${runs + 1}NB' : 'NB';
    if (extraType == 'B' || extraType == 'LB') return '$runs$extraType';
    return runs.toString();
  }

  void startSecondInnings() {
    if (_currentMatch == null) return;
    MatchModel match = _currentMatch!;
    match.currentInnings = 2;
    match.status = MatchStatus.inningsBreak;
    match.isFreeHit = false;
    match.isOverCompleteWaiting = false;
    match.isOpeningSelectionPending = true;
    match.previousBowlerId = null;

    String tempTeam = match.battingTeam;
    match.battingTeam = match.bowlingTeam;
    match.bowlingTeam = tempTeam;

    List<PlayerModel> batSquad = match.currentBattingSquad;
    List<PlayerModel> bowlSquad = match.currentBowlingSquad;

    match.currentStriker = batSquad.isNotEmpty ? batSquad[0].name : '${match.battingTeam} Opener 1';
    match.currentStrikerId = batSquad.isNotEmpty ? batSquad[0].id : 'b_1';
    match.currentNonStriker = batSquad.length > 1 ? batSquad[1].name : '${match.battingTeam} Opener 2';
    match.currentNonStrikerId = batSquad.length > 1 ? batSquad[1].id : 'b_2';
    match.currentBowler = bowlSquad.isNotEmpty ? bowlSquad.last.name : '${match.bowlingTeam} Bowler 1';
    match.currentBowlerId = bowlSquad.isNotEmpty ? bowlSquad.last.id : 'a_11';

    _autoSaveActiveMatch();
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
    MatchModel match = _currentMatch!;
    match.isCompleted = true;
    match.status = MatchStatus.completed;
    match.winnerTeam = winner;
    match.winMargin = margin;

    DateTime now = DateTime.now();
    match.matchCompletedAt = now;
    match.editExpiresAt = now.add(const Duration(hours: 2));

    _historyService.saveMatch(match);
    _activeMatchService.clearActiveMatch();
    loadHistory();
  }

  void abandonCurrentMatch() {
    if (_currentMatch == null) return;
    _currentMatch!.status = MatchStatus.abandoned;
    _activeMatchService.clearActiveMatch();
    resetCurrentMatch();
  }

  void undoLastBall() {
    if (_currentMatch == null || !_currentMatch!.isEditable) return;
    MatchModel match = _currentMatch!;

    if (match.isOverCompleteWaiting) {
      match.isOverCompleteWaiting = false;
    }

    List<String> history = match.currentBallHistory;
    List<OverModel> overs = match.currentOvers;

    if (history.isEmpty && overs.isEmpty) return;

    if (history.isNotEmpty) history.removeLast();

    BallModel? lastBall;
    if (overs.isNotEmpty && overs.last.balls.isNotEmpty) {
      lastBall = overs.last.balls.removeLast();
      if (overs.last.balls.isEmpty && overs.length > 1) {
        overs.removeLast();
      }
    }

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
      match.currentStriker = lastBall.striker;
      match.currentStrikerId = lastBall.strikerId;
      match.currentNonStriker = lastBall.nonStriker;
      match.currentNonStrikerId = lastBall.nonStrikerId;
      match.currentBowler = lastBall.bowler;
      match.currentBowlerId = lastBall.bowlerId;
    }

    if (history.isNotEmpty && history.last.contains('NB')) {
      match.isFreeHit = true;
    } else {
      match.isFreeHit = false;
    }

    _autoSaveActiveMatch();
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

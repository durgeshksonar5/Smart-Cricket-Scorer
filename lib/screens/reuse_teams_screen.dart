import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import 'coin_toss_screen.dart';

class ReuseTeamsScreen extends StatefulWidget {
  final MatchModel? sourceMatch;
  final String? teamAName;
  final String? teamBName;
  final List<PlayerModel>? teamAPlayers;
  final List<PlayerModel>? teamBPlayers;
  final int totalOvers;
  final int playersPerTeam;

  const ReuseTeamsScreen({
    super.key,
    this.sourceMatch,
    this.teamAName,
    this.teamBName,
    this.teamAPlayers,
    this.teamBPlayers,
    this.totalOvers = 20,
    this.playersPerTeam = 11,
  });

  @override
  State<ReuseTeamsScreen> createState() => _ReuseTeamsScreenState();
}

class _ReuseTeamsScreenState extends State<ReuseTeamsScreen> {
  late String _teamA;
  late String _teamB;
  late int _overs;
  late int _playersCount;
  late List<PlayerModel> _teamAPlayers;
  late List<PlayerModel> _teamBPlayers;
  bool _isEditingLineup = false;

  final List<TextEditingController> _teamACtrls = [];
  final List<TextEditingController> _teamBCtrls = [];

  @override
  void initState() {
    super.initState();
    final source = widget.sourceMatch;

    _teamA = widget.teamAName ?? source?.teamA ?? 'India';
    _teamB = widget.teamBName ?? source?.teamB ?? 'Australia';
    _overs = widget.totalOvers > 0 ? widget.totalOvers : (source?.totalOvers ?? 20);
    _playersCount = widget.playersPerTeam > 0 ? widget.playersPerTeam : (source?.playersPerTeam ?? 11);

    List<PlayerModel> rawA = widget.teamAPlayers ?? source?.teamAPlayers ?? [];
    List<PlayerModel> rawB = widget.teamBPlayers ?? source?.teamBPlayers ?? [];

    _teamAPlayers = rawA.isNotEmpty
        ? rawA.map((p) => PlayerModel(id: p.id, name: p.name, isCaptain: p.isCaptain, isWicketKeeper: p.isWicketKeeper)).toList()
        : List.generate(_playersCount, (i) => PlayerModel(id: 'a_${i + 1}', name: '$_teamA Player ${i + 1}'));

    _teamBPlayers = rawB.isNotEmpty
        ? rawB.map((p) => PlayerModel(id: p.id, name: p.name, isCaptain: p.isCaptain, isWicketKeeper: p.isWicketKeeper)).toList()
        : List.generate(_playersCount, (i) => PlayerModel(id: 'b_${i + 1}', name: '$_teamB Player ${i + 1}'));

    _syncCtrls();
  }

  void _syncCtrls() {
    for (var c in _teamACtrls) {
      c.dispose();
    }
    for (var c in _teamBCtrls) {
      c.dispose();
    }
    _teamACtrls.clear();
    _teamBCtrls.clear();

    for (var p in _teamAPlayers) {
      _teamACtrls.add(TextEditingController(text: p.name));
    }
    for (var p in _teamBPlayers) {
      _teamBCtrls.add(TextEditingController(text: p.name));
    }
  }

  @override
  void dispose() {
    for (var c in _teamACtrls) {
      c.dispose();
    }
    for (var c in _teamBCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onContinueToToss() {
    if (_isEditingLineup) {
      for (int i = 0; i < _teamAPlayers.length; i++) {
        _teamAPlayers[i].name = _teamACtrls[i].text.trim().isEmpty ? '$_teamA Player ${i + 1}' : _teamACtrls[i].text.trim();
      }
      for (int i = 0; i < _teamBPlayers.length; i++) {
        _teamBPlayers[i].name = _teamBCtrls[i].text.trim().isEmpty ? '$_teamB Player ${i + 1}' : _teamBCtrls[i].text.trim();
      }
    }

    final controller = Provider.of<MatchController>(context, listen: false);

    // Setup fresh match with 0 score and cloned players
    controller.setupMatch(
      teamA: _teamA,
      teamB: _teamB,
      dateTime: DateTime.now(),
      totalOvers: _overs,
      playersPerTeam: _playersCount,
      teamAPlayers: _teamAPlayers,
      teamBPlayers: _teamBPlayers,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CoinTossScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reuse Teams'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryEmerald.withValues(alpha: 0.2),
                            AppTheme.cardBg,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryEmerald, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.sync, color: AppTheme.coinGold, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'REUSE PREVIOUS TEAMS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryEmerald,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_teamA vs $_teamB',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_overs Overs  •  ${_teamAPlayers.length} Players/Team  •  Scores Start from 0',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Edit Lineup Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SQUAD LINEUPS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryEmerald,
                            letterSpacing: 1.1,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditingLineup = !_isEditingLineup;
                            });
                          },
                          icon: Icon(_isEditingLineup ? Icons.check : Icons.edit, size: 16, color: AppTheme.coinGold),
                          label: Text(
                            _isEditingLineup ? 'DONE EDITING' : 'EDIT LINEUP',
                            style: const TextStyle(color: AppTheme.coinGold, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Team A Squad Card
                    _buildSquadListCard(
                      teamName: _teamA,
                      players: _teamAPlayers,
                      ctrls: _teamACtrls,
                      isTeamA: true,
                    ),
                    const SizedBox(height: 16),

                    // Team B Squad Card
                    _buildSquadListCard(
                      teamName: _teamB,
                      players: _teamBPlayers,
                      ctrls: _teamBCtrls,
                      isTeamA: false,
                    ),
                    const SizedBox(height: 28),

                    // Continue to Toss Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _onContinueToToss,
                        icon: const Icon(Icons.monetization_on, color: Colors.black, size: 24),
                        label: const Text(
                          'CONTINUE TO TOSS',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadListCard({
    required String teamName,
    required List<PlayerModel> players,
    required List<TextEditingController> ctrls,
    required bool isTeamA,
  }) {
    Color accentColor = isTeamA ? AppTheme.primaryEmerald : AppTheme.coinGold;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E5749)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          '$teamName Players (${players.length})',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(
              children: List.generate(players.length, (i) {
                final p = players[i];
                if (_isEditingLineup && i < ctrls.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextFormField(
                      controller: ctrls[i],
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Player ${i + 1}',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.primaryEmerald, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        '${i + 1}. ${p.name}',
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      if (p.isCaptain) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.coinGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('C', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
                        ),
                      ],
                      if (p.isWicketKeeper) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('WK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

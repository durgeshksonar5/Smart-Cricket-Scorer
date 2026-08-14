import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
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
  bool _isCustomOvers = false;
  final TextEditingController _oversCustomCtrl = TextEditingController();

  late List<PlayerModel> _teamAPool;
  late List<PlayerModel> _teamBPool;
  final Set<String> _selectedTeamAPlayerIds = {};
  final Set<String> _selectedTeamBPlayerIds = {};

  final List<int> _commonOvers = [1, 2, 5, 6, 10, 15, 20, 25, 50];

  @override
  void initState() {
    super.initState();
    final source = widget.sourceMatch;

    _teamA = widget.teamAName ?? source?.teamA ?? 'India';
    _teamB = widget.teamBName ?? source?.teamB ?? 'Australia';
    _overs = widget.totalOvers > 0 ? widget.totalOvers : (source?.totalOvers ?? 20);
    _oversCustomCtrl.text = _overs.toString();
    _isCustomOvers = !_commonOvers.contains(_overs);

    _playersCount = widget.playersPerTeam > 0 ? widget.playersPerTeam : (source?.playersPerTeam ?? 11);

    List<PlayerModel> rawA = widget.teamAPlayers ?? source?.teamAPlayers ?? [];
    List<PlayerModel> rawB = widget.teamBPlayers ?? source?.teamBPlayers ?? [];

    _teamAPool = rawA.isNotEmpty
        ? rawA.map((p) => PlayerModel(id: p.id, name: p.name, isCaptain: p.isCaptain, isWicketKeeper: p.isWicketKeeper)).toList()
        : List.generate(_playersCount, (i) => PlayerModel(id: 'a_${i + 1}', name: '$_teamA Player ${i + 1}'));

    _teamBPool = rawB.isNotEmpty
        ? rawB.map((p) => PlayerModel(id: p.id, name: p.name, isCaptain: p.isCaptain, isWicketKeeper: p.isWicketKeeper)).toList()
        : List.generate(_playersCount, (i) => PlayerModel(id: 'b_${i + 1}', name: '$_teamB Player ${i + 1}'));

    // Automatically select the first N players from the pool up to _playersCount
    for (int i = 0; i < _teamAPool.length && i < _playersCount; i++) {
      _selectedTeamAPlayerIds.add(_teamAPool[i].id);
    }
    for (int i = 0; i < _teamBPool.length && i < _playersCount; i++) {
      _selectedTeamBPlayerIds.add(_teamBPool[i].id);
    }
  }

  @override
  void dispose() {
    _oversCustomCtrl.dispose();
    super.dispose();
  }

  void _updatePlayersCount(int newCount) {
    int clamped = newCount.clamp(2, 15);
    setState(() {
      _playersCount = clamped;

      // Adjust selection for Team A
      if (_selectedTeamAPlayerIds.length > _playersCount) {
        List<String> toKeep = _teamAPool.where((p) => _selectedTeamAPlayerIds.contains(p.id)).take(_playersCount).map((p) => p.id).toList();
        _selectedTeamAPlayerIds.clear();
        _selectedTeamAPlayerIds.addAll(toKeep);
      } else if (_selectedTeamAPlayerIds.length < _playersCount) {
        for (var p in _teamAPool) {
          if (_selectedTeamAPlayerIds.length >= _playersCount) break;
          _selectedTeamAPlayerIds.add(p.id);
        }
      }

      // Adjust selection for Team B
      if (_selectedTeamBPlayerIds.length > _playersCount) {
        List<String> toKeep = _teamBPool.where((p) => _selectedTeamBPlayerIds.contains(p.id)).take(_playersCount).map((p) => p.id).toList();
        _selectedTeamBPlayerIds.clear();
        _selectedTeamBPlayerIds.addAll(toKeep);
      } else if (_selectedTeamBPlayerIds.length < _playersCount) {
        for (var p in _teamBPool) {
          if (_selectedTeamBPlayerIds.length >= _playersCount) break;
          _selectedTeamBPlayerIds.add(p.id);
        }
      }
    });
  }

  void _togglePlayerSelection(bool isTeamA, PlayerModel player) {
    setState(() {
      Set<String> set = isTeamA ? _selectedTeamAPlayerIds : _selectedTeamBPlayerIds;
      if (set.contains(player.id)) {
        set.remove(player.id);
      } else {
        if (set.length < _playersCount) {
          set.add(player.id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only $_playersCount players can be selected. Uncheck another player first.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _showAddPlayerDialog(bool isTeamA) {
    String teamName = isTeamA ? _teamA : _teamB;
    final TextEditingController nameCtrl = TextEditingController();
    bool addToSavedTeam = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.person_add, color: AppTheme.primaryEmerald),
                  const SizedBox(width: 8),
                  Text('Add Player to $teamName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Player Name',
                      hintText: 'e.g. Sanju Samson',
                      prefixIcon: const Icon(Icons.badge, color: AppTheme.primaryEmerald),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Save Option:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 4),

                  InkWell(
                    onTap: () => setDialogState(() => addToSavedTeam = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: !addToSavedTeam ? AppTheme.primaryEmerald.withValues(alpha: 0.15) : AppTheme.cardBgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: !addToSavedTeam ? AppTheme.primaryEmerald : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(!addToSavedTeam ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: !addToSavedTeam ? AppTheme.primaryEmerald : AppTheme.textMuted),
                          const SizedBox(width: 8),
                          const Text('Add only to this match', style: TextStyle(fontSize: 13, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  InkWell(
                    onTap: () => setDialogState(() => addToSavedTeam = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: addToSavedTeam ? AppTheme.primaryEmerald.withValues(alpha: 0.15) : AppTheme.cardBgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: addToSavedTeam ? AppTheme.primaryEmerald : Colors.transparent),
                      ),
                      child: Row(
                        children: [
                          Icon(addToSavedTeam ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: addToSavedTeam ? AppTheme.primaryEmerald : AppTheme.textMuted),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Add to permanent saved team roster', style: TextStyle(fontSize: 13, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    Navigator.pop(dialogCtx);

                    String newId = 'p_${DateTime.now().millisecondsSinceEpoch}_${name.toLowerCase().replaceAll(' ', '_')}';
                    PlayerModel newPlayer = PlayerModel(id: newId, name: name);

                    setState(() {
                      if (isTeamA) {
                        _teamAPool.add(newPlayer);
                        if (_selectedTeamAPlayerIds.length < _playersCount) {
                          _selectedTeamAPlayerIds.add(newId);
                        }
                      } else {
                        _teamBPool.add(newPlayer);
                        if (_selectedTeamBPlayerIds.length < _playersCount) {
                          _selectedTeamBPlayerIds.add(newId);
                        }
                      }
                    });

                    // If user opted to add to permanent saved team roster
                    if (addToSavedTeam) {
                      final controller = Provider.of<MatchController>(context, listen: false);
                      TeamModel? existingTeam = controller.savedTeams.where((t) => t.name.toLowerCase() == teamName.toLowerCase()).isNotEmpty
                          ? controller.savedTeams.firstWhere((t) => t.name.toLowerCase() == teamName.toLowerCase())
                          : null;

                      if (existingTeam != null) {
                        existingTeam.players.add(newPlayer);
                        await controller.saveTeam(existingTeam);
                      } else {
                        TeamModel newTeam = TeamModel(
                          id: 'team_${DateTime.now().millisecondsSinceEpoch}',
                          name: teamName,
                          players: isTeamA ? List.from(_teamAPool) : List.from(_teamBPool),
                        );
                        await controller.saveTeam(newTeam);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Player "$name" added to saved roster for $teamName!'),
                            backgroundColor: AppTheme.primaryEmerald,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('ADD PLAYER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onContinueToToss() {
    // Validate overs
    if (_overs < 1 || _overs > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Overs must be between 1 and 50.')),
      );
      return;
    }

    // Validate player selections
    if (_selectedTeamAPlayerIds.length != _playersCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select exactly $_playersCount players for $_teamA (Selected: ${_selectedTeamAPlayerIds.length}).'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    if (_selectedTeamBPlayerIds.length != _playersCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select exactly $_playersCount players for $_teamB (Selected: ${_selectedTeamBPlayerIds.length}).'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    List<PlayerModel> finalTeamAPlayers = _teamAPool
        .where((p) => _selectedTeamAPlayerIds.contains(p.id))
        .map((p) => PlayerModel(
              id: 'a_${p.id}_${DateTime.now().millisecondsSinceEpoch % 10000}',
              name: p.name,
              isCaptain: p.isCaptain,
              isWicketKeeper: p.isWicketKeeper,
            ))
        .toList();

    List<PlayerModel> finalTeamBPlayers = _teamBPool
        .where((p) => _selectedTeamBPlayerIds.contains(p.id))
        .map((p) => PlayerModel(
              id: 'b_${p.id}_${DateTime.now().millisecondsSinceEpoch % 10000}',
              name: p.name,
              isCaptain: p.isCaptain,
              isWicketKeeper: p.isWicketKeeper,
            ))
        .toList();

    final controller = Provider.of<MatchController>(context, listen: false);

    // Setup fresh match with 0 score, 0 overs, and completely fresh statistics
    controller.setupMatch(
      teamA: _teamA,
      teamB: _teamB,
      dateTime: DateTime.now(),
      totalOvers: _overs,
      playersPerTeam: _playersCount,
      teamAPlayers: finalTeamAPlayers,
      teamBPlayers: finalTeamBPlayers,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CoinTossScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTeamAValid = _selectedTeamAPlayerIds.length == _playersCount;
    bool isTeamBValid = _selectedTeamBPlayerIds.length == _playersCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup & Team Reuse'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryEmerald.withValues(alpha: 0.2),
                            AppTheme.cardBg,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryEmerald, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.sync, color: AppTheme.coinGold, size: 32),
                          const SizedBox(height: 6),
                          const Text(
                            'REUSE PREVIOUS TEAMS',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald, letterSpacing: 1.1),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_teamA vs $_teamB',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Scores & Statistics will start from 0/0  •  Old matches are preserved',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // SECTION 1: MATCH CONFIGURATION (OVERS & PLAYERS COUNT)
                    _buildSectionHeader('MATCH CONFIGURATION', Icons.tune),
                    const SizedBox(height: 10),

                    // Overs Selection
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2E5749)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Number of Overs:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryEmerald),
                                ),
                                child: Text('$_overs Overs (${_overs * 6} Balls)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            children: [
                              ..._commonOvers.map((ov) {
                                bool isSel = !_isCustomOvers && _overs == ov;
                                return ChoiceChip(
                                  label: Text('$ov Ov'),
                                  selected: isSel,
                                  selectedColor: AppTheme.primaryEmerald,
                                  backgroundColor: AppTheme.cardBgLight,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: isSel ? Colors.black : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _isCustomOvers = false;
                                        _overs = ov;
                                        _oversCustomCtrl.text = ov.toString();
                                      });
                                    }
                                  },
                                );
                              }),
                              ChoiceChip(
                                label: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, size: 12, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Custom', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                selected: _isCustomOvers,
                                selectedColor: AppTheme.coinGold,
                                backgroundColor: AppTheme.cardBgLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: _isCustomOvers ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (selected) {
                                  setState(() => _isCustomOvers = true);
                                },
                              ),
                            ],
                          ),

                          if (_isCustomOvers) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  onPressed: () {
                                    int next = (_overs - 1).clamp(1, 50);
                                    setState(() {
                                      _overs = next;
                                      _oversCustomCtrl.text = next.toString();
                                    });
                                  },
                                  icon: const Icon(Icons.remove, color: AppTheme.coinGold),
                                  style: IconButton.styleFrom(backgroundColor: AppTheme.cardBgLight),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _oversCustomCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
                                    decoration: const InputDecoration(
                                      labelText: 'Custom Overs (1-50)',
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    ),
                                    onChanged: (val) {
                                      int? parsed = int.tryParse(val);
                                      if (parsed != null && parsed >= 1 && parsed <= 50) {
                                        setState(() => _overs = parsed);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filledTonal(
                                  onPressed: () {
                                    int next = (_overs + 1).clamp(1, 50);
                                    setState(() {
                                      _overs = next;
                                      _oversCustomCtrl.text = next.toString();
                                    });
                                  },
                                  icon: const Icon(Icons.add, color: AppTheme.coinGold),
                                  style: IconButton.styleFrom(backgroundColor: AppTheme.cardBgLight),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Players Per Team Stepper
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2E5749)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Players Per Team:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text('Select $_playersCount players below (2-15)', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton.filledTonal(
                                onPressed: () => _updatePlayersCount(_playersCount - 1),
                                icon: const Icon(Icons.remove, size: 16),
                                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(backgroundColor: AppTheme.cardBgLight),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '$_playersCount',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.coinGold),
                                ),
                              ),
                              IconButton.filledTonal(
                                onPressed: () => _updatePlayersCount(_playersCount + 1),
                                icon: const Icon(Icons.add, size: 16),
                                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                padding: EdgeInsets.zero,
                                style: IconButton.styleFrom(backgroundColor: AppTheme.cardBgLight),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: TEAM A SQUAD CHECKLIST
                    _buildSquadChecklistCard(
                      teamName: _teamA,
                      pool: _teamAPool,
                      selectedIds: _selectedTeamAPlayerIds,
                      isTeamA: true,
                    ),
                    const SizedBox(height: 16),

                    // SECTION 3: TEAM B SQUAD CHECKLIST
                    _buildSquadChecklistCard(
                      teamName: _teamB,
                      pool: _teamBPool,
                      selectedIds: _selectedTeamBPlayerIds,
                      isTeamA: false,
                    ),
                    const SizedBox(height: 28),

                    // CONTINUE TO TOSS BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: (isTeamAValid && isTeamBValid) ? _onContinueToToss : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isTeamAValid && isTeamBValid) ? AppTheme.primaryEmerald : Colors.grey.shade800,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.monetization_on, size: 22),
                        label: Text(
                          (isTeamAValid && isTeamBValid)
                              ? 'CONFIRM TEAMS & GO TO TOSS'
                              : 'SELECT EXACTLY $_playersCount PLAYERS PER TEAM',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppFooter(padding: EdgeInsets.only(top: 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildSquadChecklistCard({
    required String teamName,
    required List<PlayerModel> pool,
    required Set<String> selectedIds,
    required bool isTeamA,
  }) {
    int selectedCount = selectedIds.length;
    bool isValid = selectedCount == _playersCount;
    Color accentColor = isTeamA ? AppTheme.primaryEmerald : AppTheme.coinGold;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid ? accentColor.withValues(alpha: 0.8) : AppTheme.dangerRed.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Row(
          children: [
            Text(
              teamName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentColor),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isValid ? AppTheme.primaryEmerald.withValues(alpha: 0.2) : AppTheme.dangerRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isValid ? AppTheme.primaryEmerald : AppTheme.dangerRed),
              ),
              child: Text(
                '$selectedCount / $_playersCount',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isValid ? AppTheme.primaryEmerald : AppTheme.dangerRed,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          isValid ? 'Lineup ready ✓' : 'Select ${_playersCount - selectedCount} more player(s)',
          style: TextStyle(fontSize: 11, color: isValid ? AppTheme.primaryEmerald : AppTheme.dangerRed),
        ),
        trailing: TextButton.icon(
          onPressed: () => _showAddPlayerDialog(isTeamA),
          icon: const Icon(Icons.add, size: 16, color: AppTheme.coinGold),
          label: const Text('ADD PLAYER', style: TextStyle(color: AppTheme.coinGold, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Column(
              children: pool.asMap().entries.map((entry) {
                int i = entry.key;
                var player = entry.value;
                bool isSelected = selectedIds.contains(player.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.cardBgLight : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected ? Border.all(color: accentColor.withValues(alpha: 0.4)) : null,
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    activeColor: accentColor,
                    checkColor: Colors.black,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    dense: true,
                    title: Row(
                      children: [
                        Text(
                          '${i + 1}. ${player.name}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppTheme.textMuted,
                          ),
                        ),
                        if (player.isCaptain) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppTheme.coinGold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('C', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
                          ),
                        ],
                        if (player.isWicketKeeper) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: AppTheme.primaryEmerald.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('WK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                          ),
                        ],
                      ],
                    ),
                    onChanged: (_) => _togglePlayerSelection(isTeamA, player),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryEmerald, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primaryEmerald,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

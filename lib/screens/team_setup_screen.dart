import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import 'coin_toss_screen.dart';
import 'my_teams_screen.dart';
import 'reuse_teams_screen.dart';
import 'team_editor_screen.dart';

class TeamSetupScreen extends StatefulWidget {
  final TeamModel? preselectedTeamA;
  final TeamModel? preselectedTeamB;

  const TeamSetupScreen({
    super.key,
    this.preselectedTeamA,
    this.preselectedTeamB,
  });

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _battingTeamCtrl;
  late TextEditingController _bowlingTeamCtrl;
  final TextEditingController _oversCtrl = TextEditingController(text: '20');
  final TextEditingController _playersCtrl = TextEditingController(text: '11');

  final DateTime _currentDateTime = DateTime.now();
  int _selectedOvers = 20;
  bool _isCustomMode = false;

  List<TextEditingController> _teamAPlayerCtrls = [];
  List<TextEditingController> _teamBPlayerCtrls = [];

  TeamModel? _selectedSavedTeamA;
  TeamModel? _selectedSavedTeamB;

  @override
  void initState() {
    super.initState();
    _battingTeamCtrl = TextEditingController(text: widget.preselectedTeamA?.name ?? 'India');
    _bowlingTeamCtrl = TextEditingController(text: widget.preselectedTeamB?.name ?? 'Australia');

    _selectedSavedTeamA = widget.preselectedTeamA;
    _selectedSavedTeamB = widget.preselectedTeamB;

    int initialPlayers = widget.preselectedTeamA?.players.length ?? 11;
    _playersCtrl.text = initialPlayers.toString();

    _initSquadControllers(initialPlayers);

    // Apply preselected team players if provided
    if (widget.preselectedTeamA != null) {
      for (int i = 0; i < widget.preselectedTeamA!.players.length && i < _teamAPlayerCtrls.length; i++) {
        _teamAPlayerCtrls[i].text = widget.preselectedTeamA!.players[i].name;
      }
    }
    if (widget.preselectedTeamB != null) {
      for (int i = 0; i < widget.preselectedTeamB!.players.length && i < _teamBPlayerCtrls.length; i++) {
        _teamBPlayerCtrls[i].text = widget.preselectedTeamB!.players[i].name;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _matchSavedTeamsOnLaunch();
    });
  }

  void _matchSavedTeamsOnLaunch() {
    final controller = Provider.of<MatchController>(context, listen: false);
    final teams = controller.savedTeams;
    if (teams.isEmpty) return;

    if (_selectedSavedTeamA == null) {
      int idxA = teams.indexWhere((t) => t.name.toLowerCase() == _battingTeamCtrl.text.toLowerCase());
      if (idxA >= 0) {
        _applyTeamA(teams[idxA]);
      }
    }
    if (_selectedSavedTeamB == null) {
      int idxB = teams.indexWhere((t) => t.name.toLowerCase() == _bowlingTeamCtrl.text.toLowerCase());
      if (idxB >= 0) {
        _applyTeamB(teams[idxB]);
      }
    }
  }

  void _applyTeamA(TeamModel team) {
    setState(() {
      _selectedSavedTeamA = team;
      _battingTeamCtrl.text = team.name;
      _initSquadControllers(team.players.length);
      _playersCtrl.text = team.players.length.toString();
      for (int i = 0; i < team.players.length; i++) {
        _teamAPlayerCtrls[i].text = team.players[i].name;
      }
    });
  }

  void _applyTeamB(TeamModel team) {
    setState(() {
      _selectedSavedTeamB = team;
      _bowlingTeamCtrl.text = team.name;
      if (_teamBPlayerCtrls.length != team.players.length) {
        for (var c in _teamBPlayerCtrls) {
          c.dispose();
        }
        _teamBPlayerCtrls = List.generate(team.players.length, (i) => TextEditingController(text: team.players[i].name));
      } else {
        for (int i = 0; i < team.players.length; i++) {
          _teamBPlayerCtrls[i].text = team.players[i].name;
        }
      }
    });
  }

  void _initSquadControllers(int count) {
    for (var c in _teamAPlayerCtrls) {
      c.dispose();
    }
    for (var c in _teamBPlayerCtrls) {
      c.dispose();
    }
    _teamAPlayerCtrls = List.generate(count, (i) => TextEditingController(text: '${_battingTeamCtrl.text.trim()} Player ${i + 1}'));
    _teamBPlayerCtrls = List.generate(count, (i) => TextEditingController(text: '${_bowlingTeamCtrl.text.trim()} Player ${i + 1}'));
  }

  @override
  void dispose() {
    _battingTeamCtrl.dispose();
    _bowlingTeamCtrl.dispose();
    _oversCtrl.dispose();
    _playersCtrl.dispose();
    for (var c in _teamAPlayerCtrls) {
      c.dispose();
    }
    for (var c in _teamBPlayerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onProceedToToss() {
    if (!_formKey.currentState!.validate()) return;

    int overs = int.tryParse(_oversCtrl.text) ?? _selectedOvers;
    int players = int.tryParse(_playersCtrl.text) ?? 11;

    List<PlayerModel> teamAPlayers = List.generate(
      _teamAPlayerCtrls.length,
      (i) => PlayerModel(
        id: 'a_${i + 1}_${DateTime.now().millisecondsSinceEpoch % 10000}',
        name: _teamAPlayerCtrls[i].text.trim().isEmpty ? '${_battingTeamCtrl.text.trim()} Player ${i + 1}' : _teamAPlayerCtrls[i].text.trim(),
        isCaptain: _selectedSavedTeamA != null && i < _selectedSavedTeamA!.players.length ? _selectedSavedTeamA!.players[i].isCaptain : (i == 0),
        isWicketKeeper: _selectedSavedTeamA != null && i < _selectedSavedTeamA!.players.length ? _selectedSavedTeamA!.players[i].isWicketKeeper : (i == 4),
      ),
    );

    List<PlayerModel> teamBPlayers = List.generate(
      _teamBPlayerCtrls.length,
      (i) => PlayerModel(
        id: 'b_${i + 1}_${DateTime.now().millisecondsSinceEpoch % 10000}',
        name: _teamBPlayerCtrls[i].text.trim().isEmpty ? '${_bowlingTeamCtrl.text.trim()} Player ${i + 1}' : _teamBPlayerCtrls[i].text.trim(),
        isCaptain: _selectedSavedTeamB != null && i < _selectedSavedTeamB!.players.length ? _selectedSavedTeamB!.players[i].isCaptain : (i == 0),
        isWicketKeeper: _selectedSavedTeamB != null && i < _selectedSavedTeamB!.players.length ? _selectedSavedTeamB!.players[i].isWicketKeeper : (i == 4),
      ),
    );

    final controller = Provider.of<MatchController>(context, listen: false);
    controller.setupMatch(
      teamA: _battingTeamCtrl.text.trim(),
      teamB: _bowlingTeamCtrl.text.trim(),
      dateTime: _currentDateTime,
      totalOvers: overs,
      playersPerTeam: players,
      teamAPlayers: teamAPlayers,
      teamBPlayers: teamBPlayers,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CoinTossScreen()),
    );
  }

  void _updateOvers(int newOvers) {
    int clamped = newOvers.clamp(1, 50);
    setState(() {
      _selectedOvers = clamped;
      _oversCtrl.text = clamped.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    final savedTeams = controller.savedTeams;
    final lastUsed = controller.lastUsedTeams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline, color: AppTheme.primaryEmerald),
            tooltip: 'My Teams',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyTeamsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // QUICK REUSE BANNER (If previous teams available)
                      if (lastUsed != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF163228), Color(0xFF1F4235)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sync, color: AppTheme.coinGold, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Reuse Last Match: ${lastUsed["teamA"]} vs ${lastUsed["teamB"]}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  List<PlayerModel> pA = (lastUsed['teamAPlayers'] as List<dynamic>?)?.map((p) => PlayerModel.fromJson(p)).toList() ?? [];
                                  List<PlayerModel> pB = (lastUsed['teamBPlayers'] as List<dynamic>?)?.map((p) => PlayerModel.fromJson(p)).toList() ?? [];
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReuseTeamsScreen(
                                        teamAName: lastUsed['teamA'],
                                        teamBName: lastUsed['teamB'],
                                        teamAPlayers: pA,
                                        teamBPlayers: pB,
                                        totalOvers: lastUsed['totalOvers'] ?? 20,
                                        playersPerTeam: lastUsed['playersPerTeam'] ?? 11,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'REUSE',
                                  style: TextStyle(color: AppTheme.coinGold, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // TEAM A SELECTION
                      _buildSectionHeader('TEAM A (BATTING)', Icons.shield),
                      const SizedBox(height: 8),

                      if (savedTeams.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...savedTeams.map((team) {
                                bool isSel = _battingTeamCtrl.text.trim().toLowerCase() == team.name.trim().toLowerCase();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    label: Text(team.name),
                                    selected: isSel,
                                    selectedColor: AppTheme.primaryEmerald,
                                    backgroundColor: AppTheme.cardBgLight,
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    onSelected: (_) => _applyTeamA(team),
                                  ),
                                );
                              }),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.coinGold, size: 20),
                                tooltip: 'Create Team',
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamEditorScreen())),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      TextFormField(
                        controller: _battingTeamCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Team A Name',
                          prefixIcon: Icon(Icons.shield, color: AppTheme.primaryEmerald),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter Team A name' : null,
                        onChanged: (val) {
                          setState(() {
                            for (int i = 0; i < _teamAPlayerCtrls.length; i++) {
                              if (_teamAPlayerCtrls[i].text.contains('Player')) {
                                _teamAPlayerCtrls[i].text = '${val.trim()} Player ${i + 1}';
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 18),

                      // TEAM B SELECTION
                      _buildSectionHeader('TEAM B (BOWLING)', Icons.shield_outlined),
                      const SizedBox(height: 8),

                      if (savedTeams.isNotEmpty) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...savedTeams.map((team) {
                                bool isSel = _bowlingTeamCtrl.text.trim().toLowerCase() == team.name.trim().toLowerCase();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    label: Text(team.name),
                                    selected: isSel,
                                    selectedColor: AppTheme.coinGold,
                                    backgroundColor: AppTheme.cardBgLight,
                                    labelStyle: TextStyle(
                                      color: isSel ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    onSelected: (_) => _applyTeamB(team),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      TextFormField(
                        controller: _bowlingTeamCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Team B Name',
                          prefixIcon: Icon(Icons.shield_outlined, color: AppTheme.coinGold),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter Team B name';
                          if (val.trim().toLowerCase() == _battingTeamCtrl.text.trim().toLowerCase()) {
                            return 'Teams must be different';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {
                            for (int i = 0; i < _teamBPlayerCtrls.length; i++) {
                              if (_teamBPlayerCtrls[i].text.contains('Player')) {
                                _teamBPlayerCtrls[i].text = '${val.trim()} Player ${i + 1}';
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // MATCH CONFIGURATION
                      _buildSectionHeader('MATCH CONFIGURATION', Icons.tune),
                      const SizedBox(height: 14),

                      const Text(
                        'Select Overs (1 - 50):',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textLight),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          ...[1, 2, 5, 10, 20, 50].map((overs) {
                            bool isSelected = !_isCustomMode && _selectedOvers == overs;
                            return ChoiceChip(
                              label: Text('$overs Overs'),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryEmerald,
                              backgroundColor: AppTheme.cardBgLight,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _isCustomMode = false;
                                  });
                                  _updateOvers(overs);
                                }
                              },
                            );
                          }),
                          ChoiceChip(
                            label: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Custom'),
                              ],
                            ),
                            selected: _isCustomMode,
                            selectedColor: AppTheme.coinGold,
                            backgroundColor: AppTheme.cardBgLight,
                            labelStyle: TextStyle(
                              color: _isCustomMode ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _isCustomMode = true;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isCustomMode ? AppTheme.coinGold : const Color(0xFF2E5749),
                            width: _isCustomMode ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.timer, color: AppTheme.coinGold, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'CUSTOMIZE OVERS & PLAYERS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.coinGold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_selectedOvers * 6} Balls',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryEmerald,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                IconButton.filledTonal(
                                  onPressed: () {
                                    setState(() => _isCustomMode = true);
                                    _updateOvers(_selectedOvers - 1);
                                  },
                                  icon: const Icon(Icons.remove, color: AppTheme.coinGold),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.cardBgLight,
                                  ),
                                ),
                                const SizedBox(width: 8),

                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: _oversCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.coinGold,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Enter Overs (1-50)',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    ),
                                    onChanged: (val) {
                                      int? parsed = int.tryParse(val);
                                      if (parsed != null) {
                                        setState(() {
                                          _selectedOvers = parsed.clamp(1, 50);
                                          _isCustomMode = true;
                                        });
                                      }
                                    },
                                    validator: (val) {
                                      int? parsed = int.tryParse(val ?? '');
                                      if (parsed == null || parsed < 1 || parsed > 50) {
                                        return '1 - 50';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),

                                IconButton.filledTonal(
                                  onPressed: () {
                                    setState(() => _isCustomMode = true);
                                    _updateOvers(_selectedOvers + 1);
                                  },
                                  icon: const Icon(Icons.add, color: AppTheme.coinGold),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppTheme.cardBgLight,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _playersCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      labelText: 'Players/Team',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                    ),
                                    onChanged: (val) {
                                      int? parsed = int.tryParse(val);
                                      if (parsed != null && parsed >= 2 && parsed <= 11) {
                                        setState(() {
                                          _initSquadControllers(parsed);
                                        });
                                      }
                                    },
                                    validator: (val) {
                                      int? parsed = int.tryParse(val ?? '');
                                      if (parsed == null || parsed < 2 || parsed > 11) {
                                        return '2 - 11';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SQUAD PLAYERS MANAGEMENT
                      _buildSectionHeader('SQUAD PLAYERS MANAGEMENT', Icons.group),
                      const SizedBox(height: 12),

                      ExpansionTile(
                        title: Text(
                          '${_battingTeamCtrl.text.trim()} Squad (${_teamAPlayerCtrls.length} Players)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                        ),
                        children: List.generate(_teamAPlayerCtrls.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: TextFormField(
                              controller: _teamAPlayerCtrls[i],
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Batter ${i + 1}',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          );
                        }),
                      ),

                      ExpansionTile(
                        title: Text(
                          '${_bowlingTeamCtrl.text.trim()} Squad (${_teamBPlayerCtrls.length} Players)',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.coinGold),
                        ),
                        children: List.generate(_teamBPlayerCtrls.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: TextFormField(
                              controller: _teamBPlayerCtrls[i],
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Player ${i + 1}',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _onProceedToToss,
                          icon: const Icon(Icons.monetization_on, color: Colors.black),
                          label: const Text('PROCEED TO COIN TOSS'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryEmerald, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primaryEmerald,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

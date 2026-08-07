import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';
import '../widgets/made_by_footer.dart';
import 'coin_toss_screen.dart';

class TeamSetupScreen extends StatefulWidget {
  const TeamSetupScreen({super.key});

  @override
  State<TeamSetupScreen> createState() => _TeamSetupScreenState();
}

class _TeamSetupScreenState extends State<TeamSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _battingTeamCtrl = TextEditingController(text: 'India');
  final TextEditingController _bowlingTeamCtrl = TextEditingController(text: 'Australia');
  final TextEditingController _oversCtrl = TextEditingController(text: '20');
  final TextEditingController _playersCtrl = TextEditingController(text: '11');

  final DateTime _currentDateTime = DateTime.now();
  int _selectedOvers = 20;
  bool _isCustomMode = false;

  List<TextEditingController> _teamAPlayerCtrls = [];
  List<TextEditingController> _teamBPlayerCtrls = [];

  @override
  void initState() {
    super.initState();
    _initSquadControllers(11);
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
        id: 'a_${i + 1}',
        name: _teamAPlayerCtrls[i].text.trim().isEmpty ? '${_battingTeamCtrl.text.trim()} Player ${i + 1}' : _teamAPlayerCtrls[i].text.trim(),
      ),
    );

    List<PlayerModel> teamBPlayers = List.generate(
      _teamBPlayerCtrls.length,
      (i) => PlayerModel(
        id: 'b_${i + 1}',
        name: _teamBPlayerCtrls[i].text.trim().isEmpty ? '${_bowlingTeamCtrl.text.trim()} Player ${i + 1}' : _teamBPlayerCtrls[i].text.trim(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('TEAM NAMES SETUP', Icons.shield),
                const SizedBox(height: 12),

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
                const SizedBox(height: 14),

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

                // Player Rosters Accordions
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
                const SizedBox(height: 12),
                const MadeByFooter(),
              ],
            ),
          ),
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

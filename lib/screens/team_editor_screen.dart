import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/team_model.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';

class TeamEditorScreen extends StatefulWidget {
  final TeamModel? teamToEdit;

  const TeamEditorScreen({super.key, this.teamToEdit});

  @override
  State<TeamEditorScreen> createState() => _TeamEditorScreenState();
}

class _TeamEditorScreenState extends State<TeamEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _teamNameCtrl = TextEditingController();
  List<PlayerModel> _players = [];
  final List<TextEditingController> _playerCtrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.teamToEdit != null) {
      _teamNameCtrl.text = widget.teamToEdit!.name;
      _players = widget.teamToEdit!.players.map((p) => PlayerModel(
        id: p.id,
        name: p.name,
        isCaptain: p.isCaptain,
        isWicketKeeper: p.isWicketKeeper,
      )).toList();
    } else {
      _teamNameCtrl.text = 'New Team';
      _players = List.generate(
        11,
        (i) => PlayerModel(
          id: 'p_${i + 1}_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Player ${i + 1}',
          isCaptain: i == 0,
          isWicketKeeper: i == 4,
        ),
      );
    }
    _syncControllers();
  }

  void _syncControllers() {
    for (var c in _playerCtrls) {
      c.dispose();
    }
    _playerCtrls.clear();
    for (var p in _players) {
      _playerCtrls.add(TextEditingController(text: p.name));
    }
  }

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    for (var c in _playerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    setState(() {
      int nextNum = _players.length + 1;
      _players.add(PlayerModel(
        id: 'p_${nextNum}_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Player $nextNum',
      ));
      _playerCtrls.add(TextEditingController(text: 'Player $nextNum'));
    });
  }

  void _removePlayer(int index) {
    if (_players.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A team must have at least 2 players.')),
      );
      return;
    }
    setState(() {
      _players.removeAt(index);
      _playerCtrls[index].dispose();
      _playerCtrls.removeAt(index);
    });
  }

  void _toggleCaptain(int index) {
    setState(() {
      bool current = _players[index].isCaptain;
      for (var p in _players) {
        p.isCaptain = false;
      }
      _players[index].isCaptain = !current;
    });
  }

  void _toggleWicketKeeper(int index) {
    setState(() {
      bool current = _players[index].isWicketKeeper;
      for (var p in _players) {
        p.isWicketKeeper = false;
      }
      _players[index].isWicketKeeper = !current;
    });
  }

  void _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;

    for (int i = 0; i < _players.length; i++) {
      _players[i].name = _playerCtrls[i].text.trim().isEmpty ? 'Player ${i + 1}' : _playerCtrls[i].text.trim();
    }

    final controller = Provider.of<MatchController>(context, listen: false);

    TeamModel team = TeamModel(
      id: widget.teamToEdit?.id ?? 'team_${DateTime.now().millisecondsSinceEpoch}',
      name: _teamNameCtrl.text.trim(),
      players: _players,
      createdAt: widget.teamToEdit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await controller.saveTeam(team);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Team "${team.name}" saved successfully!'),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.teamToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Team Roster' : 'Create New Team'),
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
                      // Team Name Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TEAM DETAILS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryEmerald,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _teamNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Team Name',
                                prefixIcon: Icon(Icons.shield, color: AppTheme.primaryEmerald),
                              ),
                              validator: (val) => (val == null || val.trim().isEmpty) ? 'Enter team name' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Player Roster Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people, color: AppTheme.primaryEmerald, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'PLAYERS ROSTER (${_players.length})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryEmerald,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _addPlayer,
                            icon: const Icon(Icons.add, size: 18, color: AppTheme.coinGold),
                            label: const Text('ADD PLAYER', style: TextStyle(color: AppTheme.coinGold, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Players List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _players.length,
                        itemBuilder: (context, index) {
                          final p = _players[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF2E5749)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppTheme.cardBgLight,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _playerCtrls[index],
                                    style: const TextStyle(fontSize: 14, color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Player ${index + 1} Name',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // Captain toggle chip
                                InkWell(
                                  onTap: () => _toggleCaptain(index),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: p.isCaptain ? AppTheme.coinGold : AppTheme.cardBgLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'C',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: p.isCaptain ? Colors.black : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Wicketkeeper toggle chip
                                InkWell(
                                  onTap: () => _toggleWicketKeeper(index),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: p.isWicketKeeper ? AppTheme.primaryEmerald : AppTheme.cardBgLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'WK',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: p.isWicketKeeper ? Colors.black : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),

                                // Remove button
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.dangerRed, size: 20),
                                  onPressed: () => _removePlayer(index),
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Save Team Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _saveTeam,
                          icon: const Icon(Icons.save, color: Colors.black),
                          label: Text(
                            isEditing ? 'SAVE TEAM ROSTER' : 'CREATE TEAM ROSTER',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                          ),
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
}

import 'package:flutter/material.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';

class OpeningPlayersDialog extends StatefulWidget {
  final MatchModel match;
  final Function(PlayerModel striker, PlayerModel nonStriker, PlayerModel bowler) onConfirm;

  const OpeningPlayersDialog({
    super.key,
    required this.match,
    required this.onConfirm,
  });

  @override
  State<OpeningPlayersDialog> createState() => _OpeningPlayersDialogState();
}

class _OpeningPlayersDialogState extends State<OpeningPlayersDialog> {
  PlayerModel? _selectedStriker;
  PlayerModel? _selectedNonStriker;
  PlayerModel? _selectedBowler;

  @override
  void initState() {
    super.initState();
    // Default pre-select first 2 batters and first bowler if available
    List<PlayerModel> batSquad = widget.match.currentBattingSquad;
    List<PlayerModel> bowlSquad = widget.match.currentBowlingSquad;

    if (batSquad.isNotEmpty) {
      _selectedStriker = batSquad[0];
    }
    if (batSquad.length > 1) {
      _selectedNonStriker = batSquad[1];
    }
    if (bowlSquad.isNotEmpty) {
      _selectedBowler = bowlSquad.first;
    }
  }

  bool get _isValid =>
      _selectedStriker != null &&
      _selectedNonStriker != null &&
      _selectedBowler != null &&
      _selectedStriker!.id != _selectedNonStriker!.id;

  @override
  Widget build(BuildContext context) {
    List<PlayerModel> batSquad = widget.match.currentBattingSquad;
    List<PlayerModel> bowlSquad = widget.match.currentBowlingSquad;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryEmerald, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryEmerald),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sports_cricket, color: AppTheme.primaryEmerald, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'MATCH READY',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryEmerald,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Teams Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E5749)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Batting Team', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          widget.match.battingTeam,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald),
                        ),
                      ],
                    ),
                    const Icon(Icons.compare_arrows, color: AppTheme.coinGold),
                    Column(
                      children: [
                        const Text('Bowling Team', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          widget.match.bowlingTeam,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.coinGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SELECT OPENING BATTERS
              const Text(
                'SELECT OPENING BATTERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryEmerald,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              // Striker Dropdown Card
              _buildSelectorCard(
                label: '⭐ Striker',
                value: _selectedStriker,
                hint: 'Select Batsman',
                items: batSquad,
                isDisabled: (p) => p.id == _selectedNonStriker?.id,
                disabledMessage: 'Selected as Non-Striker',
                onChanged: (val) {
                  setState(() {
                    _selectedStriker = val;
                    if (_selectedNonStriker?.id == val?.id) {
                      _selectedNonStriker = null;
                    }
                  });
                },
                accentColor: AppTheme.primaryEmerald,
              ),
              const SizedBox(height: 10),

              // Non-Striker Dropdown Card
              _buildSelectorCard(
                label: '🏏 Non-Striker',
                value: _selectedNonStriker,
                hint: 'Select Batsman',
                items: batSquad.where((p) => p.id != _selectedStriker?.id).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedNonStriker = val;
                  });
                },
                accentColor: Colors.white,
              ),
              const SizedBox(height: 20),

              // SELECT BOWLER
              const Text(
                'SELECT BOWLER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.coinGold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              // Bowler Dropdown Card
              _buildSelectorCard(
                label: '🎯 Bowler',
                value: _selectedBowler,
                hint: 'Select Bowler',
                items: bowlSquad,
                onChanged: (val) {
                  setState(() {
                    _selectedBowler = val;
                  });
                },
                accentColor: AppTheme.coinGold,
              ),
              const SizedBox(height: 24),

              // Start Innings Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isValid
                      ? () {
                          widget.onConfirm(_selectedStriker!, _selectedNonStriker!, _selectedBowler!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    disabledBackgroundColor: AppTheme.cardBgLight,
                    foregroundColor: Colors.black,
                    disabledForegroundColor: AppTheme.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: _isValid ? 4 : 0,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: const Text(
                    'START INNINGS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorCard({
    required String label,
    required PlayerModel? value,
    required String hint,
    required List<PlayerModel> items,
    bool Function(PlayerModel)? isDisabled,
    String? disabledMessage,
    required ValueChanged<PlayerModel?> onChanged,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<PlayerModel>(
                isExpanded: true,
                value: value,
                hint: Text(hint, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                dropdownColor: AppTheme.cardBg,
                icon: const Icon(Icons.arrow_drop_down, color: AppTheme.coinGold),
                items: items.map((p) {
                  bool disabled = isDisabled != null && isDisabled(p);
                  return DropdownMenuItem<PlayerModel>(
                    value: disabled ? null : p,
                    enabled: !disabled,
                    child: Text(
                      '${p.name}${disabled ? " ($disabledMessage)" : ""}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: disabled ? Colors.grey : Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

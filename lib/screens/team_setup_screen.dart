import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../theme/app_theme.dart';
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

  @override
  void dispose() {
    _battingTeamCtrl.dispose();
    _bowlingTeamCtrl.dispose();
    _oversCtrl.dispose();
    _playersCtrl.dispose();
    super.dispose();
  }

  void _onProceedToToss() {
    if (!_formKey.currentState!.validate()) return;

    int overs = int.tryParse(_oversCtrl.text) ?? _selectedOvers;
    int players = int.tryParse(_playersCtrl.text) ?? 11;

    final controller = Provider.of<MatchController>(context, listen: false);
    controller.setupMatch(
      teamA: _battingTeamCtrl.text.trim(),
      teamB: _bowlingTeamCtrl.text.trim(),
      dateTime: _currentDateTime,
      totalOvers: overs,
      playersPerTeam: players,
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

                // Team A Input
                TextFormField(
                  controller: _battingTeamCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Team A Name',
                    prefixIcon: Icon(Icons.shield, color: AppTheme.primaryEmerald),
                  ),
                  validator: (val) =>
                      (val == null || val.trim().isEmpty) ? 'Enter Team A name' : null,
                ),
                const SizedBox(height: 14),

                // Team B Input
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
                ),
                const SizedBox(height: 24),

                _buildSectionHeader('MATCH CONFIGURATION', Icons.tune),
                const SizedBox(height: 14),

                // Select Overs Chips Header
                const Text(
                  'Select Overs (1 - 50):',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textLight),
                ),
                const SizedBox(height: 10),

                // Preset Chips + Custom Chip
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

                // Dedicated Customized Overs Section Card
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

                      // Over Number Entry Row with Quick +/- Buttons
                      Row(
                        children: [
                          // Decrement Button (-)
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

                          // Text Input for Direct Typing Over Number
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

                          // Increment Button (+)
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

                          // Players Per Team Input
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
                const SizedBox(height: 32),

                // Proceed Button
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

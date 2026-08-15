import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import 'scorecard_screen.dart';

class MatchConfirmationScreen extends StatelessWidget {
  const MatchConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    MatchModel? match = controller.currentMatch;

    if (match == null || match.tossDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Confirmation')),
        body: const Center(child: Text('No match details available.')),
      );
    }

    final toss = match.tossDetails!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Ready'),   
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Match Ready Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                          const Icon(Icons.check_circle_outline, color: AppTheme.primaryEmerald, size: 50),
                          const SizedBox(height: 8),
                          const Text(
                            'MATCH READY TO START',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryEmerald,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${match.teamA} vs ${match.teamB}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${match.totalOvers} Overs  •  ${match.playersPerTeam} Players/Team${match.venue.isNotEmpty ? "  •  📍 ${match.venue}" : ""}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Toss Summary Breakdown
                    _buildSectionTitle('🪙 TOSS SUMMARY'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2E5749)),
                      ),
                      child: Column(
                        children: [
                          _buildRow('Toss Winner', toss.tossWinnerTeam, isHighlight: true),
                          const Divider(color: Color(0xFF2E5749)),
                          _buildRow('Toss Decision', toss.tossDecision),
                          const Divider(color: Color(0xFF2E5749)),
                          _buildRow('Coin Call', '${toss.callingTeam} called ${toss.tossCall}'),
                          const Divider(color: Color(0xFF2E5749)),
                          _buildRow('Coin Result', toss.coinResult),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1st Innings Setup Card
                    _buildSectionTitle('🏏 1ST INNINGS ASSIGNMENT'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2E5749)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('🏏 Batting First', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                toss.battingTeam,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: AppTheme.coinGold),
                          Column(
                            children: [
                              const Text('⚾ Bowling First', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                toss.bowlingTeam,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.coinGold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Start Match Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ScorecardScreen()),
                          );
                        },
                        icon: const Icon(Icons.sports_cricket, color: Colors.black, size: 28),
                        label: const Text('START MATCH SCORECARD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryEmerald,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isHighlight ? AppTheme.coinGold : Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

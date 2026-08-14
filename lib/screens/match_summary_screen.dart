import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import 'home_screen.dart';
import 'team_setup_screen.dart';
import 'reuse_teams_screen.dart';
import 'scorecard_screen.dart';

class MatchSummaryScreen extends StatelessWidget {
  final MatchModel? historicalMatch;

  const MatchSummaryScreen({super.key, this.historicalMatch});

  void _showStartNextMatchOptions(BuildContext context, MatchModel match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'START NEW MATCH',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'How would you like to start?',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 22),

                // Option 1: USE PREVIOUS TEAMS
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReuseTeamsScreen(sourceMatch: match),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.sync, color: Colors.black, size: 22),
                    label: Text(
                      '🔄 USE PREVIOUS TEAMS (${match.teamA} vs ${match.teamB})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: CREATE NEW TEAMS
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final controller = Provider.of<MatchController>(context, listen: false);
                      controller.resetCurrentMatch();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TeamSetupScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.coinGold, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: AppTheme.coinGold, size: 22),
                    label: const Text(
                      '✨ CREATE NEW TEAMS',
                      style: TextStyle(color: AppTheme.coinGold, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    final match = historicalMatch ?? controller.currentMatch;

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Match Summary')),
        body: const Center(child: Text('No match summary available.')),
      );
    }

    String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(match.dateTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Summary'),
        automaticallyImplyLeading: historicalMatch != null,
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: AppTheme.primaryEmerald),
            tooltip: 'Home',
            onPressed: () {
              controller.resetCurrentMatch();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
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
                child: Column(
                  children: [
                    // MATCH COMPLETE BANNER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryEmerald.withValues(alpha: 0.25),
                            AppTheme.cardBg,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryEmerald, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryEmerald),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('MATCH COMPLETE 🏏', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald, letterSpacing: 1.1)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Icon(Icons.emoji_events, color: AppTheme.coinGold, size: 48),
                          const SizedBox(height: 6),
                          Text(
                            match.winnerTeam ?? 'Match Finished',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryEmerald,
                            ),
                          ),
                          if (match.winMargin != null && match.winMargin!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Won By ${match.winMargin}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.coinGold,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            '${match.teamA} vs ${match.teamB}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${match.totalOvers} Overs Match  •  📅 $formattedDate',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          if (match.venue.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('📍 ${match.venue}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Next Match Action Hero Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                controller.selectHistoricalMatch(match);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ScorecardScreen()),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.primaryEmerald),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.scoreboard, color: AppTheme.primaryEmerald, size: 20),
                              label: const Text('VIEW SCORECARD', style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => _showStartNextMatchOptions(context, match),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryEmerald,
                                foregroundColor: Colors.black,
                              ),
                              icon: const Icon(Icons.fast_forward, color: Colors.black, size: 20),
                              label: const Text('START NEXT MATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('TOSS DETAILS'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2E5749)),
                      ),
                      child: match.tossDetails == null
                          ? const Text('No Toss data recorded.', style: TextStyle(color: AppTheme.textMuted))
                          : Column(
                              children: [
                                _buildSummaryRow('Toss Winner', match.tossDetails!.tossWinnerTeam, isHighlight: true),
                                const Divider(color: Color(0xFF2E5749)),
                                _buildSummaryRow('Toss Decision', match.tossDetails!.tossDecision),
                                const Divider(color: Color(0xFF2E5749)),
                                _buildSummaryRow('Coin Call', '${match.tossDetails!.callingTeam} called ${match.tossDetails!.tossCall}'),
                                const Divider(color: Color(0xFF2E5749)),
                                _buildSummaryRow('Coin Result', match.tossDetails!.coinResult),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('INNINGS BREAKDOWN'),
                    const SizedBox(height: 10),
                    _buildInningsCard(
                      inningsLabel: '1st Innings: ${match.tossDetails?.tossDecision == "Bowl First" ? match.teamB : match.teamA}',
                      runs: match.inn1Runs,
                      wickets: match.inn1Wickets,
                      balls: match.inn1Balls,
                      totalOvers: match.totalOvers,
                    ),
                    const SizedBox(height: 12),
                    _buildInningsCard(
                      inningsLabel: '2nd Innings: ${match.tossDetails?.tossDecision == "Bowl First" ? match.teamA : match.teamB}',
                      runs: match.inn2Runs,
                      wickets: match.inn2Wickets,
                      balls: match.inn2Balls,
                      totalOvers: match.totalOvers,
                    ),
                    const SizedBox(height: 28),

                    // Bottom Navigation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              controller.resetCurrentMatch();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const HomeScreen()),
                                (route) => false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.primaryEmerald),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.home, color: AppTheme.primaryEmerald),
                            label: const Text('HOME', style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showStartNextMatchOptions(context, match),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.play_arrow, color: Colors.black),
                            label: const Text('NEXT MATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
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

  Widget _buildSummaryRow(String title, String value, {bool isHighlight = false}) {
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

  Widget _buildInningsCard({
    required String inningsLabel,
    required int runs,
    required int wickets,
    required int balls,
    required int totalOvers,
  }) {
    String oversFormatted = MatchModel.formatOvers(balls);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E5749)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(inningsLabel, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(
                '$runs / $wickets',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Overs', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(
                '$oversFormatted / $totalOvers.0',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'team_setup_screen.dart';

class MatchSummaryScreen extends StatelessWidget {
  final MatchModel? historicalMatch;

  const MatchSummaryScreen({super.key, this.historicalMatch});

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Winner Trophy Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
                ),
                child: Column(
                  children: [
                    const Icon(Icons.emoji_events, color: AppTheme.coinGold, size: 54),
                    const SizedBox(height: 8),
                    Text(
                      match.winnerTeam ?? 'Match Finished',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    if (match.winMargin != null && match.winMargin!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Won By ${match.winMargin}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.coinGold,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      '${match.teamA} vs ${match.teamB}',
                      style: const TextStyle(fontSize: 15, color: AppTheme.textMuted),
                    ),
                    if (match.venue.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('📍 ${match.venue}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                    const SizedBox(height: 2),
                    Text('📅 $formattedDate', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Feature 5 Requirement: Complete Toss Details Card
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

              // Scores Summary Card
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
              const SizedBox(height: 32),

              // Bottom Actions
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
                      onPressed: () {
                        controller.resetCurrentMatch();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const TeamSetupScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.add, color: Colors.black),
                      label: const Text('NEW MATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

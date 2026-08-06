import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../widgets/made_by_footer.dart';
import 'team_setup_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_cricket, color: AppTheme.primaryEmerald),
            SizedBox(width: 8),
            Text('Cricket Score Counter'),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF132620), Color(0xFF1F4035)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2E5749), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryEmerald,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sports_cricket, color: Colors.black, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready for a Match?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Fair coin toss & official scorecard',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          controller.resetCurrentMatch();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TeamSetupScreen()),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, color: Colors.black, size: 26),
                        label: const Text('START NEW MATCH'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Match History Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT MATCHES HISTORY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${controller.history.length} Matches',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Match History List
              Expanded(
                child: controller.isLoadingHistory
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald))
                    : controller.history.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: controller.history.length,
                            itemBuilder: (context, index) {
                              final match = controller.history[index];
                              return _buildMatchHistoryCard(context, controller, match);
                            },
                          ),
              ),
              const MadeByFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'No match history yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap "Start New Match" to begin!',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHistoryCard(
    BuildContext context,
    MatchController controller,
    MatchModel match,
  ) {
    String dateStr = DateFormat('dd MMM yyyy').format(match.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E5749)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Teams & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${match.teamA} vs ${match.teamB}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Toss summary badge
              if (match.tossDetails != null) ...[
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: AppTheme.coinGold, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Toss: ${match.tossDetails!.tossWinnerTeam} won (${match.tossDetails!.tossDecision})',
                        style: const TextStyle(fontSize: 12, color: AppTheme.coinGold, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Scores summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '1st: ${match.inn1Runs}/${match.inn1Wickets} (${MatchModel.formatOvers(match.inn1Balls)} ov)',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '2nd: ${match.inn2Runs}/${match.inn2Wickets} (${MatchModel.formatOvers(match.inn2Balls)} ov)',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Result & Delete action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🏆 ${match.winnerTeam} (${match.winMargin})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryEmerald,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20),
                    onPressed: () {
                      _confirmDelete(context, controller, match.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MatchController controller, String matchId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Delete Match Record?'),
        content: const Text('Are you sure you want to delete this match history entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteHistoryItem(matchId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

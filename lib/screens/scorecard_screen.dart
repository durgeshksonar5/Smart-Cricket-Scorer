import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import 'match_summary_screen.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  int _lastCompletedOverShown = 0;

  void _handleRecordBall(MatchController controller, {required int runs, bool isWicket = false, String? extraType}) {
    MatchModel? match = controller.currentMatch;
    if (match == null) return;

    int oldBalls = match.currentBalls;
    int oldInnings = match.currentInnings;

    controller.recordBall(runs: runs, isWicket: isWicket, extraType: extraType);

    MatchModel? updatedMatch = controller.currentMatch;
    if (updatedMatch == null || updatedMatch.isCompleted) return;

    // Check if a legal ball was completed, making currentBalls a multiple of 6 (and not 0)
    int newBalls = updatedMatch.currentBalls;
    if (updatedMatch.currentInnings == oldInnings &&
        newBalls > oldBalls &&
        newBalls % 6 == 0 &&
        newBalls > 0) {
      int overNumber = newBalls ~/ 6;
      if (overNumber != _lastCompletedOverShown) {
        _lastCompletedOverShown = overNumber;
        _showOverCompleteDialog(context, updatedMatch, overNumber);
      }
    }
  }

  void _showOverCompleteDialog(BuildContext context, MatchModel match, int overNumber) {
    int totalBalls = match.currentBalls;
    List<String> history = match.currentBallHistory;

    // Get last 6 entries or items in this over
    int entriesCount = history.length >= 6 ? 6 : history.length;
    List<String> overBalls = history.sublist(history.length - entriesCount);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.coinGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.coinGold.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'OVER COMPLETE!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.coinGold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Over $overNumber Finished',
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // Current Score Container
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBgLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2E5749)),
                ),
                child: Column(
                  children: [
                    Text(
                      match.battingTeam,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.currentRuns} / ${match.currentWickets}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '(${MatchModel.formatOvers(totalBalls)} Overs)',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Balls in this over timeline
              const Text(
                'This Over:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: overBalls.map((ball) => _buildOverBallBadge(ball)).toList(),
              ),
              const SizedBox(height: 24),

              // Start Next Over Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text(
                    'START NEXT OVER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverBallBadge(String ball) {
    Color bg = AppTheme.cardBgLight;
    Color fg = Colors.white;

    if (ball == 'W') {
      bg = AppTheme.dangerRed;
    } else if (ball == '4') {
      bg = AppTheme.primaryEmerald;
      fg = Colors.black;
    } else if (ball == '6') {
      bg = const Color(0xFFD500F9);
      fg = Colors.black;
    } else if (ball.contains('WD') || ball.contains('NB')) {
      bg = AppTheme.coinGold;
      fg = Colors.black;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2E5749)),
      ),
      child: Center(
        child: Text(
          ball,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    MatchModel? match = controller.currentMatch;

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Scorecard')),
        body: const Center(child: Text('No match in progress.')),
      );
    }

    if (match.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MatchSummaryScreen()),
        );
      });
    }

    int target = match.inn1Runs + 1;
    int runsNeeded = target - match.inn2Runs;
    int maxBalls = match.maxBalls;
    int ballsRemaining = maxBalls - match.inn2Balls;

    return Scaffold(
      appBar: AppBar(
        title: Text(match.matchName.isNotEmpty ? match.matchName : 'Live Scorecard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: AppTheme.dangerRed),
            tooltip: 'End Match',
            onPressed: () {
              _showEndMatchDialog(context, controller);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Match Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E5749)),
              ),
              child: Column(
                children: [
                  // Toss info banner
                  if (match.tossDetails != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.coinGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.coinGold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '🪙 Toss: ${match.tossDetails!.tossWinnerTeam} won & chose to ${match.tossDetails!.tossDecision}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.coinGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sports_cricket, color: AppTheme.primaryEmerald, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                match.battingTeam,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryEmerald,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Innings ${match.currentInnings}',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bowling: ${match.bowlingTeam}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      Text(
                        'Overs: ${match.totalOvers}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Score display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${match.currentRuns}/${match.currentWickets}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '(${match.currentOversFormatted} Ov)',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.coinGold,
                        ),
                      ),
                    ],
                  ),

                  // Target display for 2nd Innings
                  if (match.currentInnings == 2) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBgLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Target: $target  •  Need $runsNeeded runs in $ballsRemaining balls',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryEmerald,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Recent Ball History Timeline
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardBgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Recent: ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        children: match.currentBallHistory.isEmpty
                            ? [const Text('No balls bowled yet', style: TextStyle(fontSize: 12, color: AppTheme.textMuted))]
                            : match.currentBallHistory.map((ball) => _buildBallBadge(ball)).toList(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, color: AppTheme.coinGold, size: 20),
                    tooltip: 'Undo last ball',
                    onPressed: () => controller.undoLastBall(),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Scoring Action Control Buttons Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: Color(0xFF2E5749), width: 1)),
              ),
              child: Column(
                children: [
                  // Run buttons (0, 1, 2, 3, 4, 6)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [0, 1, 2, 3, 4, 6].map((runs) {
                      bool isBoundary = (runs == 4 || runs == 6);
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _handleRecordBall(controller, runs: runs),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: isBoundary
                                  ? (runs == 6 ? const Color(0xFFD500F9) : AppTheme.primaryEmerald)
                                  : AppTheme.cardBgLight,
                              foregroundColor: isBoundary ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              '$runs',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isBoundary ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Extras & Wicket buttons
                  Row(
                    children: [
                      _buildExtraButton('WD', 'Wide', () => _handleRecordBall(controller, runs: 0, extraType: 'WD')),
                      const SizedBox(width: 8),
                      _buildExtraButton('NB', 'No Ball', () => _handleRecordBall(controller, runs: 0, extraType: 'NB')),
                      const SizedBox(width: 8),
                      _buildExtraButton('B', 'Bye', () => _handleRecordBall(controller, runs: 1, extraType: 'B')),
                      const SizedBox(width: 8),
                      _buildExtraButton('LB', 'Leg Bye', () => _handleRecordBall(controller, runs: 1, extraType: 'LB')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Large Wicket Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRecordBall(controller, runs: 0, isWicket: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRed,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text('OUT / WICKET ☝️', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                  ),

                  // Manual Innings switch option
                  if (match.currentInnings == 1) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => controller.startSecondInnings(),
                      icon: const Icon(Icons.swap_calls, color: AppTheme.coinGold, size: 18),
                      label: const Text('End 1st Innings', style: TextStyle(color: AppTheme.coinGold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBallBadge(String ball) {
    Color bg = AppTheme.cardBg;
    Color fg = Colors.white;

    if (ball == 'W') {
      bg = AppTheme.dangerRed;
    } else if (ball == '4') {
      bg = AppTheme.primaryEmerald;
      fg = Colors.black;
    } else if (ball == '6') {
      bg = const Color(0xFFD500F9);
      fg = Colors.black;
    } else if (ball.contains('WD') || ball.contains('NB')) {
      bg = AppTheme.coinGold;
      fg = Colors.black;
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          ball,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg),
        ),
      ),
    );
  }

  Widget _buildExtraButton(String label, String tooltip, VoidCallback onTap) {
    return Expanded(
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: AppTheme.cardBgLight,
            side: const BorderSide(color: Color(0xFF2E5749)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.coinGold,
            ),
          ),
        ),
      ),
    );
  }

  void _showEndMatchDialog(BuildContext context, MatchController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('End Match Early?'),
        content: const Text('Do you want to end the match now and declare the current winner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.forceEndInningsOrMatch();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('End Match', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../widgets/made_by_footer.dart';
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

    // Check if 1st innings just completed and transitioned to 2nd innings
    if (oldInnings == 1 && updatedMatch.currentInnings == 2) {
      _showInningsCompleteDialog(context, updatedMatch);
      return;
    }

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

  void _handleWicketPressed(BuildContext context, MatchController controller) {
    MatchModel? match = controller.currentMatch;
    if (match == null) return;

    if (match.isFreeHit) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.coinGold),
              SizedBox(width: 8),
              Text('FREE HIT DISMISSAL', style: TextStyle(color: AppTheme.coinGold, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'On a Free Hit, batters CANNOT be Bowled, Caught, LBW, or Stumped!\n\nWas the batter RUN OUT?',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _handleRecordBall(controller, runs: 0, isWicket: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
              child: const Text('YES - RUN OUT ☝️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      _handleRecordBall(controller, runs: 0, isWicket: true);
    }
  }

  void _showExtraRunsDialog(BuildContext context, MatchController controller, String extraType) {
    String extraTitle = extraType == 'NB' ? 'NO BALL' : 'WIDE';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '⚾ $extraTitle + RUNS SCORED',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.coinGold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select runs scored off this $extraTitle (Includes +1 $extraTitle penalty${extraType == 'NB' ? ' & Next Ball is FREE HIT!' : ''})',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Run Choices Grid (0, 1, 2, 3, 4, 6)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildExtraRunChip(ctx, controller, extraType, 0, '0 Runs', '(1 Total Run)'),
                  _buildExtraRunChip(ctx, controller, extraType, 1, '+1 Run', '(2 Total Runs)'),
                  _buildExtraRunChip(ctx, controller, extraType, 2, '+2 Runs', '(3 Total Runs)'),
                  _buildExtraRunChip(ctx, controller, extraType, 3, '+3 Runs', '(4 Total Runs)'),
                  _buildExtraRunChip(ctx, controller, extraType, 4, '+4 FOUR! 🏏', '(5 Total Runs)', color: AppTheme.primaryEmerald),
                  _buildExtraRunChip(ctx, controller, extraType, 6, '+6 SIX! 🚀', '(7 Total Runs)', color: const Color(0xFFD500F9)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExtraRunChip(
    BuildContext ctx,
    MatchController controller,
    String extraType,
    int runs,
    String label,
    String sublabel, {
    Color? color,
  }) {
    return SizedBox(
      width: 145,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(ctx);
          _handleRecordBall(controller, runs: runs, extraType: extraType);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppTheme.cardBgLight,
          foregroundColor: color != null ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFF2E5749)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color != null ? Colors.black : Colors.white,
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: color != null ? Colors.black87 : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInningsCompleteDialog(BuildContext context, MatchModel match) {
    int target = match.inn1Runs + 1;
    String inn1BattingTeam = match.bowlingTeam; // In 2nd Innings, bowlingTeam was 1st innings batting team
    String inn2BattingTeam = match.battingTeam;

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
            border: Border.all(color: AppTheme.primaryEmerald, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏏', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                '1ST INNINGS COMPLETE!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryEmerald,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$inn1BattingTeam finished 1st Innings',
                style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // Final 1st Innings Score Card
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
                      inn1BattingTeam,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.inn1Runs} / ${match.inn1Wickets}',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald),
                    ),
                    Text(
                      '(${MatchModel.formatOvers(match.inn1Balls)} Overs)',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Target Container
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.coinGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.coinGold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TARGET FOR 2ND INNINGS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.coinGold, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$target Runs',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.coinGold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$inn2BattingTeam needs $target runs in ${match.totalOvers} overs',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Start 2nd Innings Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.sports_cricket, color: Colors.black),
                  label: const Text(
                    'START 2ND INNINGS',
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

  Map<String, dynamic> _getOverSummaryDetails(List<String> history) {
    List<String> overBalls = [];
    int legalCount = 0;

    for (int i = history.length - 1; i >= 0; i--) {
      String entry = history[i];
      overBalls.insert(0, entry);

      bool isExtra = entry.endsWith('WD') || entry.endsWith('NB');
      if (!isExtra) {
        legalCount++;
      }
      if (legalCount == 6) {
        break;
      }
    }

    int overRuns = 0;
    int overWickets = 0;

    for (String ball in overBalls) {
      if (ball == 'W') {
        overWickets++;
      } else if (ball.endsWith('WD') || ball.endsWith('NB')) {
        int extraRuns = 1;
        if (ball.length > 2) {
          extraRuns += int.tryParse(ball.substring(0, ball.length - 2)) ?? 0;
        }
        overRuns += extraRuns;
      } else {
        overRuns += int.tryParse(ball) ?? 0;
      }
    }

    return {
      'overBalls': overBalls,
      'overRuns': overRuns,
      'overWickets': overWickets,
    };
  }

  void _showOverCompleteDialog(BuildContext context, MatchModel match, int overNumber) {
    int totalBalls = match.currentBalls;
    Map<String, dynamic> overSummary = _getOverSummaryDetails(match.currentBallHistory);
    List<String> overBalls = overSummary['overBalls'] as List<String>;
    int overRuns = overSummary['overRuns'] as int;
    int overWickets = overSummary['overWickets'] as int;

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

              // Over Summary Stats Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.coinGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.coinGold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('OVER RUNS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
                        const SizedBox(height: 2),
                        Text('$overRuns Runs', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                    Container(height: 24, width: 1, color: AppTheme.coinGold.withValues(alpha: 0.3)),
                    Column(
                      children: [
                        const Text('OVER WICKETS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
                        const SizedBox(height: 2),
                        Text('$overWickets Wkts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
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

              // Balls in this over summary timeline
              Text(
                'Over Breakdown (${overBalls.length} Deliveries):',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: overBalls.map((ball) => _buildOverBallBadge(ball)).toList(),
                ),
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
    Color bg = const Color(0xFF2E5749);
    Color fg = Colors.white;
    Border? border;

    if (ball == 'W' || ball.contains('W')) {
      bg = AppTheme.dangerRed;
      fg = Colors.white;
    } else if (ball == '4' || ball == '4NB' || ball == '4WD') {
      bg = AppTheme.primaryEmerald;
      fg = Colors.black;
    } else if (ball == '6' || ball == '6NB' || ball == '6WD') {
      bg = const Color(0xFFD500F9);
      fg = Colors.black;
    } else if (ball.contains('WD') || ball.contains('NB')) {
      bg = AppTheme.coinGold;
      fg = Colors.black;
    } else {
      bg = const Color(0xFF253E35);
      fg = Colors.white;
      border = Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.4), width: 1);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 32,
      constraints: const BoxConstraints(minWidth: 34),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: border,
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

                  // Free Hit Banner Indicator
                  if (match.isFreeHit) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD500F9), Color(0xFFFF9100)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD500F9).withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '🔥 NEXT BALL IS FREE HIT! 🚀',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
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

                  // Extras buttons (Wide and No Ball)
                  Row(
                    children: [
                      _buildExtraButton('WD', 'Wide', () => _showExtraRunsDialog(context, controller, 'WD')),
                      const SizedBox(width: 12),
                      _buildExtraButton('NB', 'No Ball', () => _showExtraRunsDialog(context, controller, 'NB')),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Large Wicket Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleWicketPressed(context, controller),
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
                      onPressed: () {
                        controller.startSecondInnings();
                        if (controller.currentMatch != null) {
                          _showInningsCompleteDialog(context, controller.currentMatch!);
                        }
                      },
                      icon: const Icon(Icons.swap_calls, color: AppTheme.coinGold, size: 18),
                      label: const Text('End 1st Innings', style: TextStyle(color: AppTheme.coinGold)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const MadeByFooter(padding: EdgeInsets.zero),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBallBadge(String ball) {
    Color bg = const Color(0xFF253E35);
    Color fg = Colors.white;
    Border? border;

    if (ball == 'W' || ball.contains('W')) {
      bg = AppTheme.dangerRed;
      fg = Colors.white;
    } else if (ball == '4' || ball == '4NB' || ball == '4WD') {
      bg = AppTheme.primaryEmerald;
      fg = Colors.black;
    } else if (ball == '6' || ball == '6NB' || ball == '6WD') {
      bg = const Color(0xFFD500F9);
      fg = Colors.black;
    } else if (ball.contains('WD') || ball.contains('NB')) {
      bg = AppTheme.coinGold;
      fg = Colors.black;
    } else {
      bg = const Color(0xFF253E35);
      fg = Colors.white;
      border = Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.4), width: 1);
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 32,
      constraints: const BoxConstraints(minWidth: 34),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: (ball == 'W' || ball.contains('W'))
            ? [
                BoxShadow(
                  color: AppTheme.dangerRed.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          ball,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
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

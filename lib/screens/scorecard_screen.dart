import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../models/over_model.dart';
import '../models/ball_model.dart';
import '../theme/app_theme.dart';
import '../widgets/made_by_footer.dart';
import 'match_summary_screen.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> {
  bool _isOverCompleteDialogOpen = false;

  void _handleRecordBall(MatchController controller, {required int runs, bool isWicket = false, String? extraType}) {
    MatchModel? match = controller.currentMatch;
    if (match == null || match.isOverCompleteWaiting) return;

    int oldInnings = match.currentInnings;
    controller.recordBall(runs: runs, isWicket: isWicket, extraType: extraType);

    MatchModel? updatedMatch = controller.currentMatch;
    if (updatedMatch == null || updatedMatch.isCompleted) return;

    // Check 1st innings complete
    if (oldInnings == 1 && updatedMatch.currentInnings == 2) {
      _showInningsCompleteDialog(context, updatedMatch);
    }
  }

  void _handleWicketPressed(BuildContext context, MatchController controller) {
    MatchModel? match = controller.currentMatch;
    if (match == null || match.isOverCompleteWaiting) return;

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
    String inn1BattingTeam = match.bowlingTeam;
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
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.coinGold),
                    ),
                    Text(
                      '(${MatchModel.formatOvers(match.inn1Balls)} Overs)',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Target Card for 2nd Innings
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Text(
                      'TARGET FOR $inn2BattingTeam',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryEmerald,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$target RUNS',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'in ${match.totalOvers} Overs (${match.maxBalls} Balls)',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryEmerald,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
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

  void _showOverCompleteDialog(BuildContext context, MatchController controller, MatchModel match, OverModel over) {
    TextEditingController bowlerController = TextEditingController(text: match.currentBowler);
    double runRate = match.currentBalls > 0 ? (match.currentRuns / (match.currentBalls / 6)) : 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏏', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 4),
                const Text(
                  'OVER COMPLETE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.coinGold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Over ${over.overNumber} Finished',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),

                // Over Stats Grid
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
                      _buildOverStatItem('RUNS', '${over.totalRuns}'),
                      _buildOverStatItem('WICKETS', '${over.wickets}'),
                      _buildOverStatItem('4s', '${over.fours}'),
                      _buildOverStatItem('6s', '${over.sixes}'),
                      _buildOverStatItem('EXTRAS', '${over.extras}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Total Score & Run Rate Box
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2E5749)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(match.battingTeam, style: const TextStyle(fontSize: 13, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                          Text(
                            '${match.currentRuns}/${match.currentWickets}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('RUN RATE', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                          Text(
                            runRate.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Over Delivery Badges
                const Text('Deliveries:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: over.balls.map((b) => _buildBallBadgeWidget(b.displayResult, b)).toList(),
                ),
                const SizedBox(height: 14),

                // Next Bowler Selection Input
                TextField(
                  controller: bowlerController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Next Bowler Name',
                    labelStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.cardBgLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2E5749))),
                    prefixIcon: const Icon(Icons.sports_baseball_outlined, color: AppTheme.coinGold, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Start Next Over Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _isOverCompleteDialogOpen = false;
                      Navigator.pop(ctx);
                      controller.startNextOver(nextBowler: bowlerController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: const Text(
                      'START NEXT OVER',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
      ],
    );
  }

  void _showBallDetailsModal(BuildContext context, BallModel ball) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.coinGold, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Details (${ball.ballNumberFormatted})',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.coinGold,
                        ),
                      ),
                    ],
                  ),
                  _buildBallBadgeWidget(ball.displayResult),
                ],
              ),
              const Divider(color: Color(0xFF2E5749), height: 24),
              _buildDetailRow('Over Number', 'Over ${ball.overNumber}'),
              _buildDetailRow('Ball Number', 'Delivery ${ball.ballInOver}'),
              _buildDetailRow('Result', _getExpandedResultText(ball)),
              _buildDetailRow('Runs Scored', '${ball.runs} Runs'),
              _buildDetailRow('Striker (*)', ball.striker),
              _buildDetailRow('Non-Striker', ball.nonStriker),
              _buildDetailRow('Bowler', ball.bowler),
              _buildDetailRow('Team Score', ball.teamScoreSnapshot),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  String _getExpandedResultText(BallModel ball) {
    if (ball.isWicket) return 'WICKET ☝️';
    if (ball.extraType == 'WD') return 'WIDE (${ball.runs} Runs)';
    if (ball.extraType == 'NB') return 'NO BALL (${ball.runs} Runs)';
    if (ball.extraType == 'B') return 'BYE (${ball.runs} Runs)';
    if (ball.extraType == 'LB') return 'LEG BYE (${ball.runs} Runs)';
    if (ball.runs == 4) return 'FOUR 🏏';
    if (ball.runs == 6) return 'SIX 🚀';
    if (ball.runs == 0) return 'DOT BALL';
    return '${ball.runs} RUNS';
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

    // Auto-trigger Over Complete Dialog if waiting
    if (match.isOverCompleteWaiting && !_isOverCompleteDialogOpen) {
      _isOverCompleteDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OverModel? lastOver = match.currentOver;
        if (lastOver != null && mounted) {
          _showOverCompleteDialog(context, controller, match, lastOver);
        }
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
            onPressed: () => _showEndMatchDialog(context, controller),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Summary Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E5749)),
              ),
              child: Column(
                children: [
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
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.coinGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (match.isFreeHit) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD500F9), Color(0xFFFF9100)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '🔥 NEXT BALL IS FREE HIT! 🚀',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.sports_cricket, color: AppTheme.primaryEmerald, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                match.battingTeam,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                                overflow: TextOverflow.ellipsis,
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
                                'Inn ${match.currentInnings}',
                                style: const TextStyle(fontSize: 10, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Overs: ${match.totalOvers}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${match.currentRuns}/${match.currentWickets}',
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '(${match.currentOversFormatted} Ov)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.coinGold),
                      ),
                    ],
                  ),

                  if (match.currentInnings == 2) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBgLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Target: $target  •  Need $runsNeeded runs in $ballsRemaining balls',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Active Players Bar (Striker, Non-Striker, Bowler)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardBgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2E5749)),
              ),
              child: Row(
                children: [
                  const Text('🏏 ', style: TextStyle(fontSize: 11)),
                  Expanded(
                    flex: 6,
                    child: Text(
                      '*${match.currentStriker}  •  ${match.currentNonStriker}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryEmerald,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('⚽ ', style: TextStyle(fontSize: 11)),
                  Expanded(
                    flex: 4,
                    child: Text(
                      match.currentBowler,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.coinGold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),

            // Ball-by-Ball Timeline & Overs Section (Middle Scrollable)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E5749)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'BALL-BY-BALL HISTORY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.coinGold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Row(
                          children: [
                            const Text('Undo', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              icon: const Icon(Icons.undo, color: AppTheme.coinGold, size: 18),
                              tooltip: 'Undo last ball',
                              onPressed: () => controller.undoLastBall(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: match.currentOvers.isEmpty
                          ? const Center(
                              child: Text(
                                'No deliveries bowled yet.\nTap scoring buttons below to start!',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: match.currentOvers.length,
                              reverse: true,
                              itemBuilder: (ctx, index) {
                                OverModel over = match.currentOvers[match.currentOvers.length - 1 - index];
                                bool isCurrent = (index == 0);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isCurrent ? AppTheme.cardBg : const Color(0xFF1E342B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isCurrent ? AppTheme.primaryEmerald : const Color(0xFF254237),
                                      width: isCurrent ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'OVER ${over.overNumber}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                  color: isCurrent ? AppTheme.primaryEmerald : Colors.white,
                                                ),
                                              ),
                                              if (isCurrent) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'CURRENT',
                                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          Text(
                                            '${over.totalRuns} Runs  •  ${over.wickets} Wkts',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: over.balls.map((b) => _buildBallBadgeWidget(b.displayResult, b)).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Scoring Action Control Buttons Panel
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 48,
                          child: ElevatedButton(
                            onPressed: match.isOverCompleteWaiting ? null : () => _handleRecordBall(controller, runs: runs),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: isBoundary
                                  ? (runs == 6 ? const Color(0xFFD500F9) : AppTheme.primaryEmerald)
                                  : AppTheme.cardBgLight,
                              foregroundColor: isBoundary ? Colors.black : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              '$runs',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isBoundary ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Extras buttons (Wide and No Ball)
                  Row(
                    children: [
                      _buildExtraButton('WD', 'Wide', match.isOverCompleteWaiting ? null : () => _showExtraRunsDialog(context, controller, 'WD')),
                      const SizedBox(width: 10),
                      _buildExtraButton('NB', 'No Ball', match.isOverCompleteWaiting ? null : () => _showExtraRunsDialog(context, controller, 'NB')),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Wicket Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: match.isOverCompleteWaiting ? null : () => _handleWicketPressed(context, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRed,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.cancel, color: Colors.white, size: 20),
                      label: const Text('OUT / WICKET ☝️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                    ),
                  ),

                  if (match.currentInnings == 1) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () {
                        controller.startSecondInnings();
                        if (controller.currentMatch != null) {
                          _showInningsCompleteDialog(context, controller.currentMatch!);
                        }
                      },
                      icon: const Icon(Icons.swap_calls, color: AppTheme.coinGold, size: 16),
                      label: const Text('End 1st Innings', style: TextStyle(color: AppTheme.coinGold, fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 2),
                  const MadeByFooter(padding: EdgeInsets.zero),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBallBadgeWidget(String ballResult, [BallModel? ball]) {
    Color bg = const Color(0xFF253E35);
    Color fg = Colors.white;
    Border? border;

    if (ballResult == 'W' || ballResult.contains('W')) {
      bg = AppTheme.dangerRed;
      fg = Colors.white;
    } else if (ballResult == '4' || ballResult == '4NB' || ballResult == '4WD') {
      bg = AppTheme.primaryEmerald;
      fg = Colors.black;
    } else if (ballResult == '6' || ballResult == '6NB' || ballResult == '6WD') {
      bg = const Color(0xFFD500F9);
      fg = Colors.black;
    } else if (ballResult.contains('WD') || ballResult.contains('NB')) {
      bg = AppTheme.coinGold;
      fg = Colors.black;
    } else {
      bg = const Color(0xFF253E35);
      fg = Colors.white;
      border = Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.4), width: 1);
    }

    Widget badge = Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      height: 26,
      constraints: const BoxConstraints(minWidth: 26),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: border,
        boxShadow: (ballResult == 'W' || ballResult.contains('W'))
            ? [
                BoxShadow(
                  color: AppTheme.dangerRed.withValues(alpha: 0.4),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                )
              ]
            : null,
      ),
      child: Center(
        child: Text(
          ballResult,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: fg,
          ),
        ),
      ),
    );

    if (ball != null) {
      return GestureDetector(
        onTap: () => _showBallDetailsModal(context, ball),
        child: badge,
      );
    }

    return badge;
  }

  Widget _buildExtraButton(String label, String tooltip, VoidCallback? onTap) {
    return Expanded(
      child: SizedBox(
        height: 40,
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

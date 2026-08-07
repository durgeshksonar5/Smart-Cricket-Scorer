import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../models/over_model.dart';
import '../models/ball_model.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';
import '../widgets/made_by_footer.dart';
import 'match_summary_screen.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key});

  @override
  State<ScorecardScreen> createState() => _ScorecardScreenState();
}

class _ScorecardScreenState extends State<ScorecardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOverCompleteDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleRecordBall(MatchController controller, {
    required int runs,
    bool isWicket = false,
    String? extraType,
    String? dismissalType,
    String? dismissedBatterId,
    String? fielderName,
  }) {
    MatchModel? match = controller.currentMatch;
    if (match == null || match.isOverCompleteWaiting || match.isCompleted) return;

    int oldInnings = match.currentInnings;
    controller.recordBall(
      runs: runs,
      isWicket: isWicket,
      extraType: extraType,
      dismissalType: dismissalType,
      dismissedBatterId: dismissedBatterId,
      fielderName: fielderName,
    );

    MatchModel? updatedMatch = controller.currentMatch;
    if (updatedMatch == null || updatedMatch.isCompleted) return;

    if (oldInnings == 1 && updatedMatch.currentInnings == 2) {
      _showInningsCompleteDialog(context, updatedMatch);
    }
  }

  void _handleWicketPressed(BuildContext context, MatchController controller) {
    MatchModel? match = controller.currentMatch;
    if (match == null || match.isOverCompleteWaiting || match.isCompleted) return;

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
                _showDismissalSelectionModal(context, controller, isFreeHitRunOutOnly: true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
              child: const Text('YES - RUN OUT ☝️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      _showDismissalSelectionModal(context, controller);
    }
  }

  void _showDismissalSelectionModal(BuildContext context, MatchController controller, {bool isFreeHitRunOutOnly = false}) {
    MatchModel? match = controller.currentMatch;
    if (match == null) return;

    String selectedOutBatterId = match.currentStrikerId;
    String selectedDismissal = isFreeHitRunOutOnly ? 'Run Out' : 'Bowled';
    TextEditingController fielderCtrl = TextEditingController();

    List<String> dismissals = isFreeHitRunOutOnly
        ? ['Run Out', 'Retired Out']
        : ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'Hit Wicket', 'Retired Out'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cancel, color: AppTheme.dangerRed, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'WICKET DISMISSAL DETAILS',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.dangerRed, letterSpacing: 1.1),
                          ),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text('Select Dismissed Batter:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: Text('*${match.currentStriker} (Striker)'),
                          selected: selectedOutBatterId == match.currentStrikerId,
                          selectedColor: AppTheme.dangerRed,
                          onSelected: (val) => setModalState(() => selectedOutBatterId = match.currentStrikerId),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: Text('${match.currentNonStriker} (Non-Striker)'),
                          selected: selectedOutBatterId == match.currentNonStrikerId,
                          selectedColor: AppTheme.dangerRed,
                          onSelected: (val) => setModalState(() => selectedOutBatterId = match.currentNonStrikerId),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text('Select Dismissal Type:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dismissals.map((d) {
                      bool isSel = selectedDismissal == d;
                      return ChoiceChip(
                        label: Text(d),
                        selected: isSel,
                        selectedColor: AppTheme.primaryEmerald,
                        backgroundColor: AppTheme.cardBgLight,
                        labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                        onSelected: (val) => setModalState(() => selectedDismissal = d),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  if (selectedDismissal == 'Caught' || selectedDismissal == 'Run Out' || selectedDismissal == 'Stumped') ...[
                    TextField(
                      controller: fielderCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Fielder Name (Optional)',
                        labelStyle: const TextStyle(color: AppTheme.textMuted),
                        filled: true,
                        fillColor: AppTheme.cardBgLight,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleRecordBall(
                          controller,
                          runs: 0,
                          isWicket: true,
                          dismissalType: selectedDismissal,
                          dismissedBatterId: selectedOutBatterId,
                          fielderName: fielderCtrl.text.trim().isEmpty ? null : fielderCtrl.text.trim(),
                        );
                        _showSelectIncomingBatterModal(context, controller, selectedOutBatterId);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text('CONFIRM WICKET ☝️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSelectIncomingBatterModal(BuildContext context, MatchController controller, String dismissedBatterId) {
    MatchModel? match = controller.currentMatch;
    if (match == null) return;

    List<PlayerModel> squad = match.currentBattingSquad;
    List<BatterStats> stats = match.getBattingStatsForInnings(match.currentInnings);

    Set<String> dismissedIds = stats.where((s) => s.isOut).map((s) => s.playerId).toSet();
    dismissedIds.add(match.currentStrikerId);
    dismissedIds.add(match.currentNonStrikerId);

    List<PlayerModel> availableBatters = squad.where((p) => !dismissedIds.contains(p.id)).toList();

    if (availableBatters.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person_add, color: AppTheme.primaryEmerald, size: 22),
                  SizedBox(width: 8),
                  Text('SELECT INCOMING BATTER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableBatters.length,
                  itemBuilder: (context, index) {
                    PlayerModel player = availableBatters[index];
                    return Card(
                      color: AppTheme.cardBgLight,
                      child: ListTile(
                        leading: const Icon(Icons.sports_cricket, color: AppTheme.coinGold),
                        title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primaryEmerald),
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.replaceBatter(dismissedBatterId: dismissedBatterId, incomingBatter: player);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditPlayerNameModal(BuildContext context, MatchController controller, String playerId, String currentName) {
    MatchModel? match = controller.currentMatch;
    if (match != null && !match.isEditable) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔒 Editing locked for this match.')));
      return;
    }

    TextEditingController nameCtrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Row(
          children: [
            Icon(Icons.edit, color: AppTheme.coinGold),
            SizedBox(width: 8),
            Text('EDIT PLAYER NAME', style: TextStyle(color: AppTheme.coinGold, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Player Name', filled: true, fillColor: AppTheme.cardBgLight),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.updatePlayerName(playerId, nameCtrl.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald),
            child: const Text('SAVE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showExtraRunsDialog(BuildContext context, MatchController controller, String extraType) {
    String extraTitle = extraType == 'NB' ? 'NO BALL' : 'WIDE';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⚾ $extraTitle + RUNS SCORED', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.coinGold)),
              const SizedBox(height: 6),
              Text('Select runs scored off this $extraTitle (Includes +1 $extraTitle penalty)', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 20),
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

  Widget _buildExtraRunChip(BuildContext ctx, MatchController controller, String extraType, int runs, String label, String sublabel, {Color? color}) {
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
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color != null ? Colors.black : Colors.white)),
            Text(sublabel, style: TextStyle(fontSize: 10, color: color != null ? Colors.black87 : AppTheme.textMuted)),
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏏', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text('1ST INNINGS COMPLETE!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald)),
              const SizedBox(height: 4),
              Text('$inn1BattingTeam finished 1st Innings', style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text(inn1BattingTeam, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('${match.inn1Runs} / ${match.inn1Wickets}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.coinGold)),
                    Text('(${MatchModel.formatOvers(match.inn1Balls)} Overs)', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.primaryEmerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('TARGET FOR $inn2BattingTeam', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                    const SizedBox(height: 4),
                    Text('$target RUNS', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('in ${match.totalOvers} Overs (${match.maxBalls} Balls)', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.black),
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                  label: const Text('START 2ND INNINGS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOverCompleteDialog(BuildContext context, MatchController controller, MatchModel match, OverModel over) {
    List<PlayerModel> bowlingSquad = match.currentBowlingSquad;
    PlayerModel? selectedNextBowler = bowlingSquad.firstWhere(
      (b) => b.id != match.currentBowlerId,
      orElse: () => bowlingSquad.isNotEmpty ? bowlingSquad.first : PlayerModel(id: 'temp', name: match.currentBowler),
    );

    double runRate = match.currentBalls > 0 ? (match.currentRuns / (match.currentBalls / 6)) : 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.coinGold, width: 2),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏏', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 4),
                    const Text('OVER COMPLETE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.coinGold)),
                    Text('Over ${over.overNumber} Finished', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.coinGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
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

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(match.battingTeam, style: const TextStyle(fontSize: 13, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
                              Text('${match.currentRuns}/${match.currentWickets}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('RUN RATE', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                              Text(runRate.toStringAsFixed(2), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('SELECT NEXT BOWLER:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<PlayerModel>(
                      initialValue: selectedNextBowler,
                      dropdownColor: AppTheme.cardBgLight,
                      decoration: InputDecoration(filled: true, fillColor: AppTheme.cardBgLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      items: bowlingSquad.map((b) {
                        bool isConsecutive = (b.id == match.currentBowlerId && bowlingSquad.length > 1);
                        return DropdownMenuItem<PlayerModel>(
                          value: b,
                          enabled: !isConsecutive,
                          child: Text('${b.name}${isConsecutive ? " (Cannot bowl consecutive overs)" : ""}', style: TextStyle(color: isConsecutive ? Colors.grey : Colors.white, fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedNextBowler = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _isOverCompleteDialogOpen = false;
                          Navigator.pop(ctx);
                          controller.startNextOver(nextBowler: selectedNextBowler);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.black),
                        icon: const Icon(Icons.play_arrow, color: Colors.black),
                        label: const Text('START NEXT OVER', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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

  void _showBallDetailsModal(BuildContext context, MatchController controller, MatchModel match, BallModel ball, {int? overIndex, int? ballIndex}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
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
                      Text('Delivery Details (${ball.ballNumberFormatted})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
                    ],
                  ),
                  _buildBallBadgeWidget(ball.displayResult),
                ],
              ),
              const Divider(color: Color(0xFF2E5749), height: 20),
              _buildDetailRow('Over Number', 'Over ${ball.overNumber}'),
              _buildDetailRow('Ball Number', 'Delivery ${ball.ballInOver}'),
              _buildDetailRow('Result', _getExpandedResultText(ball)),
              _buildDetailRow('Runs Scored', '${ball.runs} Runs'),
              _buildDetailRow('Striker (*)', ball.striker),
              _buildDetailRow('Non-Striker', ball.nonStriker),
              _buildDetailRow('Bowler', ball.bowler),
              _buildDetailRow('Team Score', ball.teamScoreSnapshot),
              const SizedBox(height: 16),

              if (match.isEditable && overIndex != null && ballIndex != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEditBallModal(context, controller, match, match.currentInnings, overIndex, ballIndex, ball);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coinGold, foregroundColor: Colors.black),
                    icon: const Icon(Icons.edit, color: Colors.black),
                    label: const Text('EDIT THIS BALL RESULT ✏️', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
                  child: const Center(
                    child: Text('🔒 Editing locked for this match.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showEditBallModal(BuildContext context, MatchController controller, MatchModel match, int innings, int overIndex, int ballIndex, BallModel ball) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit, color: AppTheme.coinGold, size: 22),
                      SizedBox(width: 8),
                      Text('EDIT BALL RESULT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
                    ],
                  ),
                  Text('Current: ${ball.displayResult}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Select New Result:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...[0, 1, 2, 3, 4, 6].map((r) => ChoiceChip(
                    label: Text('$r Runs'),
                    selected: false,
                    backgroundColor: AppTheme.cardBgLight,
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      controller.editBall(innings: innings, overIndex: overIndex, ballIndex: ballIndex, runs: r);
                    },
                  )),
                  ChoiceChip(
                    label: const Text('Wide (WD)'),
                    selected: false,
                    backgroundColor: AppTheme.coinGold,
                    labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      controller.editBall(innings: innings, overIndex: overIndex, ballIndex: ballIndex, runs: 0, extraType: 'WD');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('No Ball (NB)'),
                    selected: false,
                    backgroundColor: AppTheme.coinGold,
                    labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      controller.editBall(innings: innings, overIndex: overIndex, ballIndex: ballIndex, runs: 0, extraType: 'NB');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Wicket (W)'),
                    selected: false,
                    backgroundColor: AppTheme.dangerRed,
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    onSelected: (_) {
                      Navigator.pop(ctx);
                      controller.editBall(innings: innings, overIndex: overIndex, ballIndex: ballIndex, runs: 0, isWicket: true, dismissalType: 'Bowled');
                    },
                  ),
                ],
              ),
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
    if (ball.isWicket) return 'WICKET (${ball.dismissalType ?? "Out"}) ☝️';
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

    if (match.isOverCompleteWaiting && !_isOverCompleteDialogOpen) {
      _isOverCompleteDialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OverModel? lastOver = match.currentOver;
        if (lastOver != null && mounted) {
          _showOverCompleteDialog(context, controller, match, lastOver);
        }
      });
    }

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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryEmerald,
          labelColor: AppTheme.primaryEmerald,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'SCORE'),
            Tab(text: 'BALLS'),
            Tab(text: 'BATTING'),
            Tab(text: 'BOWLING'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildScoreTab(context, controller, match),
            _buildBallsTab(context, controller, match),
            _buildBattingScorecardTab(context, match),
            _buildBowlingScorecardTab(context, match),
          ],
        ),
      ),
    );
  }

  // 1. SCORE TAB
  Widget _buildScoreTab(BuildContext context, MatchController controller, MatchModel match) {
    int target = match.inn1Runs + 1;
    int runsNeeded = target - match.inn2Runs;
    int maxBalls = match.maxBalls;
    int ballsRemaining = maxBalls - match.inn2Balls;
    bool isActionsEnabled = !match.isOverCompleteWaiting && match.isEditable && !match.isCompleted;

    List<BatterStats> currentBattingStats = match.getBattingStatsForInnings(match.currentInnings);
    BatterStats strikerStats = currentBattingStats.firstWhere(
      (s) => s.playerId == match.currentStrikerId,
      orElse: () => BatterStats(playerId: match.currentStrikerId, playerName: match.currentStriker, runs: 0, balls: 0, fours: 0, sixes: 0, isOut: false, dismissalInfo: 'not out', strikeRate: 0.0),
    );
    BatterStats nonStrikerStats = currentBattingStats.firstWhere(
      (s) => s.playerId == match.currentNonStrikerId,
      orElse: () => BatterStats(playerId: match.currentNonStrikerId, playerName: match.currentNonStriker, runs: 0, balls: 0, fours: 0, sixes: 0, isOut: false, dismissalInfo: 'not out', strikeRate: 0.0),
    );

    List<BowlerStats> currentBowlingStats = match.getBowlingStatsForInnings(match.currentInnings);
    BowlerStats bowlerStats = currentBowlingStats.firstWhere(
      (s) => s.playerId == match.currentBowlerId,
      orElse: () => BowlerStats(playerId: match.currentBowlerId, bowlerName: match.currentBowler, legalBalls: 0, runsConceded: 0, wickets: 0, maidens: 0, foursConceded: 0, sixesConceded: 0, dots: 0),
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Top Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E5749)),
            ),
            child: Column(
              children: [
                if (match.isFreeHit) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFD500F9), Color(0xFFFF9100)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('🔥 FREE HIT DELIVERED! 🚀', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(match.battingTeam, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald), overflow: TextOverflow.ellipsis),
                    ),
                    Text('Inn ${match.currentInnings} • Overs: ${match.totalOvers}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${match.currentRuns}/${match.currentWickets}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(width: 8),
                    Text('(${match.currentOversFormatted} Ov)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.coinGold)),
                  ],
                ),
                if (match.currentInnings == 2) ...[
                  const SizedBox(height: 2),
                  Text('Target: $target • Need $runsNeeded in $ballsRemaining balls', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                ],
              ],
            ),
          ),

          // Prominent Batters Display Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.3))),
            child: Column(
              children: [
                _buildBatterCardRow(context, controller, match.currentStrikerId, match.currentStriker, strikerStats, isStriker: true),
                const Divider(color: Color(0xFF2E5749), height: 12),
                _buildBatterCardRow(context, controller, match.currentNonStrikerId, match.currentNonStriker, nonStrikerStats, isStriker: false),
              ],
            ),
          ),

          // Prominent Bowler Display Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.coinGold.withValues(alpha: 0.3))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('⚽ ', style: TextStyle(fontSize: 13)),
                    Text(match.currentBowler, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      icon: const Icon(Icons.edit, size: 13, color: AppTheme.textMuted),
                      onPressed: () => _showEditPlayerNameModal(context, controller, match.currentBowlerId, match.currentBowler),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${bowlerStats.oversFormatted} Ov • ${bowlerStats.runsConceded} R • ${bowlerStats.wickets} W', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('ECO: ${bowlerStats.economy.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: AppTheme.coinGold, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // Recent Timeline Quick View
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Text('Recent: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: match.currentBallHistory.isEmpty
                          ? [const Text('No balls bowled yet', style: TextStyle(fontSize: 11, color: AppTheme.textMuted))]
                          : match.currentBallHistory.map((b) => _buildBallBadgeWidget(b)).toList(),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  icon: const Icon(Icons.undo, color: AppTheme.coinGold, size: 18),
                  tooltip: 'Undo',
                  onPressed: isActionsEnabled ? () => controller.undoLastBall() : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Scoring Controls Panel
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(top: BorderSide(color: Color(0xFF2E5749), width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [0, 1, 2, 3, 4, 6].map((runs) {
                    bool isBoundary = (runs == 4 || runs == 6);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isActionsEnabled ? () => _handleRecordBall(controller, runs: runs) : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: isBoundary ? (runs == 6 ? const Color(0xFFD500F9) : AppTheme.primaryEmerald) : AppTheme.cardBgLight,
                            foregroundColor: isBoundary ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('$runs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isBoundary ? Colors.black : Colors.white)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildExtraButton('WD', 'Wide', isActionsEnabled ? () => _showExtraRunsDialog(context, controller, 'WD') : null),
                    const SizedBox(width: 8),
                    _buildExtraButton('NB', 'No Ball', isActionsEnabled ? () => _showExtraRunsDialog(context, controller, 'NB') : null),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: isActionsEnabled ? () => _handleWicketPressed(context, controller) : null,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
                    icon: const Icon(Icons.cancel, color: Colors.white, size: 18),
                    label: const Text('OUT / WICKET ☝️', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 8),
                const MadeByFooter(padding: EdgeInsets.only(top: 4, bottom: 4)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildBatterCardRow(BuildContext context, MatchController controller, String playerId, String playerName, BatterStats stats, {required bool isStriker}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(isStriker ? '★ ' : '   ', style: const TextStyle(color: AppTheme.primaryEmerald, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(playerName, style: TextStyle(fontSize: 14, fontWeight: isStriker ? FontWeight.w900 : FontWeight.bold, color: isStriker ? AppTheme.primaryEmerald : Colors.white)),
            IconButton(
              icon: const Icon(Icons.edit, size: 14, color: AppTheme.textMuted),
              onPressed: () => _showEditPlayerNameModal(context, controller, playerId, playerName),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${stats.runs} (${stats.balls})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('${stats.fours}×4  ${stats.sixes}×6  SR ${stats.strikeRate.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          ],
        ),
      ],
    );
  }

  // 2. BALLS TAB
  Widget _buildBallsTab(BuildContext context, MatchController controller, MatchModel match) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COMPLETE BALL-BY-BALL HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.coinGold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Expanded(
            child: match.currentOvers.isEmpty
                ? const Center(child: Text('No deliveries bowled yet.', style: TextStyle(color: AppTheme.textMuted)))
                : ListView.builder(
                    itemCount: match.currentOvers.length,
                    reverse: true,
                    itemBuilder: (ctx, index) {
                      int realOverIdx = match.currentOvers.length - 1 - index;
                      OverModel over = match.currentOvers[realOverIdx];
                      bool isCurrent = (index == 0);
                      return Card(
                        color: isCurrent ? AppTheme.cardBg : const Color(0xFF1E342B),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('OVER ${over.overNumber} ${isCurrent ? " (CURRENT)" : ""}', style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? AppTheme.primaryEmerald : Colors.white)),
                                  Text('Over Runs: ${over.totalRuns} (${over.wickets} Wkts)', style: const TextStyle(color: AppTheme.coinGold, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(over.balls.length, (bIdx) {
                                    BallModel b = over.balls[bIdx];
                                    return _buildBallBadgeWidget(
                                      b.displayResult,
                                      ball: b,
                                      controller: controller,
                                      match: match,
                                      overIndex: realOverIdx,
                                      ballIndex: bIdx,
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 3. BATTING TAB
  Widget _buildBattingScorecardTab(BuildContext context, MatchModel match) {
    List<BatterStats> statsList = match.getBattingStatsForInnings(match.currentInnings);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BATTING SCORECARD - ${match.battingTeam.toUpperCase()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2.0),
              2: FlexColumnWidth(0.8),
              3: FlexColumnWidth(0.8),
              4: FlexColumnWidth(0.8),
              5: FlexColumnWidth(0.8),
              6: FlexColumnWidth(1.2),
            },
            border: TableBorder.all(color: const Color(0xFF2E5749)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.cardBgLight),
                children: ['Player', 'Dismissal', 'R', 'B', '4s', '6s', 'SR'].map((h) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.coinGold)),
                )).toList(),
              ),
              ...statsList.map((s) {
                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(s.playerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(s.dismissalInfo, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text('${s.runs}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text('${s.balls}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text('${s.fours}', style: const TextStyle(fontSize: 11, color: Colors.white))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text('${s.sixes}', style: const TextStyle(fontSize: 11, color: Colors.white))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(s.strikeRate.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: AppTheme.coinGold))),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // 4. BOWLING TAB
  Widget _buildBowlingScorecardTab(BuildContext context, MatchModel match) {
    List<BowlerStats> statsList = match.getBowlingStatsForInnings(match.currentInnings);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BOWLING SCORECARD - ${match.bowlingTeam.toUpperCase()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.coinGold, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(0.8),
              3: FlexColumnWidth(0.8),
              4: FlexColumnWidth(0.8),
              5: FlexColumnWidth(1.2),
            },
            border: TableBorder.all(color: const Color(0xFF2E5749)),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppTheme.cardBgLight),
                children: ['Bowler', 'O', 'M', 'R', 'W', 'ECO'].map((h) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(h, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.coinGold)),
                )).toList(),
              ),
              ...statsList.map((s) {
                return TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(s.bowlerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(s.oversFormatted, style: const TextStyle(fontSize: 11, color: Colors.white))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text('${s.maidens}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text('${s.runsConceded}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text('${s.wickets}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.dangerRed))),
                    Padding(padding: const EdgeInsets.all(8.0), child: Text(s.economy.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: AppTheme.coinGold))),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBallBadgeWidget(
    String ballResult, {
    BallModel? ball,
    MatchController? controller,
    MatchModel? match,
    int? overIndex,
    int? ballIndex,
  }) {
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
      ),
      child: Center(
        child: Text(
          ballResult,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: fg),
        ),
      ),
    );

    if (ball != null && controller != null && match != null) {
      return GestureDetector(
        onTap: () => _showBallDetailsModal(context, controller, match, ball, overIndex: overIndex, ballIndex: ballIndex),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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

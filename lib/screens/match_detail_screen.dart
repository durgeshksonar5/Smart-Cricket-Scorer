import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/over_model.dart';
import '../models/ball_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import 'reuse_teams_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final MatchModel match;
  final int initialTabIndex;

  const MatchDetailScreen({
    super.key,
    required this.match,
    this.initialTabIndex = 0,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedInnings = 1;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d <= Duration.zero) return '00:00:00';
    String h = d.inHours.toString().padLeft(2, '0');
    String m = (d.inMinutes % 60).toString().padLeft(2, '0');
    String s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    // Find up-to-date match instance if in history or active
    MatchModel match = controller.history.firstWhere(
      (m) => m.id == widget.match.id,
      orElse: () => controller.currentMatch?.id == widget.match.id ? controller.currentMatch! : widget.match,
    );

    bool isEditable = match.isEditable;
    Duration timeRem = match.editTimeRemaining;
    String dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(match.dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text('${match.teamA} vs ${match.teamB}'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryEmerald,
          labelColor: AppTheme.primaryEmerald,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 20), text: 'SUMMARY'),
            Tab(icon: Icon(Icons.table_chart_outlined, size: 20), text: 'SCORECARD'),
            Tab(icon: Icon(Icons.timeline, size: 20), text: 'BALL-BY-BALL'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status & Editing Lock Banner
            _buildStatusHeaderBanner(match, isEditable, timeRem),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Summary
                  _buildSummaryTab(match, dateStr),

                  // Tab 2: Scorecard
                  _buildScorecardTab(match),

                  // Tab 3: Ball by Ball
                  _buildBallByBallTab(context, controller, match, isEditable),
                ],
              ),
            ),

            // Bottom Rematch & Navigation Action Bar
            _buildBottomActionBar(context, controller, match),
            const AppFooter(padding: EdgeInsets.only(top: 4)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeaderBanner(MatchModel match, bool isEditable, Duration timeRem) {
    if (match.status == MatchStatus.live) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppTheme.dangerRed.withValues(alpha: 0.15),
        child: const Row(
          children: [
            Icon(Icons.radio_button_checked, color: AppTheme.dangerRed, size: 14),
            SizedBox(width: 8),
            Text('LIVE MATCH IN PROGRESS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
          ],
        ),
      );
    }

    if (isEditable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppTheme.coinGold.withValues(alpha: 0.15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: AppTheme.coinGold, size: 14),
                const SizedBox(width: 6),
                Text('Editing Available: ${_formatDuration(timeRem)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
              ],
            ),
            const Text('Tap any ball to edit', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.cardBgLight,
      child: const Row(
        children: [
          Icon(Icons.lock, color: AppTheme.textMuted, size: 14),
          SizedBox(width: 8),
          Text('Editing time expired. This match is now permanent and read-only.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(MatchModel match, String dateStr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Winner Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                const Icon(Icons.emoji_events, color: AppTheme.coinGold, size: 48),
                const SizedBox(height: 6),
                Text(
                  match.winnerTeam ?? 'Match Completed',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryEmerald),
                  textAlign: TextAlign.center,
                ),
                if (match.winMargin != null && match.winMargin!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Won By ${match.winMargin}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
                  ),
                ],
                const SizedBox(height: 12),
                Text('${match.teamA} vs ${match.teamB}', style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('📅 $dateStr', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                if (match.venue.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('📍 ${match.venue}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Toss Information
          _buildSectionHeader('TOSS INFORMATION', Icons.monetization_on_outlined),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E5749)),
            ),
            child: match.tossDetails == null
                ? const Text('No toss details recorded.', style: TextStyle(color: AppTheme.textMuted))
                : Column(
                    children: [
                      _buildRow('Toss Winner', match.tossDetails!.tossWinnerTeam, isHighlight: true),
                      const Divider(color: Color(0xFF2E5749)),
                      _buildRow('Toss Decision', match.tossDetails!.tossDecision),
                      const Divider(color: Color(0xFF2E5749)),
                      _buildRow('Coin Call', '${match.tossDetails!.callingTeam} called ${match.tossDetails!.tossCall}'),
                      const Divider(color: Color(0xFF2E5749)),
                      _buildRow('Coin Result', match.tossDetails!.coinResult),
                    ],
                  ),
          ),
          const SizedBox(height: 18),

          // Innings Breakdown
          _buildSectionHeader('INNINGS BREAKDOWN', Icons.analytics_outlined),
          const SizedBox(height: 8),
          _buildInningsOverviewCard(
            title: '1st Innings: ${match.inn1BattingTeam}',
            runs: match.inn1Runs,
            wickets: match.inn1Wickets,
            balls: match.inn1Balls,
            totalOvers: match.totalOvers,
          ),
          const SizedBox(height: 10),
          _buildInningsOverviewCard(
            title: '2nd Innings: ${match.inn2BattingTeam}',
            runs: match.inn2Runs,
            wickets: match.inn2Wickets,
            balls: match.inn2Balls,
            totalOvers: match.totalOvers,
          ),
          const SizedBox(height: 18),

          // Match Squad Snapshots
          _buildSectionHeader('MATCH SQUADS (SNAPSHOT)', Icons.groups_outlined),
          const SizedBox(height: 8),
          _buildSquadSnapshotCard(match.teamA, match.teamAPlayers),
          const SizedBox(height: 10),
          _buildSquadSnapshotCard(match.teamB, match.teamBPlayers),
        ],
      ),
    );
  }

  Widget _buildScorecardTab(MatchModel match) {
    return Column(
      children: [
        // Innings Switcher Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      '1ST INNINGS (${match.inn1Runs}/${match.inn1Wickets})',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _selectedInnings == 1 ? Colors.black : Colors.white),
                    ),
                  ),
                  selected: _selectedInnings == 1,
                  selectedColor: AppTheme.primaryEmerald,
                  backgroundColor: AppTheme.cardBgLight,
                  onSelected: (val) {
                    if (val) setState(() => _selectedInnings = 1);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Center(
                    child: Text(
                      '2ND INNINGS (${match.inn2Runs}/${match.inn2Wickets})',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _selectedInnings == 2 ? Colors.black : Colors.white),
                    ),
                  ),
                  selected: _selectedInnings == 2,
                  selectedColor: AppTheme.coinGold,
                  backgroundColor: AppTheme.cardBgLight,
                  onSelected: (val) {
                    if (val) setState(() => _selectedInnings = 2);
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: _buildInningsScorecard(match, _selectedInnings),
          ),
        ),
      ],
    );
  }

  Widget _buildInningsScorecard(MatchModel match, int innings) {
    List<BatterStats> batters = match.getBattingStatsForInnings(innings);
    List<BowlerStats> bowlers = match.getBowlingStatsForInnings(innings);
    ExtrasSummary extras = match.getExtrasForInnings(innings);

    int runs = innings == 1 ? match.inn1Runs : match.inn2Runs;
    int wickets = innings == 1 ? match.inn1Wickets : match.inn2Wickets;
    int balls = innings == 1 ? match.inn1Balls : match.inn2Balls;
    String oversFormatted = MatchModel.formatOvers(balls);

    String battingTeamName = innings == 1 ? match.inn1BattingTeam : match.inn2BattingTeam;
    String bowlingTeamName = innings == 1 ? match.inn1BowlingTeam : match.inn2BowlingTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BATTING TABLE
        _buildSectionHeader('$battingTeamName BATTING', Icons.sports_cricket),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E5749)),
          ),
          child: Column(
            children: [
              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppTheme.cardBgLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('Batter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald))),
                    Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                    Expanded(flex: 1, child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                    Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                    Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                    Expanded(flex: 2, child: Text('SR', textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                  ],
                ),
              ),

              // Batter Rows
              if (batters.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No batting data available.', style: TextStyle(color: AppTheme.textMuted)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: batters.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFF2E5749)),
                  itemBuilder: (ctx, i) {
                    final b = batters[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  b.playerName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(flex: 1, child: Text('${b.runs}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.coinGold))),
                              Expanded(flex: 1, child: Text('${b.balls}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
                              Expanded(flex: 1, child: Text('${b.fours}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
                              Expanded(flex: 1, child: Text('${b.sixes}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
                              Expanded(flex: 2, child: Text(b.strikeRate.toStringAsFixed(1), textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: Colors.white))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.dismissalInfo,
                            style: TextStyle(
                              fontSize: 11,
                              color: b.isOut ? AppTheme.dangerRed.withValues(alpha: 0.9) : AppTheme.primaryEmerald,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // Extras and Total Summary Footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppTheme.cardBgLight,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Extras', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text('${extras.total} (${extras.breakdown})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                        Text('$runs / $wickets ($oversFormatted Ov)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.coinGold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // BOWLING TABLE
        _buildSectionHeader('$bowlingTeamName BOWLING', Icons.sports_baseball),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2E5749)),
          ),
          child: Column(
            children: [
              // Bowling Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppTheme.cardBgLight,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 4, child: Text('Bowler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.coinGold))),
                    Expanded(flex: 1, child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                    Expanded(flex: 1, child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                    Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                    Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald))),
                    Expanded(flex: 2, child: Text('Econ', textAlign: TextAlign.end, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))),
                  ],
                ),
              ),

              // Bowler Rows
              if (bowlers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No bowling data available.', style: TextStyle(color: AppTheme.textMuted)),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bowlers.length,
                  separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFF2E5749)),
                  itemBuilder: (ctx, i) {
                    final bowl = bowlers[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: Text(bowl.bowlerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                          Expanded(flex: 1, child: Text(bowl.oversFormatted, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Colors.white))),
                          Expanded(flex: 1, child: Text('${bowl.maidens}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted))),
                          Expanded(flex: 1, child: Text('${bowl.runsConceded}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.coinGold))),
                          Expanded(flex: 1, child: Text('${bowl.wickets}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald))),
                          Expanded(flex: 2, child: Text(bowl.economy.toStringAsFixed(2), textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: Colors.white))),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBallByBallTab(BuildContext context, MatchController controller, MatchModel match, bool isEditable) {
    List<OverModel> overs = _selectedInnings == 1 ? match.inn1Overs : match.inn2Overs;

    return Column(
      children: [
        // Innings selector chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text('1ST INNINGS (${match.inn1Overs.length} Overs)')),
                  selected: _selectedInnings == 1,
                  selectedColor: AppTheme.primaryEmerald,
                  backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, color: _selectedInnings == 1 ? Colors.black : Colors.white),
                  onSelected: (val) {
                    if (val) setState(() => _selectedInnings = 1);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Center(child: Text('2ND INNINGS (${match.inn2Overs.length} Overs)')),
                  selected: _selectedInnings == 2,
                  selectedColor: AppTheme.coinGold,
                  backgroundColor: AppTheme.cardBgLight,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, color: _selectedInnings == 2 ? Colors.black : Colors.white),
                  onSelected: (val) {
                    if (val) setState(() => _selectedInnings = 2);
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: overs.isEmpty
              ? const Center(child: Text('No balls recorded for this innings.', style: TextStyle(color: AppTheme.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  itemCount: overs.length,
                  itemBuilder: (context, overIdx) {
                    final over = overs[overIdx];
                    int runsInOver = over.balls.fold(0, (sum, b) => sum + b.runs);
                    int wicketsInOver = over.balls.where((b) => b.isWicket).length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2E5749)),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: overIdx == overs.length - 1,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        title: Text(
                          'Over ${over.overNumber} • ${over.bowler}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          '$runsInOver Runs • $wicketsInOver Wickets',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Column(
                              children: List.generate(over.balls.length, (ballIdx) {
                                final b = over.balls[ballIdx];
                                return InkWell(
                                  onTap: isEditable ? () => _showEditBallDialog(context, controller, match, _selectedInnings, overIdx, ballIdx, b) : null,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardBgLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        // Ball Number
                                        Text(
                                          b.ballNumberFormatted,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
                                        ),
                                        const SizedBox(width: 10),

                                        // Ball outcome badge
                                        _buildBallChip(b),
                                        const SizedBox(width: 10),

                                        // Striker to Bowler info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${b.bowler} to ${b.striker}',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                              ),
                                              if (b.isWicket)
                                                Text(
                                                  'OUT (${b.dismissalType ?? "Wicket"})',
                                                  style: const TextStyle(fontSize: 11, color: AppTheme.dangerRed, fontWeight: FontWeight.bold),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Score snapshot
                                        Text(
                                          b.teamScoreSnapshot,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        ),

                                        if (isEditable) ...[
                                          const SizedBox(width: 6),
                                          const Icon(Icons.edit_outlined, color: AppTheme.coinGold, size: 16),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBallChip(BallModel b) {
    Color bg = AppTheme.cardBg;
    Color fg = Colors.white;

    if (b.isWicket) {
      bg = AppTheme.dangerRed;
      fg = Colors.white;
    } else if (b.runs == 4 || b.runs == 6) {
      bg = AppTheme.coinGold;
      fg = Colors.black;
    } else if (b.extraType == 'WD' || b.extraType == 'NB') {
      bg = Colors.orange;
      fg = Colors.black;
    } else if (b.runs > 0) {
      bg = AppTheme.primaryEmerald.withValues(alpha: 0.3);
      fg = AppTheme.primaryEmerald;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        b.displayResult,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildInningsOverviewCard({
    required String title,
    required int runs,
    required int wickets,
    required int balls,
    required int totalOvers,
  }) {
    String oversFormatted = MatchModel.formatOvers(balls);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E5749)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('$runs / $wickets', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Overs', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text('$oversFormatted / $totalOvers.0', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquadSnapshotCard(String teamName, List<PlayerModel> players) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E5749)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text('$teamName Squad (${players.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: players.asMap().entries.map((entry) {
                int i = entry.key;
                var p = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.cardBgLight, borderRadius: BorderRadius.circular(8)),
                  child: Text('${i + 1}. ${p.name}${p.isCaptain ? " (C)" : ""}${p.isWicketKeeper ? " (WK)" : ""}', style: const TextStyle(fontSize: 12, color: Colors.white)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, MatchController controller, MatchModel match) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(top: BorderSide(color: Color(0xFF2E5749))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  _confirmRematch(context, controller, match);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.sync, color: Colors.black),
                label: const Text('QUICK REMATCH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryEmerald, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryEmerald,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String title, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppTheme.coinGold : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRematch(BuildContext context, MatchController controller, MatchModel match) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sync, color: AppTheme.primaryEmerald),
            SizedBox(width: 8),
            Text('START REMATCH?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${match.teamA} vs ${match.teamB}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.coinGold)),
            const SizedBox(height: 8),
            Text('${match.teamAPlayers.length} players from each team will be reused.', style: const TextStyle(fontSize: 13, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('All scoring statistics will start from 0.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReuseTeamsScreen(sourceMatch: match)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.black),
            child: const Text('CONFIGURE & REMATCH', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showEditBallDialog(
    BuildContext context,
    MatchController controller,
    MatchModel match,
    int innings,
    int overIdx,
    int ballIdx,
    BallModel currentBall,
  ) {
    int runs = currentBall.runs;
    bool isWicket = currentBall.isWicket;
    String? extra = currentBall.extraType;
    String? dismissal = currentBall.dismissalType;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              title: Text('Edit Ball ${currentBall.ballNumberFormatted}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Runs selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Runs:'),
                      DropdownButton<int>(
                        value: runs,
                        dropdownColor: AppTheme.cardBgLight,
                        items: [0, 1, 2, 3, 4, 6].map((r) => DropdownMenuItem(value: r, child: Text('$r Runs'))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => runs = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Extras selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Extra:'),
                      DropdownButton<String?>(
                        value: extra,
                        dropdownColor: AppTheme.cardBgLight,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None (Legal)')),
                          const DropdownMenuItem(value: 'WD', child: Text('Wide (WD)')),
                          const DropdownMenuItem(value: 'NB', child: Text('No Ball (NB)')),
                          const DropdownMenuItem(value: 'B', child: Text('Bye (B)')),
                          const DropdownMenuItem(value: 'LB', child: Text('Leg Bye (LB)')),
                        ],
                        onChanged: (val) => setDialogState(() => extra = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Wicket toggle
                  SwitchListTile(
                    title: const Text('Is Wicket?', style: TextStyle(fontSize: 14)),
                    value: isWicket,
                    activeThumbColor: AppTheme.dangerRed,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDialogState(() => isWicket = val),
                  ),

                  if (isWicket) ...[
                    DropdownButton<String>(
                      isExpanded: true,
                      value: dismissal ?? 'Bowled',
                      dropdownColor: AppTheme.cardBgLight,
                      items: ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'Hit Wicket']
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => dismissal = val);
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    controller.editBall(
                      innings: innings,
                      overIndex: overIdx,
                      ballIndex: ballIdx,
                      runs: runs,
                      isWicket: isWicket,
                      extraType: extra,
                      dismissalType: isWicket ? (dismissal ?? 'Bowled') : null,
                    );
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.black),
                  child: const Text('SAVE CORRECTION', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

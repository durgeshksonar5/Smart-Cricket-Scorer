import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../theme/app_theme.dart';
import '../widgets/made_by_footer.dart';
import 'team_setup_screen.dart';
import 'coin_toss_screen.dart';
import 'scorecard_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'ALL';
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
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

  List<MatchModel> _filterMatches(List<MatchModel> allMatches, MatchModel? activeMatch) {
    List<MatchModel> list = [];

    // Combine active match if present and not in history yet
    if (activeMatch != null && !activeMatch.isCompleted) {
      if (!allMatches.any((m) => m.id == activeMatch.id)) {
        list.add(activeMatch);
      }
    }
    list.addAll(allMatches);

    if (_selectedFilter == 'LIVE') {
      return list.where((m) => !m.isCompleted).toList();
    } else if (_selectedFilter == 'COMPLETED') {
      return list.where((m) => m.isCompleted).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    MatchModel? activeMatch = controller.currentMatch;
    bool hasActiveLiveMatch = (activeMatch != null && !activeMatch.isCompleted && activeMatch.status != MatchStatus.abandoned);

    List<MatchModel> filteredMatches = _filterMatches(controller.history, activeMatch);

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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ACTIVE LIVE MATCH BANNER (IF UNFINISHED MATCH EXISTS)
              if (hasActiveLiveMatch) ...[
                _buildActiveLiveMatchCard(context, controller, activeMatch),
                const SizedBox(height: 16),
              ] else ...[
                // Hero Banner Card for Start New Match
                _buildStartNewMatchHeroCard(context, controller),
                const SizedBox(height: 20),
              ],

              // 2. MATCH HISTORY FILTERS HEADER & CHIPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MATCH HISTORY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '${filteredMatches.length} Matches',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ALL', 'LIVE', 'COMPLETED'].map((filter) {
                    bool isSel = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(filter, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.black : Colors.white)),
                        selected: isSel,
                        selectedColor: AppTheme.primaryEmerald,
                        backgroundColor: AppTheme.cardBgLight,
                        onSelected: (val) {
                          if (val) setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // 3. MATCH HISTORY LIST
              Expanded(
                child: controller.isLoadingHistory
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald))
                    : filteredMatches.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: filteredMatches.length,
                            itemBuilder: (context, index) {
                              final match = filteredMatches[index];
                              return _buildMatchCard(context, controller, match);
                            },
                          ),
              ),
              const MadeByFooter(padding: EdgeInsets.only(top: 8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveLiveMatchCard(BuildContext context, MatchController controller, MatchModel match) {
    String lastSavedStr = 'Just now';
    if (match.lastSavedAt != null) {
      int diffMins = DateTime.now().difference(match.lastSavedAt!).inMinutes;
      lastSavedStr = diffMins == 0 ? 'Just now' : '$diffMins mins ago';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3B2F), Color(0xFF265242)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.coinGold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.coinGold.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.radio_button_checked, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('LIVE MATCH IN PROGRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
              ),
              Text('Saved: $lastSavedStr', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),

          Text('${match.teamA} vs ${match.teamB}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${match.battingTeam}: ', style: const TextStyle(fontSize: 14, color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
              Text('${match.currentRuns}/${match.currentWickets}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.coinGold)),
              const SizedBox(width: 8),
              Text('(${match.currentOversFormatted} Ov)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (match.status == MatchStatus.tossPending) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CoinTossScreen()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScorecardScreen()));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald, foregroundColor: Colors.black),
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: const Text('CONTINUE MATCH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: () => _confirmAbandon(context, controller),
                icon: const Icon(Icons.stop_circle_outlined, color: AppTheme.dangerRed),
                style: IconButton.styleFrom(backgroundColor: AppTheme.cardBgLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartNewMatchHeroCard(BuildContext context, MatchController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF132620), Color(0xFF1F4035)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E5749), width: 1.5),
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
                child: const Icon(Icons.sports_cricket, color: Colors.black, size: 26),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ready for a Match?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('Fair coin toss & official scorecard', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                controller.resetCurrentMatch();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamSetupScreen()));
              },
              icon: const Icon(Icons.play_arrow, color: Colors.black, size: 24),
              label: const Text('START NEW MATCH', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchController controller, MatchModel match) {
    String dateStr = DateFormat('dd MMM yyyy').format(match.dateTime);
    bool isEditable = match.isEditable;
    Duration timeRem = match.editTimeRemaining;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          controller.selectHistoricalMatch(match);
          if (!match.isCompleted) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ScorecardScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match)));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isEditable ? AppTheme.primaryEmerald.withValues(alpha: 0.6) : const Color(0xFF2E5749)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${match.teamA} vs ${match.teamB}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                  ),
                  Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 6),

              // Scores summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('1st: ${match.inn1Runs}/${match.inn1Wickets} (${MatchModel.formatOvers(match.inn1Balls)} ov)', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: Text('2nd: ${match.inn2Runs}/${match.inn2Wickets} (${MatchModel.formatOvers(match.inn2Balls)} ov)', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Editing Status / Timer Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (match.isCompleted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isEditable ? AppTheme.coinGold.withValues(alpha: 0.15) : AppTheme.cardBgLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isEditable ? AppTheme.coinGold : Colors.grey),
                      ),
                      child: Row(
                        children: [
                          Icon(isEditable ? Icons.timer : Icons.lock, size: 12, color: isEditable ? AppTheme.coinGold : AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            isEditable ? 'Editing Available: ${_formatDuration(timeRem)}' : '🔒 Editing Locked',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isEditable ? AppTheme.coinGold : AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.dangerRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('🔴 Live Match', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                    ),
                  ],

                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 18),
                    onPressed: () => _confirmDelete(context, controller, match.id),
                  ),
                ],
              ),
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
          Icon(Icons.history_toggle_off, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          const Text('No matches found for filter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          const Text('Tap "Start New Match" to begin!', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  void _confirmAbandon(BuildContext context, MatchController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text('Abandon Current Match?'),
        content: const Text('Are you sure you want to abandon this live match? All unsaved data will be cleared.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.abandonCurrentMatch();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('ABANDON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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

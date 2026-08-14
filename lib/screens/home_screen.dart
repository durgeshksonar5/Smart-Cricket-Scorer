import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';
import '../widgets/made_by_footer.dart';
import '../widgets/app_logo.dart';
import 'team_setup_screen.dart';
import 'coin_toss_screen.dart';
import 'scorecard_screen.dart';
import 'match_detail_screen.dart';
import 'my_teams_screen.dart';
import 'reuse_teams_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearchVisible = false;
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
    _searchCtrl.dispose();
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

    // Apply Filter Chips
    if (_selectedFilter == 'LIVE') {
      list = list.where((m) => !m.isCompleted).toList();
    } else if (_selectedFilter == 'COMPLETED') {
      list = list.where((m) => m.isCompleted).toList();
    } else if (_selectedFilter == 'EDITABLE') {
      list = list.where((m) => m.isCompleted && m.isEditable).toList();
    } else if (_selectedFilter == 'LOCKED') {
      list = list.where((m) => m.isCompleted && !m.isEditable).toList();
    }

    // Apply Search Query
    if (_searchQuery.trim().isNotEmpty) {
      String q = _searchQuery.trim().toLowerCase();
      list = list.where((m) {
        bool teamMatch = m.teamA.toLowerCase().contains(q) || m.teamB.toLowerCase().contains(q);
        bool venueMatch = m.venue.toLowerCase().contains(q);
        bool dateMatch = DateFormat('dd MMM yyyy').format(m.dateTime).toLowerCase().contains(q);
        bool playerMatch = m.teamAPlayers.any((p) => p.name.toLowerCase().contains(q)) ||
            m.teamBPlayers.any((p) => p.name.toLowerCase().contains(q));
        return teamMatch || venueMatch || dateMatch || playerMatch;
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    MatchModel? activeMatch = controller.currentMatch;
    bool hasActiveLiveMatch = (activeMatch != null && !activeMatch.isCompleted && activeMatch.status != MatchStatus.abandoned);

    List<MatchModel> filteredMatches = _filterMatches(controller.history, activeMatch);
    MatchModel? latestCompletedMatch = controller.history.where((m) => m.isCompleted).isNotEmpty
        ? controller.history.firstWhere((m) => m.isCompleted)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(size: 28, showText: true),
        actions: [
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.search_off : Icons.search, color: AppTheme.primaryEmerald),
            tooltip: 'Search Matches',
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: AppTheme.primaryEmerald),
            tooltip: 'My Teams',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyTeamsScreen()),
              );
            },
          ),
        ],
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
                const SizedBox(height: 12),

                // Quick Start / Reuse Last Match Card (if recent match available)
                if (latestCompletedMatch != null || controller.lastUsedTeams != null) ...[
                  _buildQuickStartReuseCard(context, controller, latestCompletedMatch),
                  const SizedBox(height: 16),
                ] else ...[
                  const SizedBox(height: 8),
                ],
              ],

              // 2. SEARCH BAR (IF TOGGLED)
              if (_isSearchVisible) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by team, player, venue, or date...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryEmerald, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ],

              // 3. MATCH HISTORY FILTERS HEADER & CHIPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PERMANENT MATCH HISTORY',
                    style: TextStyle(
                      fontSize: 12,
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
                  children: ['ALL', 'LIVE', 'COMPLETED', 'EDITABLE', 'LOCKED'].map((filter) {
                    bool isSel = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(filter, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.black : Colors.white)),
                        selected: isSel,
                        selectedColor: filter == 'LOCKED' ? Colors.grey.shade700 : AppTheme.primaryEmerald,
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

              // 4. MATCH HISTORY LIST
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
      padding: const EdgeInsets.all(18),
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
              const AppLogo(size: 38, showText: false),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ready for a Match?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                    Text('Fair coin toss & official scorecard', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                controller.resetCurrentMatch();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TeamSetupScreen()));
              },
              icon: const Icon(Icons.add, color: Colors.black, size: 22),
              label: const Text('START NEW MATCH', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartReuseCard(BuildContext context, MatchController controller, MatchModel? latestMatch) {
    String teamA = latestMatch?.teamA ?? (controller.lastUsedTeams?['teamA'] ?? 'India');
    String teamB = latestMatch?.teamB ?? (controller.lastUsedTeams?['teamB'] ?? 'Australia');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sync, color: AppTheme.primaryEmerald, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'QUICK START',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.coinGold, letterSpacing: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  '$teamA vs $teamB',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (latestMatch != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReuseTeamsScreen(sourceMatch: latestMatch)),
                );
              } else if (controller.lastUsedTeams != null) {
                var d = controller.lastUsedTeams!;
                List<PlayerModel> pA = (d['teamAPlayers'] as List<dynamic>?)?.map((p) => PlayerModel.fromJson(p)).toList() ?? [];
                List<PlayerModel> pB = (d['teamBPlayers'] as List<dynamic>?)?.map((p) => PlayerModel.fromJson(p)).toList() ?? [];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReuseTeamsScreen(
                      teamAName: d['teamA'],
                      teamBName: d['teamB'],
                      teamAPlayers: pA,
                      teamBPlayers: pB,
                      totalOvers: d['totalOvers'] ?? 20,
                      playersPerTeam: d['playersPerTeam'] ?? 11,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 36),
            ),
            child: const Text('REUSE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, MatchController controller, MatchModel match) {
    String dateStr = DateFormat('dd MMM yyyy').format(match.dateTime);
    bool isEditable = match.isEditable;
    Duration timeRem = match.editTimeRemaining;

    String inn1Team = match.tossDetails?.tossDecision == "Bowl First" ? match.teamB : match.teamA;
    String inn2Team = inn1Team == match.teamA ? match.teamB : match.teamA;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEditable
              ? AppTheme.primaryEmerald.withValues(alpha: 0.6)
              : const Color(0xFF2E5749),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Teams & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      controller.selectHistoricalMatch(match);
                      if (!match.isCompleted) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ScorecardScreen()));
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match)));
                      }
                    },
                    child: Text(
                      '${match.teamA} vs ${match.teamB}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
            const SizedBox(height: 8),

            // Scores Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$inn1Team: ${match.inn1Runs}/${match.inn1Wickets}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '(${MatchModel.formatOvers(match.inn1Balls)} / ${match.totalOvers}.0 ov)',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                const Text('vs', style: TextStyle(fontSize: 12, color: AppTheme.coinGold, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$inn2Team: ${match.inn2Runs}/${match.inn2Wickets}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        '(${MatchModel.formatOvers(match.inn2Balls)} / ${match.totalOvers}.0 ov)',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Result / Margin Banner
            if (match.winnerTeam != null && match.winnerTeam!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '🏆 ${match.winnerTeam} ${match.winMargin != null && match.winMargin!.isNotEmpty ? "won by ${match.winMargin}" : ""}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Status Badge & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Badge
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
                          isEditable ? 'Editable (${_formatDuration(timeRem)})' : '🔒 Permanent',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isEditable ? AppTheme.coinGold : AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.dangerRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: const Text('🔴 Live Match', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
                  ),
                ],

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // VIEW SCORECARD BUTTON
                    OutlinedButton(
                      onPressed: () {
                        controller.selectHistoricalMatch(match);
                        if (!match.isCompleted) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ScorecardScreen()));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MatchDetailScreen(match: match, initialTabIndex: 1)));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        side: const BorderSide(color: AppTheme.primaryEmerald),
                        minimumSize: const Size(50, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('VIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryEmerald)),
                    ),
                    const SizedBox(width: 6),

                    // REMATCH BUTTON (For completed matches)
                    if (match.isCompleted) ...[
                      ElevatedButton.icon(
                        onPressed: () => _confirmRematch(context, controller, match),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryEmerald,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: const Size(60, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.sync, size: 13, color: Colors.black),
                        label: const Text('REMATCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 6),
                    ],

                    // Delete Button
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
          ],
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
          const Text('No matches found for filter/search', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          const Text('Tap "Start New Match" to begin!', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
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
            Text(
              '${match.teamA} vs ${match.teamB}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.coinGold),
            ),
            const SizedBox(height: 10),
            Text(
              '${match.teamAPlayers.length} players from each team will be reused.',
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'All scoring statistics will start from 0.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReuseTeamsScreen(sourceMatch: match)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmerald,
              foregroundColor: Colors.black,
            ),
            child: const Text('CONFIGURE & REMATCH', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
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

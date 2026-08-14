import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/match_controller.dart';
import '../models/team_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';
import 'team_editor_screen.dart';
import 'team_setup_screen.dart';

class MyTeamsScreen extends StatelessWidget {
  const MyTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MatchController>(context);
    final teams = controller.savedTeams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryEmerald),
            tooltip: 'Create New Team',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamEditorScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: teams.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        return _buildTeamCard(context, controller, team);
                      },
                    ),
            ),
            const AppFooter(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TeamEditorScreen()),
          );
        },
        backgroundColor: AppTheme.primaryEmerald,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('CREATE TEAM', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildTeamCard(BuildContext context, MatchController controller, TeamModel team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E5749), width: 1.2),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('🏏', style: TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          '${team.players.length} Players Squad',
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.coinGold, size: 20),
              tooltip: 'Edit Roster',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeamEditorScreen(teamToEdit: team)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed, size: 20),
              tooltip: 'Delete Team',
              onPressed: () => _confirmDeleteTeam(context, controller, team),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Color(0xFF2E5749)),
                const SizedBox(height: 6),
                const Text(
                  'ROSTER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryEmerald,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: team.players.asMap().entries.map((entry) {
                    int i = entry.key;
                    var p = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBgLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${i + 1}. ${p.name}${p.isCaptain ? " (C)" : ""}${p.isWicketKeeper ? " (WK)" : ""}',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamSetupScreen(preselectedTeamA: team),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.play_arrow, size: 20, color: Colors.black),
                    label: const Text('USE IN NEW MATCH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text('No Saved Teams Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Create your favorite cricket team rosters for quick reuse.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamEditorScreen()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.black),
            label: const Text('CREATE FIRST TEAM'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTeam(BuildContext context, MatchController controller, TeamModel team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text('Delete "${team.name}"?'),
        content: const Text('Are you sure you want to remove this team from saved rosters? Past matches with this team will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteTeam(team.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

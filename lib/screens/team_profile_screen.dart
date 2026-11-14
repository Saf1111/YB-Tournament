import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tournament_models.dart';
import '../themes/league_themes.dart';
import '../services/tournament_engine.dart';

class TeamProfileScreen extends StatefulWidget {
  final Tournament tournament;
  final Team team;
  final LeagueTheme theme;

  const TeamProfileScreen({
    super.key,
    required this.tournament,
    required this.team,
    required this.theme,
  });

  @override
  State<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends State<TeamProfileScreen> {
  int _selectedTab = 0;

  Future<void> _editTeamLogo() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Logo',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Do you want to edit the team logo?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      String? newLogoPath = await TournamentEngine.pickAndSaveLogo();
      if (newLogoPath != null) {
        setState(() {
          widget.team.logoPath = newLogoPath;
        });
        await TournamentEngine.saveSingleTournament(widget.tournament);
      }
    }
  }

  Future<void> _editTeamName() async {
    final TextEditingController nameController = TextEditingController(
      text: widget.team.name,
    );

    final String? newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Team Name',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Team Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: widget.theme.primaryColor,
                width: 2,
              ),
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.theme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final text = nameController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx, text);
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName != widget.team.name) {
      setState(() {
        widget.team.name = newName;
      });
      await TournamentEngine.saveSingleTournament(widget.tournament);
    }
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Team',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.image, color: widget.theme.primaryColor),
              ),
              title: const Text(
                'Change Logo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _editTeamLogo();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.edit_note, color: widget.theme.primaryColor),
              ),
              title: const Text(
                'Edit Team Name',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _editTeamName();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final standings = TournamentEngine.calculateStandings(widget.tournament);
    final int rank =
        standings.indexWhere((s) => s.team.id == widget.team.id) + 1;
    final stat = rank > 0
        ? standings[rank - 1]
        : TeamStanding(team: widget.team);

    final cleanSheets = TournamentEngine.calculateCleanSheets(
      widget.tournament,
    ).where((cs) => cs.teamName == widget.team.name).toList();
    final topScorers = TournamentEngine.calculateTopScorers(
      widget.tournament,
    ).where((ts) => ts.teamName == widget.team.name).toList();

    final int totalCs = cleanSheets.fold(0, (sum, cs) => sum + cs.count);

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
            onPressed: _showEditOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _editTeamLogo,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.theme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child:
                    widget.team.logoPath != null &&
                        File(widget.team.logoPath!).existsSync()
                    ? ClipOval(
                        child: Image.file(
                          File(widget.team.logoPath!),
                          fit: BoxFit.contain,
                          width: 80,
                          height: 80,
                        ),
                      )
                    : Icon(
                        Icons.shield,
                        size: 50,
                        color: widget.theme.primaryColor,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _editTeamName,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.team.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, color: Colors.white70, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Rank: ${rank > 0 ? rank : '-'}',
                style: const TextStyle(
                  color: Color(0xFF422006),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildStatCard('MP', stat.mp.toString(), Colors.white),
                      _buildStatCard(
                        'W',
                        stat.w.toString(),
                        const Color(0xFF22C55E),
                      ),
                      _buildStatCard(
                        'D',
                        stat.d.toString(),
                        const Color(0xFFEAB308),
                      ),
                      _buildStatCard(
                        'L',
                        stat.l.toString(),
                        const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard('GD', stat.gd.toString(), Colors.white),
                      _buildStatCard('GF', stat.gf.toString(), Colors.white),
                      _buildStatCard(
                        'CS',
                        totalCs.toString(),
                        const Color(0xFF38BDF8),
                      ),
                      _buildStatCard(
                        'PTS',
                        stat.points.toString(),
                        const Color(0xFFA855F7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTabButton(0, 'Performers'),
                  _buildTabButton(1, 'Match History'),
                  _buildTabButton(2, 'Fixtures'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildTabContent(topScorers, cleanSheets),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFEF4444)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  // ================= പുതുതായി മാറ്റം വരുത്തിയ ഭാഗം =================
  Widget _buildTabContent(
    List<PlayerStat> topScorers,
    List<PlayerStat> cleanSheets,
  ) {
    if (_selectedTab == 0) {
      // Performers Tab (പഴയത് പോലെ തന്നെ)
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
        ),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Scorers (Team)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            if (topScorers.isEmpty)
              const Text(
                'No goals yet',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              )
            else
              for (var s in topScorers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.playerName,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${s.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 24),
            const Text(
              'Clean Sheets (GK)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            if (cleanSheets.isEmpty)
              const Text(
                'No clean sheets yet',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              )
            else
              for (var s in cleanSheets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.playerName,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${s.count}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      );
    } else if (_selectedTab == 1) {
      // Match History Tab (കളിച്ചു കഴിഞ്ഞ മാച്ചുകൾ)
      final historyMatches = widget.tournament.matches
          .where(
            (m) =>
                m.isCompleted &&
                (m.homeTeamId == widget.team.id ||
                    m.awayTeamId == widget.team.id),
          )
          .toList()
          .reversed
          .toList(); // ഏറ്റവും പുതിയത് ആദ്യം വരാൻ reversed കൊടുത്തു

      if (historyMatches.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No matches played yet.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: historyMatches
              .map((match) => _buildMatchCard(match))
              .toList(),
        ),
      );
    } else {
      // Fixtures Tab (കളിക്കാൻ പോകുന്ന മാച്ചുകൾ)
      final upcomingMatches = widget.tournament.matches
          .where(
            (m) =>
                !m.isCompleted &&
                (m.homeTeamId == widget.team.id ||
                    m.awayTeamId == widget.team.id),
          )
          .toList();

      if (upcomingMatches.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No upcoming fixtures.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: upcomingMatches
              .map((match) => _buildMatchCard(match))
              .toList(),
        ),
      );
    }
  }

  // മാച്ച് റിസൾട്ട് / ഫിക്സ്ചർ കാണിക്കാനുള്ള കാർഡ് ഡിസൈൻ
  Widget _buildMatchCard(MatchFixture match) {
    Team? homeTeam = widget.tournament.teams
        .where((t) => t.id == match.homeTeamId)
        .firstOrNull;
    Team? awayTeam = widget.tournament.teams
        .where((t) => t.id == match.awayTeamId)
        .firstOrNull;

    if (homeTeam == null || awayTeam == null) return const SizedBox.shrink();

    // ഈ ടീം ജയിച്ചോ തോറ്റോ എന്ന് കണ്ടുപിടിക്കാൻ (കളർ കൊടുക്കാൻ)
    Color resultColor = const Color(0xFF334155);
    String resultText = 'VS';

    if (match.isCompleted) {
      bool isHome = widget.team.id == match.homeTeamId;
      int myScore = isHome ? match.homeScore! : match.awayScore!;
      int opponentScore = isHome ? match.awayScore! : match.homeScore!;

      if (myScore > opponentScore) {
        resultColor = const Color(0xFF22C55E); // പച്ച (ജയിച്ചു)
        resultText = '${match.homeScore} - ${match.awayScore}';
      } else if (myScore < opponentScore) {
        resultColor = const Color(0xFFEF4444); // ചുവപ്പ് (തോറ്റു)
        resultText = '${match.homeScore} - ${match.awayScore}';
      } else {
        resultColor = const Color(0xFFEAB308); // മഞ്ഞ (സമനില)
        resultText = '${match.homeScore} - ${match.awayScore}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Home Team
          Expanded(
            child: Column(
              children: [
                _buildSmallLogo(homeTeam),
                const SizedBox(height: 8),
                Text(
                  homeTeam.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Score or VS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: resultColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              resultText,
              style: TextStyle(
                color: resultColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),

          // Away Team
          Expanded(
            child: Column(
              children: [
                _buildSmallLogo(awayTeam),
                const SizedBox(height: 8),
                Text(
                  awayTeam.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallLogo(Team t) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: t.logoPath != null && File(t.logoPath!).existsSync()
          ? ClipOval(
              child: Image.file(
                File(t.logoPath!),
                fit: BoxFit.contain,
                width: 28,
                height: 28,
              ),
            )
          : Icon(Icons.shield, size: 20, color: widget.theme.primaryColor),
    );
  }
}

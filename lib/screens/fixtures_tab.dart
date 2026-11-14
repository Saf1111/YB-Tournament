import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tournament_models.dart';
import '../services/tournament_engine.dart';
import '../themes/league_themes.dart';

class FixturesTab extends StatefulWidget {
  final Tournament tournament;
  final LeagueTheme theme;
  final VoidCallback onRefresh;

  const FixturesTab({
    super.key,
    required this.tournament,
    required this.theme,
    required this.onRefresh,
  });

  @override
  State<FixturesTab> createState() => _FixturesTabState();
}

class _FixturesTabState extends State<FixturesTab> {
  int _selectedRound = 1;
  late List<int> _rounds;

  @override
  void initState() {
    super.initState();
    _setupRounds();
  }

  void _setupRounds() {
    final matches = widget.tournament.matches;
    if (matches.isEmpty) {
      _rounds = [1];
      return;
    }
    final highestRound = matches
        .map((m) => m.round)
        .reduce((a, b) => a > b ? a : b);
    _rounds = List.generate(highestRound, (i) => i + 1);

    final firstUncompleted = matches.firstWhere(
      (m) => !m.isCompleted,
      orElse: () => matches.last,
    );
    _selectedRound = firstUncompleted.round;
  }

  Team _getTeam(String id) {
    return widget.tournament.teams.firstWhere(
      (t) => t.id == id,
      orElse: () => Team(id: 'unknown', name: 'Unknown Team'),
    );
  }

  void _openMatchDetail(MatchFixture match) async {
    final homeTeam = _getTeam(match.homeTeamId);
    final awayTeam = _getTeam(match.awayTeamId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchDetailScreen(
          tournament: widget.tournament,
          match: match,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          theme: widget.theme,
        ),
      ),
    );

    await TournamentEngine.saveSingleTournament(widget.tournament);
    widget.onRefresh();
    setState(() {
      _setupRounds();
    });
  }

  // ================= DYNAMIC PLAYOFF LOGIC =================
  void _saveNewMatches(List<MatchFixture> newMatches) async {
    setState(() {
      widget.tournament.matches.addAll(newMatches);
      _setupRounds();
      _selectedRound = newMatches.first.round;
    });
    await TournamentEngine.saveSingleTournament(widget.tournament);
    widget.onRefresh();
  }

  void _generateInitialPlayoffs() {
    final newMatches = TournamentEngine.generatePlayoffsFromStandings(
      widget.tournament,
    );
    if (newMatches.isNotEmpty) {
      _saveNewMatches(newMatches);
    }
  }

  void _generateNextKnockoutRound(List<MatchFixture> prevRoundMatches) {
    List<Team> winners = [];

    for (var m in prevRoundMatches) {
      if (m.homeScore == null || m.awayScore == null) return;
      if (m.homeScore! > m.awayScore!) {
        winners.add(_getTeam(m.homeTeamId));
      } else if (m.awayScore! > m.homeScore!) {
        winners.add(_getTeam(m.awayTeamId));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Knockout matches cannot end in a draw! Please enter a decisive score (or penalty shootout score).',
            ),
          ),
        );
        return;
      }
    }

    int nextRound = prevRoundMatches.first.round + 1;
    List<MatchFixture> newMatches = [];

    // ISL Top 6 Format Special Case
    if (widget.tournament.playoffQualifiers == 6 &&
        prevRoundMatches.first.knockoutTitle != null &&
        prevRoundMatches.first.knockoutTitle!.contains('Eliminator')) {
      final standings = TournamentEngine.calculateStandings(widget.tournament);
      if (standings.length >= 2) {
        Team firstPlace = standings[0].team;
        Team secondPlace = standings[1].team;

        newMatches.add(
          MatchFixture(
            id: 'ko_${DateTime.now().millisecondsSinceEpoch}_sf1',
            round: nextRound,
            stage: 'Knockout',
            knockoutTitle: 'Semi Final 1',
            homeTeamId: firstPlace.id,
            awayTeamId: winners.length > 1 ? winners[1].id : winners[0].id,
          ),
        );

        newMatches.add(
          MatchFixture(
            id: 'ko_${DateTime.now().millisecondsSinceEpoch}_sf2',
            round: nextRound,
            stage: 'Knockout',
            knockoutTitle: 'Semi Final 2',
            homeTeamId: secondPlace.id,
            awayTeamId: winners[0].id,
          ),
        );
      }
    } else {
      String title = _getKnockoutStageName(winners.length);
      for (int i = 0; i + 1 < winners.length; i += 2) {
        newMatches.add(
          MatchFixture(
            id: 'ko_${DateTime.now().millisecondsSinceEpoch}_$i',
            round: nextRound,
            stage: 'Knockout',
            knockoutTitle: title,
            homeTeamId: winners[i].id,
            awayTeamId: winners[i + 1].id,
          ),
        );
      }
    }

    if (newMatches.isNotEmpty) {
      _saveNewMatches(newMatches);
    }
  }

  String _getKnockoutStageName(int teamCount) {
    if (teamCount <= 2) return 'Final';
    if (teamCount <= 4) return 'Semi Final';
    if (teamCount <= 8) return 'Quarter Final';
    return 'Round of $teamCount';
  }
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final matchesForRound = widget.tournament.matches
        .where((m) => m.round == _selectedRound)
        .toList();

    bool showPlayoffButton = false;
    String buttonText = '';
    VoidCallback? onButtonTap;

    if (widget.tournament.matches.isNotEmpty) {
      final highestRound = widget.tournament.matches
          .map((m) => m.round)
          .reduce((a, b) => a > b ? a : b);

      if (_selectedRound == highestRound) {
        final highestRoundMatches = widget.tournament.matches
            .where((m) => m.round == highestRound)
            .toList();
        final allCompleted = highestRoundMatches.every((m) => m.isCompleted);

        if (allCompleted) {
          bool hasKnockouts = widget.tournament.matches.any(
            (m) => m.stage == 'Knockout',
          );
          String format = widget.tournament.formatType;

          // 1. League or Group finished, start playoffs
          if ((format == 'League + Playoffs' ||
                  format == 'League + Knockout' ||
                  format == 'Group + Knockout') &&
              !hasKnockouts) {
            showPlayoffButton = true;
            buttonText = format == 'Group + Knockout'
                ? 'START KNOCKOUTS'
                : 'START PLAYOFFS (TOP ${widget.tournament.playoffQualifiers})';
            onButtonTap = _generateInitialPlayoffs;
          }
          // 2. Currently in a knockout stage, generate next round
          else if (hasKnockouts ||
              format == 'Knockout' ||
              format == 'Knockout Only') {
            if (highestRoundMatches.length > 1) {
              showPlayoffButton = true;
              buttonText = 'GENERATE NEXT ROUND';
              onButtonTap = () =>
                  _generateNextKnockoutRound(highestRoundMatches);
            }
          }
        }
      }
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          height: 54,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _rounds.length,
            itemBuilder: (context, index) {
              final round = _rounds[index];
              final isSelected = round == _selectedRound;

              final kmatch = widget.tournament.matches
                  .where((m) => m.round == round)
                  .firstOrNull;
              String roundName =
                  kmatch?.stage == 'Knockout' && kmatch?.knockoutTitle != null
                  ? kmatch!.knockoutTitle!
                  : (kmatch?.stage == 'Group Stage'
                        ? 'Group MW $round'
                        : 'MW $round');

              return GestureDetector(
                onTap: () => setState(() => _selectedRound = round),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.theme.accentColor
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: widget.theme.accentColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    roundName,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: matchesForRound.length + (showPlayoffButton ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == matchesForRound.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: onButtonTap,
                    icon: const Icon(Icons.emoji_events, size: 22),
                    label: Text(
                      buttonText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              }

              final match = matchesForRound[index];
              final homeTeam = _getTeam(match.homeTeamId);
              final awayTeam = _getTeam(match.awayTeamId);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (match.stage == 'Group Stage' && match.groupId != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.theme.primaryColor.withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          match.groupId!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: widget.theme.primaryColor,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildLogo(homeTeam),
                                const SizedBox(height: 8),
                                Text(
                                  homeTeam.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: match.isCompleted
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F172A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${match.homeScore} - ${match.awayScore}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'VS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                _buildLogo(awayTeam),
                                const SizedBox(height: 8),
                                Text(
                                  awayTeam.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: match.isCompleted
                                  ? Colors.white
                                  : widget.theme.primaryColor,
                              foregroundColor: match.isCompleted
                                  ? const Color(0xFF334155)
                                  : Colors.white,
                              elevation: match.isCompleted ? 0 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: match.isCompleted
                                      ? const Color(0xFFCBD5E1)
                                      : Colors.transparent,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () => _openMatchDetail(match),
                            icon: Icon(
                              match.isCompleted ? Icons.edit : Icons.add,
                              size: 16,
                            ),
                            label: Text(
                              match.isCompleted ? 'Re-edit Score' : 'Add Score',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildLogo(Team team) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: ClipOval(
        child: team.logoPath != null && File(team.logoPath!).existsSync()
            ? Image.file(File(team.logoPath!), fit: BoxFit.contain)
            : Icon(Icons.shield, color: widget.theme.primaryColor),
      ),
    );
  }
}

// ================= MATCH DETAIL SCREEN =================
class MatchDetailScreen extends StatefulWidget {
  final Tournament tournament;
  final MatchFixture match;
  final Team homeTeam;
  final Team awayTeam;
  final LeagueTheme theme;

  const MatchDetailScreen({
    super.key,
    required this.tournament,
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.theme,
  });

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late TextEditingController _homeScoreCtrl;
  late TextEditingController _awayScoreCtrl;
  List<MatchGoalEvent> _scorers = [];
  List<MatchCleanSheet> _cleanSheets = [];

  @override
  void initState() {
    super.initState();
    _homeScoreCtrl = TextEditingController(
      text: widget.match.homeScore?.toString() ?? '',
    );
    _awayScoreCtrl = TextEditingController(
      text: widget.match.awayScore?.toString() ?? '',
    );
    _scorers = List.from(widget.match.scorers);
    _cleanSheets = List.from(widget.match.cleanSheets);
  }

  void _addScorer(String teamId) {
    setState(
      () => _scorers.add(
        MatchGoalEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          teamId: teamId,
          playerName: '',
        ),
      ),
    );
  }

  void _saveMatch() {
    final hs = int.tryParse(_homeScoreCtrl.text);
    final as_ = int.tryParse(_awayScoreCtrl.text);

    if (hs == null || as_ == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid scores')),
      );
      return;
    }

    _cleanSheets.clear();
    if (as_ == 0)
      _cleanSheets.add(
        MatchCleanSheet(
          teamId: widget.homeTeam.id,
          goalkeeperName: 'GK (${widget.homeTeam.name})',
        ),
      );
    if (hs == 0)
      _cleanSheets.add(
        MatchCleanSheet(
          teamId: widget.awayTeam.id,
          goalkeeperName: 'GK (${widget.awayTeam.name})',
        ),
      );

    setState(() {
      widget.match.homeScore = hs;
      widget.match.awayScore = as_;
      widget.match.isCompleted = true;
      widget.match.scorers = _scorers
          .where((s) => s.playerName.trim().isNotEmpty)
          .toList();
      widget.match.cleanSheets = _cleanSheets;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const Text(
          'Update Match',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveMatch,
            child: Text(
              'SAVE',
              style: TextStyle(
                color: widget.theme.accentColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTeamScoreInput(widget.homeTeam, _homeScoreCtrl),
                  const Text(
                    ' - ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                  _buildTeamScoreInput(widget.awayTeam, _awayScoreCtrl),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GOAL SCORERS',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildScorerList(widget.homeTeam),
                  const SizedBox(height: 16),
                  _buildScorerList(widget.awayTeam),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScoreInput(Team team, TextEditingController ctrl) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipOval(
            child: team.logoPath != null && File(team.logoPath!).existsSync()
                ? Image.file(File(team.logoPath!), fit: BoxFit.contain)
                : Icon(Icons.shield, color: widget.theme.primaryColor),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 80,
          child: Text(
            team.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 70,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScorerList(Team team) {
    final teamScorers = _scorers.where((s) => s.teamId == team.id).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              team.name,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: widget.theme.primaryColor,
                fontSize: 12,
              ),
            ),
            TextButton.icon(
              onPressed: () => _addScorer(team.id),
              icon: const Icon(Icons.add, size: 14),
              label: const Text(
                'Add Scorer',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        if (teamScorers.isEmpty)
          const Text(
            'No scorers added yet',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ...teamScorers.map((scorer) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => scorer.playerName = val,
                    controller: TextEditingController(text: scorer.playerName)
                      ..selection = TextSelection.collapsed(
                        offset: scorer.playerName.length,
                      ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Player Name',
                      hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _scorers.remove(scorer)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

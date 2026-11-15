import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_models.dart';
import '../themes/league_themes.dart';
import '../services/tournament_engine.dart';
import 'fixtures_tab.dart';
import 'teams_tab.dart';
import 'award_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Tournament tournament;
  const DashboardScreen({super.key, required this.tournament});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isFullView = false;
  late LeagueTheme theme;

  @override
  void initState() {
    super.initState();
    theme = LeagueThemes.getTheme(widget.tournament.leagueId);
  }

  void _refreshData() {
    setState(() {});
  }

  // ================= SHARE & FIREBASE UPLOAD FUNCTION =================
  Future<void> _shareTournament() async {
    final standings = TournamentEngine.calculateStandings(widget.tournament);

    // 1. വാട്സാപ്പിലും മറ്റും ഷെയർ ചെയ്യാൻ പാകത്തിന് പോയിന്റ് ടേബിളും വെബ് ലിങ്കും ഉണ്ടാക്കുന്നു
    StringBuffer sb = StringBuffer();
    sb.writeln('🏆 *${widget.tournament.name.toUpperCase()}* 🏆');
    sb.writeln('📊 *Standings Table*\n');
    sb.writeln('Pos | Team | MP | GD | PTS');
    sb.writeln('------------------------------------');

    for (int i = 0; i < standings.length; i++) {
      final st = standings[i];
      final gdStr = st.gd > 0 ? '+${st.gd}' : '${st.gd}';
      sb.writeln(
        '${i + 1}. ${st.team.name} | ${st.mp} | $gdStr | *${st.points}*',
      );
    }

    // വ്യൂവർ സ്ക്രീനിലേക്കുള്ള ഡയറക്ട് ലിങ്ക്
    sb.writeln('\n🔗 *Live Updates, Stats & Awards:*');
    sb.writeln('https://yb-tournament-app.web.app/?id=${widget.tournament.id}');
    sb.writeln('\n⚡ _Generated via YB eFootball Manager_');

    final shareText = sb.toString();

    // 2. ലോഡിങ് കാണിക്കുന്നു
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool cloudSaved = false;
    try {
      // 3. Firebase Cloud Firestore-ലേക്ക് ഡാറ്റ അപ്‌ലോഡ് ചെയ്യുന്നു (Awards ഡാറ്റ ഉൾപ്പെടെ)
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournament.id)
          .set({
            'id': widget.tournament.id,
            'name': widget.tournament.name,
            'leagueId': widget.tournament.leagueId,
            'formatType': widget.tournament.formatType,
            'updatedAt': FieldValue.serverTimestamp(),
            'standingsText': shareText,
            'standings': standings
                .map(
                  (s) => {
                    'teamName': s.team.name,
                    'mp': s.mp,
                    'w': s.w,
                    'd': s.d,
                    'l': s.l,
                    'gf': s.gf,
                    'ga': s.ga,
                    'gd': s.gd,
                    'pts': s.points,
                  },
                )
                .toList(),

            // --- അവാർഡുകൾ ഫയർബേസിലേക്ക് ആഡ് ചെയ്യുന്നു ---
            'topScorers':
                TournamentEngine.calculateTopScorers(widget.tournament)
                    .map(
                      (s) => {
                        'playerName': s.playerName,
                        'teamName': s.teamName,
                        'goals': s.count,
                      },
                    )
                    .toList(),
            'cleanSheets':
                TournamentEngine.calculateCleanSheets(widget.tournament)
                    .map(
                      (s) => {
                        'playerName': s.playerName,
                        'teamName': s.teamName,
                        'cleanSheets': s.count,
                      },
                    )
                    .toList(),
          });
      cloudSaved = true;
    } catch (e) {
      debugPrint('Firebase Upload Error: $e');
    }

    if (!mounted) return;
    Navigator.pop(context); // ലോഡിങ് ക്ലോസ് ചെയ്യുന്നു

    // 4. ഷെയർ ഓപ്ഷൻ പോപ്പ്-അപ്പ് കാണിക്കുന്നു
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              cloudSaved ? Icons.cloud_done : Icons.share,
              color: cloudSaved ? Colors.green : theme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cloudSaved ? 'Live Synced & Share' : 'Share Standings',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cloudSaved)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '✅ ഫയർബേസിലേക്ക് അപ്‌ലോഡ് ആയി!\nUnique Link Generated.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              const Text(
                'ലിങ്കും പോയിന്റ് ടേബിളും കോപ്പി ചെയ്ത് ഷെയർ ചെയ്യാം:',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  shareText,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Data & Link'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'കോപ്പി ചെയ്തു! ഇനി വാട്സാപ്പിൽ പേസ്റ്റ് ചെയ്യാം.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child:
                  widget.tournament.leagueLogoPath != null &&
                      File(widget.tournament.leagueLogoPath!).existsSync()
                  ? Image.file(
                      File(widget.tournament.leagueLogoPath!),
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      Icons.emoji_events,
                      color: theme.primaryColor,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.tournament.name,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${widget.tournament.teams.length} Teams • ${widget.tournament.formatType}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF0F172A)),
            tooltip: 'Share Standings',
            onPressed: _shareTournament,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildStandingsTab(),
          FixturesTab(
            tournament: widget.tournament,
            theme: theme,
            onRefresh: _refreshData,
          ),
          _buildAwardsTab(),
          TeamsTab(tournament: widget.tournament, theme: theme),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: theme.primaryColor,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_numbered_rtl),
              label: 'Standings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer),
              label: 'Fixtures',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Awards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              label: 'Teams',
            ),
          ],
        ),
      ),
    );
  }

  // ================= STANDINGS & BRACKET TAB =================
  Widget _buildStandingsTab() {
    final allStandings = TournamentEngine.calculateStandings(widget.tournament);
    final knockoutMatches = widget.tournament.matches
        .where((m) => m.stage == 'Knockout')
        .toList();

    if (allStandings.isEmpty) {
      return const Center(
        child: Text(
          'No standings available',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (widget.tournament.formatType == 'Group + Knockout')
            ..._buildGroupTables(allStandings)
          else
            _buildSingleTable('League Table', allStandings),

          if (knockoutMatches.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🏆 KNOCKOUT TREE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBracketGraphics(knockoutMatches),
            const SizedBox(height: 30),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildGroupTables(List<TeamStanding> allStandings) {
    Map<String, List<TeamStanding>> groups = {};
    for (var s in allStandings) {
      String g = s.team.groupId ?? 'Group A';
      groups.putIfAbsent(g, () => []).add(s);
    }

    var sortedKeys = groups.keys.toList()..sort();
    List<Widget> tables = [];

    for (var g in sortedKeys) {
      tables.add(_buildSingleTable(g, groups[g]!, isGroup: true));
      tables.add(const SizedBox(height: 20));
    }
    return tables;
  }

  Widget _buildSingleTable(
    String title,
    List<TeamStanding> standings, {
    bool isGroup = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                  ),
                ),
                if (!isGroup || title == 'Group A')
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _isFullView,
                      onChanged: (val) => setState(() => _isFullView = val),
                      activeThumbColor: theme.primaryColor,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: Column(
                  children: [
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        children: const [
                          SizedBox(
                            width: 22,
                            child: Text(
                              '#',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'CLUB',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...standings.asMap().entries.map((entry) {
                      int index = entry.key;
                      var st = entry.value;

                      int qualifiers = isGroup
                          ? widget.tournament.qualifiersPerGroup
                          : widget.tournament.playoffQualifiers;
                      final isTopN =
                          (widget.tournament.formatType != 'League Only' &&
                              widget.tournament.formatType !=
                                  'Knockout Only') &&
                          index < qualifiers;

                      return Container(
                        height: 44,
                        color: isTopN
                            ? theme.primaryColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: isTopN
                                      ? theme.primaryColor
                                      : const Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child:
                                  st.team.logoPath != null &&
                                      File(st.team.logoPath!).existsSync()
                                  ? Image.file(
                                      File(st.team.logoPath!),
                                      fit: BoxFit.contain,
                                    )
                                  : Icon(
                                      Icons.shield,
                                      size: 16,
                                      color: theme.primaryColor,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                st.team.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        padding: const EdgeInsets.only(right: 12),
                        color: const Color(0xFFF8FAFC),
                        child: Row(
                          children: [
                            _statHeader('MP', 22),
                            _statHeader('W', 22),
                            _statHeader('D', 22),
                            _statHeader('L', 22),
                            if (_isFullView) _statHeader('GF', 24),
                            if (_isFullView) _statHeader('GA', 24),
                            _statHeader('+/-', 26),
                            _statHeader('PTS', 28, isPts: true),
                            if (_isFullView)
                              const SizedBox(
                                width: 80,
                                child: Text(
                                  'FORM',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ...standings.asMap().entries.map((entry) {
                        int index = entry.key;
                        var st = entry.value;
                        int qualifiers = isGroup
                            ? widget.tournament.qualifiersPerGroup
                            : widget.tournament.playoffQualifiers;
                        final isTopN =
                            (widget.tournament.formatType != 'League Only' &&
                                widget.tournament.formatType !=
                                    'Knockout Only') &&
                            index < qualifiers;

                        return Container(
                          height: 44,
                          color: isTopN
                              ? theme.primaryColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            children: [
                              _statValue(st.mp.toString(), 22),
                              _statValue(st.w.toString(), 22),
                              _statValue(st.d.toString(), 22),
                              _statValue(st.l.toString(), 22),
                              if (_isFullView) _statValue(st.gf.toString(), 24),
                              if (_isFullView) _statValue(st.ga.toString(), 24),
                              _statValue(
                                st.gd > 0 ? '+${st.gd}' : st.gd.toString(),
                                26,
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  st.points.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: theme.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (_isFullView)
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: st.last5.take(5).map((result) {
                                      Color bgColor = result == 'W'
                                          ? const Color(0xFF22C55E)
                                          : (result == 'D'
                                                ? const Color(0xFFEAB308)
                                                : const Color(0xFFEF4444));
                                      return Container(
                                        margin: const EdgeInsets.only(right: 2),
                                        width: 13,
                                        height: 13,
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          result,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statHeader(String text, double width, {bool isPts = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: isPts ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          fontSize: isPts ? 12 : 10,
        ),
      ),
    );
  }

  Widget _statValue(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
          fontSize: 12,
        ),
      ),
    );
  }

  // ================= DYNAMIC FULL BRACKET GRAPHICS WITH CONNECTING LINES =================
  Widget _buildBracketGraphics(List<MatchFixture> knockouts) {
    Map<int, List<MatchFixture>> rounds = {};
    for (var m in knockouts) {
      rounds.putIfAbsent(m.round, () => []).add(m);
    }

    var sortedRounds = rounds.keys.toList()..sort();
    int firstRound = sortedRounds.first;
    int initialMatches = rounds[firstRound]!.length;

    bool isBinaryTree = widget.tournament.formatType.contains('Knockout');
    List<List<MatchFixture>> fullTree = [];

    if (isBinaryTree) {
      int currentRound = firstRound;
      int currentMatchesCount = initialMatches;

      while (currentMatchesCount >= 1) {
        if (rounds.containsKey(currentRound)) {
          fullTree.add(rounds[currentRound]!);
        } else {
          List<MatchFixture> dummyMatches = [];
          String title = currentMatchesCount == 1
              ? 'FINAL'
              : (currentMatchesCount == 2 ? 'SEMI FINAL' : 'QUARTER FINAL');
          if (currentMatchesCount > 4) {
            title = 'ROUND OF ${currentMatchesCount * 2}';
          }

          for (int i = 0; i < currentMatchesCount; i++) {
            dummyMatches.add(
              MatchFixture(
                id: 'dummy_$i',
                round: currentRound,
                stage: 'Knockout',
                knockoutTitle: title,
                homeTeamId: 'tbd',
                awayTeamId: 'tbd',
              ),
            );
          }
          fullTree.add(dummyMatches);
        }
        if (currentMatchesCount == 1) break;
        currentMatchesCount = currentMatchesCount ~/ 2;
        currentRound++;
      }
    } else {
      for (var r in sortedRounds) {
        fullTree.add(rounds[r]!);
      }
    }

    List<int> matchesPerRound = fullTree.map((r) => r.length).toList();
    int maxMatches = matchesPerRound.isNotEmpty
        ? matchesPerRound.reduce((a, b) => a > b ? a : b)
        : 1;

    double cardHeight = 84.0;
    double verticalSpacing = 24.0;
    double totalHeight = (maxMatches * (cardHeight + verticalSpacing)) + 60;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: totalHeight < 200 ? 200 : totalHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomPaint(
          painter: BracketPainter(
            matchesPerRound: matchesPerRound,
            lineColor: theme.primaryColor.withValues(alpha: 0.3),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: fullTree.map((matches) {
              String title =
                  matches.first.knockoutTitle ?? 'Round ${matches.first.round}';

              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 40),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: matches
                            .map((m) => _buildBracketMatchCard(m))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBracketMatchCard(MatchFixture match) {
    Team getTeam(String id) {
      if (id == 'tbd') return Team(id: 'tbd', name: 'TBD');
      return widget.tournament.teams.firstWhere(
        (t) => t.id == id,
        orElse: () => Team(id: '', name: 'TBD'),
      );
    }

    final homeTeam = getTeam(match.homeTeamId);
    final awayTeam = getTeam(match.awayTeamId);

    bool homeWon =
        match.isCompleted && (match.homeScore ?? 0) > (match.awayScore ?? 0);
    bool awayWon =
        match.isCompleted && (match.awayScore ?? 0) > (match.homeScore ?? 0);

    return Container(
      height: 84,
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _bracketTeamRow(
            homeTeam,
            match.homeScore,
            homeWon,
            match.isCompleted && match.homeTeamId != 'tbd',
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0), thickness: 1),
          _bracketTeamRow(
            awayTeam,
            match.awayScore,
            awayWon,
            match.isCompleted && match.awayTeamId != 'tbd',
          ),
        ],
      ),
    );
  }

  Widget _bracketTeamRow(
    Team team,
    int? score,
    bool isWinner,
    bool isCompleted,
  ) {
    Color bgColor = isCompleted
        ? (isWinner ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2))
        : Colors.transparent;
    Color textColor = isCompleted
        ? (isWinner ? const Color(0xFF166534) : const Color(0xFF991B1B))
        : const Color(0xFF334155);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              child:
                  team.logoPath != null &&
                      File(team.logoPath!).existsSync() &&
                      team.id != 'tbd'
                  ? Image.file(File(team.logoPath!), fit: BoxFit.contain)
                  : Icon(
                      Icons.shield,
                      size: 14,
                      color: team.id == 'tbd'
                          ? const Color(0xFFCBD5E1)
                          : theme.primaryColor,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isWinner ? FontWeight.w900 : FontWeight.w700,
                  color: (isCompleted && !isWinner) || team.id == 'tbd'
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F172A),
                  fontSize: 12,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                team.id == 'tbd' ? '-' : (score?.toString() ?? '-'),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= AWARDS TAB =================
  Widget _buildAwardsTab() {
    final topScorers = TournamentEngine.calculateTopScorers(widget.tournament);
    final cleanSheets = TournamentEngine.calculateCleanSheets(
      widget.tournament,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPremiumAwardCard(
            title: 'Golden Boot - Top Scorers',
            icon: Icons.sports_soccer,
            stats: topScorers,
            headerColor: const Color(0xFFFEF08A),
            textColor: const Color(0xFF854D0E),
            isGoal: true,
          ),
          const SizedBox(height: 16),
          _buildPremiumAwardCard(
            title: 'Golden Glove - Clean Sheets',
            icon: Icons.front_hand,
            stats: cleanSheets,
            headerColor: const Color(0xFFBAE6FD),
            textColor: const Color(0xFF0369A1),
            isGoal: false,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAwardCard({
    required String title,
    required IconData icon,
    required List<PlayerStat> stats,
    required Color headerColor,
    required Color textColor,
    required bool isGoal,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AwardDetailsScreen(
              title: title,
              icon: icon,
              stats: stats,
              headerColor: headerColor,
              textColor: textColor,
              isGoal: isGoal,
              theme: theme,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: headerColor.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'View full ranking list',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= BRACKET CONNECTING LINES =================
class BracketPainter extends CustomPainter {
  final List<int> matchesPerRound;
  final Color lineColor;

  BracketPainter({required this.matchesPerRound, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    double columnWidth = 220.0;
    double horizontalSpacing = 40.0;
    double topOffset = 50.0;
    double availableHeight = size.height - topOffset;

    for (int i = 0; i < matchesPerRound.length - 1; i++) {
      int currentMatches = matchesPerRound[i];
      int nextMatches = matchesPerRound[i + 1];

      double currentX = (i * (columnWidth + horizontalSpacing)) + columnWidth;
      double nextX = currentX + horizontalSpacing;

      double currentSpacing = availableHeight / currentMatches;
      double nextSpacing = availableHeight / nextMatches;

      for (int j = 0; j < currentMatches; j++) {
        double startY = topOffset + (j * currentSpacing) + (currentSpacing / 2);

        int nextIdx = (currentMatches == nextMatches)
            ? j
            : (j ~/ (currentMatches / nextMatches).ceil());
        if (nextIdx >= nextMatches) nextIdx = nextMatches - 1;

        double endY = topOffset + (nextIdx * nextSpacing) + (nextSpacing / 2);
        double midX = currentX + (horizontalSpacing / 2);

        Path path = Path();
        path.moveTo(currentX, startY);
        path.lineTo(midX, startY);
        path.lineTo(midX, endY);
        path.lineTo(nextX, endY);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

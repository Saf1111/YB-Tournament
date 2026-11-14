import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../themes/league_themes.dart';

class ViewerScreen extends StatefulWidget {
  final String tournamentId;
  const ViewerScreen({super.key, required this.tournamentId});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  int _currentIndex = 0;
  bool _isFullView = false;
  String _selectedTeamFilter = 'clubs';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tournaments')
            .doc(widget.tournamentId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Scaffold(
              body: Center(
                child: Text('Tournament not found or no data available.'),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['name'] ?? 'Tournament';
          final String formatType = data['formatType'] ?? 'League Only';
          final String leagueId = data['leagueId'] ?? 'custom';
          final LeagueTheme theme = LeagueThemes.getTheme(leagueId);

          List<dynamic> rawStandings = data['standings'] ?? [];
          // അവാർഡ് ഡാറ്റ ഫയർബേസിൽ നിന്നും എടുക്കുന്നു
          List<dynamic> topScorers = data['topScorers'] ?? [];
          List<dynamic> cleanSheets = data['cleanSheets'] ?? [];

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Live Updates • $formatType',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _buildStandingsTab(rawStandings, theme),
                _buildAwardsTab(topScorers, cleanSheets, theme),
                _buildTeamsTab(rawStandings, theme),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0F172A),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_numbered_rtl),
              label: 'Standings',
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

  // ================= 1. STANDINGS TAB =================
  Widget _buildStandingsTab(List<dynamic> standings, LeagueTheme theme) {
    if (standings.isEmpty) {
      return const Center(
        child: Text(
          'No standings available',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: _buildSingleTable('League Table', standings, theme),
    );
  }

  Widget _buildSingleTable(
    String title,
    List<dynamic> standings,
    LeagueTheme theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
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
                Transform.scale(
                  scale: 0.85,
                  child: Switch(
                    value: _isFullView,
                    onChanged: (val) => setState(() => _isFullView = val),
                    activeColor: theme.primaryColor,
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
                      return Container(
                        height: 44,
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 22,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.shield,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                st['teamName'] ?? 'Unknown',
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
                          ],
                        ),
                      ),
                      ...standings.map((st) {
                        return Container(
                          height: 44,
                          color: Colors.transparent,
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            children: [
                              _statValue(st['mp']?.toString() ?? '0', 22),
                              _statValue(st['w']?.toString() ?? '0', 22),
                              _statValue(st['d']?.toString() ?? '0', 22),
                              _statValue(st['l']?.toString() ?? '0', 22),
                              if (_isFullView)
                                _statValue(st['gf']?.toString() ?? '0', 24),
                              if (_isFullView)
                                _statValue(st['ga']?.toString() ?? '0', 24),
                              _statValue(st['gd']?.toString() ?? '0', 26),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  st['pts']?.toString() ?? '0',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: theme.primaryColor,
                                    fontSize: 13,
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

  // ================= 2. AWARDS TAB =================
  Widget _buildAwardsTab(
    List<dynamic> topScorers,
    List<dynamic> cleanSheets,
    LeagueTheme theme,
  ) {
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
    required List<dynamic> stats,
    required Color headerColor,
    required Color textColor,
    required bool isGoal,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewerAwardDetailsScreen(
              title: title,
              icon: icon,
              stats: stats,
              headerColor: headerColor,
              textColor: textColor,
              isGoal: isGoal,
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
              color: Colors.black.withOpacity(0.03),
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
                color: headerColor.withOpacity(0.4),
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

  // ================= 3. TEAMS TAB (Stats) =================
  Widget _buildTeamsTab(List<dynamic> standings, LeagueTheme theme) {
    if (standings.isEmpty) return const SizedBox();

    List<dynamic> sortedStandings = List.from(standings);

    sortedStandings.sort((a, b) {
      int mpA = a['mp'] ?? 0;
      int mpB = b['mp'] ?? 0;

      double getGpm(dynamic s, int mp) => mp > 0 ? (s['gf'] ?? 0) / mp : 0.0;
      double getGcpm(dynamic s, int mp) => mp > 0 ? (s['ga'] ?? 0) / mp : 0.0;
      double getRating(dynamic s, int mp) =>
          mp > 0 ? ((s['pts'] ?? 0) / (mp * 3)) * 10 : 0.0;

      if (_selectedTeamFilter == 'gpm') {
        return getGpm(b, mpB).compareTo(getGpm(a, mpA));
      } else if (_selectedTeamFilter == 'gcpm') {
        return getGcpm(a, mpA).compareTo(getGcpm(b, mpB));
      } else if (_selectedTeamFilter == 'rating') {
        return getRating(b, mpB).compareTo(getRating(a, mpA));
      }
      return 0;
    });

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildFilterChip('Clubs', 'clubs', theme),
              const SizedBox(width: 8),
              _buildFilterChip('Goals per match', 'gpm', theme),
              const SizedBox(width: 8),
              _buildFilterChip('Rating', 'rating', theme),
              const SizedBox(width: 8),
              _buildFilterChip('Goals conceded', 'gcpm', theme),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedStandings.length,
            itemBuilder: (context, index) {
              var st = sortedStandings[index];
              int mp = st['mp'] ?? 0;

              String statValue = '';
              if (_selectedTeamFilter == 'gpm') {
                double val = mp > 0 ? (st['gf'] ?? 0) / mp : 0.0;
                statValue = val.toStringAsFixed(1);
              } else if (_selectedTeamFilter == 'gcpm') {
                double val = mp > 0 ? (st['ga'] ?? 0) / mp : 0.0;
                statValue = val.toStringAsFixed(1);
              } else if (_selectedTeamFilter == 'rating') {
                double val = mp > 0 ? ((st['pts'] ?? 0) / (mp * 3)) * 10 : 0.0;
                statValue = val.toStringAsFixed(1);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.shield, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        st['teamName'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (statValue.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statValue,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: theme.primaryColor,
                            fontSize: 13,
                          ),
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

  Widget _buildFilterChip(String label, String value, LeagueTheme theme) {
    bool isSelected = _selectedTeamFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTeamFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ================= VIEWER AWARD DETAILS SCREEN =================
class ViewerAwardDetailsScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<dynamic> stats;
  final Color headerColor;
  final Color textColor;
  final bool isGoal;

  const ViewerAwardDetailsScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.stats,
    required this.headerColor,
    required this.textColor,
    required this.isGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      body: stats.isEmpty
          ? const Center(
              child: Text(
                "No records yet.",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                var st = stats[index];
                String pName = st['playerName'] ?? 'Unknown';
                String tName = st['teamName'] ?? 'Unknown';
                String val = isGoal
                    ? (st['goals']?.toString() ?? '0')
                    : (st['cleanSheets']?.toString() ?? '0');

                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: headerColor),
                      boxShadow: [
                        BoxShadow(
                          color: headerColor.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          size: 48,
                          color: headerColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          pName.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          tName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: headerColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            val,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      Icon(Icons.person, color: Colors.grey.shade400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              tName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: headerColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          val,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tournament_models.dart';
import '../themes/league_themes.dart';
import '../services/tournament_engine.dart';
import 'team_profile_screen.dart';

class TeamsTab extends StatefulWidget {
  final Tournament tournament;
  final LeagueTheme theme;

  const TeamsTab({super.key, required this.tournament, required this.theme});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  int _selectedFilter = 0;
  // 0: Clubs, 1: Goals per match, 2: Rating, 3: Goals conceded per match

  final List<String> _filters = [
    'Clubs',
    'Goals per match',
    'Rating',
    'Goals conceded per match',
  ];

  @override
  Widget build(BuildContext context) {
    // സ്റ്റാറ്റ്സ് കാണിക്കാനായി പോയിന്റ് ടേബിൾ ഡാറ്റ എടുക്കുന്നു
    List<TeamStanding> standings = TournamentEngine.calculateStandings(
      widget.tournament,
    );

    // നമ്മൾ സെലക്ട് ചെയ്ത ചിപ്പ് അനുസരിച്ച് ലിസ്റ്റ് അറേഞ്ച് ചെയ്യുന്നു
    if (_selectedFilter == 0) {
      // Clubs (ഡിഫോൾട്ട് റാങ്കിംഗ് ഓർഡർ)
    } else if (_selectedFilter == 1) {
      // Goals per match (ഏറ്റവും കൂടുതൽ ഗോൾ അടിച്ചവർ മുകളിൽ)
      standings.sort((a, b) {
        double aGpm = a.mp > 0 ? a.gf / a.mp : 0;
        double bGpm = b.mp > 0 ? b.gf / b.mp : 0;
        return bGpm.compareTo(aGpm);
      });
    } else if (_selectedFilter == 2) {
      // Rating (കളിച്ച മാച്ചും പോയിന്റും വെച്ച് 10-ൽ ഒരു റേറ്റിംഗ് ഉണ്ടാക്കുന്നു)
      standings.sort((a, b) {
        double aR = a.mp > 0 ? 5.0 + ((a.points / (a.mp * 3)) * 5.0) : 0;
        double bR = b.mp > 0 ? 5.0 + ((b.points / (b.mp * 3)) * 5.0) : 0;
        return bR.compareTo(aR);
      });
    } else if (_selectedFilter == 3) {
      // Goals conceded (ഏറ്റവും കുറവ് ഗോൾ വഴങ്ങിയവർ മുകളിൽ)
      standings.sort((a, b) {
        double aGc = a.mp > 0 ? a.ga / a.mp : 0;
        double bGc = b.mp > 0 ? b.ga / b.mp : 0;
        return aGc.compareTo(bGc);
      });
    }

    return Column(
      children: [
        // മുകളിലെ സ്ക്രോൾ ചെയ്യാവുന്ന മെനു (Filter Chips)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: _filters.asMap().entries.map((entry) {
              int idx = entry.key;
              String label = entry.value;
              bool isSelected = _selectedFilter == idx;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: widget.theme.primaryColor,
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? widget.theme.primaryColor
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFilter = idx;
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // താഴെയുള്ള ക്ലീൻ ലിസ്റ്റ് വ്യൂ (Teams List)
        Expanded(
          child: standings.isEmpty
              ? const Center(
                  child: Text(
                    'No teams found',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: standings.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final st = standings[index];

                    // സെലക്ട് ചെയ്ത ചിപ്പ് അനുസരിച്ച് കാണിക്കേണ്ട നമ്പറുകൾ (Stat Value)
                    String statValue = '';
                    if (_selectedFilter == 1) {
                      statValue = st.mp > 0
                          ? (st.gf / st.mp).toStringAsFixed(1)
                          : '0.0';
                    } else if (_selectedFilter == 2) {
                      statValue = st.mp > 0
                          ? (5.0 + ((st.points / (st.mp * 3)) * 5.0))
                                .toStringAsFixed(1)
                          : '-';
                    } else if (_selectedFilter == 3) {
                      statValue = st.mp > 0
                          ? (st.ga / st.mp).toStringAsFixed(1)
                          : '0.0';
                    }

                    return InkWell(
                      onTap: () {
                        // ടീമിൽ ക്ലിക്ക് ചെയ്താൽ ടീം പ്രൊഫൈലിലേക്ക് പോകും
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamProfileScreen(
                              tournament: widget.tournament,
                              team: st.team,
                              theme: widget.theme,
                            ),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF94A3B8),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: ClipOval(
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
                                        color: widget.theme.primaryColor,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                st.team.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (_selectedFilter != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.theme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statValue,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: widget.theme.primaryColor,
                                    fontSize: 13,
                                  ),
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
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/tournament_models.dart';
import '../services/tournament_engine.dart';
import '../themes/league_themes.dart';
import 'dashboard_screen.dart';

class TournamentSetupScreen extends StatefulWidget {
  final String initialLeagueId;

  const TournamentSetupScreen({super.key, required this.initialLeagueId});

  @override
  State<TournamentSetupScreen> createState() => _TournamentSetupScreenState();
}

class _TournamentSetupScreenState extends State<TournamentSetupScreen> {
  late String _selectedLeagueId;
  late TextEditingController _leagueNameCtrl;
  late TextEditingController _seasonSubtitleCtrl;
  String? _leagueLogoPath;

  int _teamCount = 8;
  String _formatType = 'League Only';
  int _roundsMultiplier = 2; // Default Double (Home & Away)
  int _playoffQualifiers = 4;
  int _qualifiersPerGroup =
      2; // ഗ്രൂപ്പിൽ നിന്ന് എത്ര പേർ ക്വാളിഫൈ ആവണം എന്ന് തീരുമാനിക്കാൻ

  final List<Team> _teams = [];
  final List<TextEditingController> _teamControllers = [];

  final List<String> _defaultIslNames = [
    'Kerala Blasters FC',
    'Mohun Bagan SG',
    'FC Goa',
    'Bengaluru FC',
    'Mumbai City FC',
    'Odisha FC',
    'Chennaiyin FC',
    'East Bengal FC',
    'NorthEast United',
    'Jamshedpur FC',
    'Punjab FC',
    'Mohammedan SC',
    'Hyderabad FC',
    'Gokulam Kerala FC',
    'Calicut FC',
    'Malappuram FC',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLeagueId = widget.initialLeagueId;
    final theme = LeagueThemes.getTheme(_selectedLeagueId);
    _leagueNameCtrl = TextEditingController(text: theme.shortName);
    _seasonSubtitleCtrl = TextEditingController(text: theme.name);
    _syncTeamsList(_teamCount);
  }

  void _syncTeamsList(int targetCount) {
    while (_teams.length < targetCount) {
      int idx = _teams.length;
      String defaultName = idx < _defaultIslNames.length
          ? _defaultIslNames[idx]
          : 'Team ${idx + 1}';
      final team = Team(
        id: 'team_${DateTime.now().microsecondsSinceEpoch}_$idx',
        name: defaultName,
      );
      _teams.add(team);
      _teamControllers.add(TextEditingController(text: defaultName));
    }
    while (_teams.length > targetCount) {
      _teams.removeLast();
      _teamControllers.removeLast().dispose();
    }
    setState(() {
      _teamCount = _teams.length;
    });
  }

  void _addSingleTeam() {
    if (_teams.length >= 24)
      return; // അല്ലെങ്കിൽ കൂടുതൽ ടീമുകൾ വേണമെങ്കിൽ ഇവിടെ മാറ്റാം
    _syncTeamsList(_teams.length + 1);
  }

  void _removeSingleTeam(int index) {
    if (_teams.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 2 teams required!')),
      );
      return;
    }
    setState(() {
      _teams.removeAt(index);
      _teamControllers.removeAt(index).dispose();
      _teamCount = _teams.length;
    });
  }

  Future<void> _pickLeagueLogo() async {
    final path = await TournamentEngine.pickAndSaveLogo();
    if (path != null) {
      setState(() => _leagueLogoPath = path);
    }
  }

  Future<void> _pickTeamLogo(int index) async {
    final path = await TournamentEngine.pickAndSaveLogo();
    if (path != null) {
      setState(() => _teams[index].logoPath = path);
    }
  }

  Future<void> _startTournament() async {
    for (int i = 0; i < _teams.length; i++) {
      final text = _teamControllers[i].text.trim();
      _teams[i].name = text.isEmpty ? 'Team ${i + 1}' : text;
    }

    final matches = TournamentEngine.generateFixtures(
      teams: _teams,
      formatType: _formatType,
      roundsMultiplier: _roundsMultiplier,
    );

    final tournament = Tournament(
      id: 'tour_${DateTime.now().millisecondsSinceEpoch}',
      leagueId: _selectedLeagueId,
      name: _leagueNameCtrl.text.trim().isEmpty
          ? 'ISL 2026-27'
          : _leagueNameCtrl.text.trim(),
      seasonSubtitle: _seasonSubtitleCtrl.text.trim().isEmpty
          ? 'Indian Super League'
          : _seasonSubtitleCtrl.text.trim(),
      leagueLogoPath: _leagueLogoPath,
      formatType: _formatType,
      roundsMultiplier: _roundsMultiplier,
      playoffQualifiers: _playoffQualifiers,
      qualifiersPerGroup:
          _qualifiersPerGroup, // സേവ് ചെയ്യുമ്പോൾ ഇതും കൊടുക്കുന്നു
      teams: _teams,
      matches: matches,
    );

    await TournamentEngine.saveSingleTournament(tournament);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(tournament: tournament),
      ),
    );
  }

  @override
  void dispose() {
    _leagueNameCtrl.dispose();
    _seasonSubtitleCtrl.dispose();
    for (var c in _teamControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LeagueThemes.getTheme(_selectedLeagueId);
    final teamCountOptions = List<int>.generate(23, (i) => i + 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Tournament',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickLeagueLogo,
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child:
                            _leagueLogoPath != null &&
                                File(_leagueLogoPath!).existsSync()
                            ? Image.file(
                                File(_leagueLogoPath!),
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Icons.add_photo_alternate_outlined,
                                color: theme.primaryColor,
                                size: 26,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tournament Setup',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Create & customize your league, format & teams',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Section 1: League Details Card
            _buildSectionCard(
              title: 'League Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select League Theme',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: LeagueThemes.allLeagues.map((l) {
                        final isSelected = l.id == _selectedLeagueId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(l.name),
                            selected: isSelected,
                            selectedColor: l.primaryColor,
                            backgroundColor: const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedLeagueId = l.id;
                                _leagueNameCtrl.text = l.shortName;
                                _seasonSubtitleCtrl.text = l.name;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: _leagueNameCtrl,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: _inputDecoration(
                                'League Title (e.g. ISL 2026-27)',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _seasonSubtitleCtrl,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF334155),
                              ),
                              decoration: _inputDecoration(
                                'Subtitle (e.g. Indian Super League)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _pickLeagueLogo,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child:
                                  _leagueLogoPath != null &&
                                      File(_leagueLogoPath!).existsSync()
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(13),
                                      child: Image.file(
                                        File(_leagueLogoPath!),
                                        fit: BoxFit.contain,
                                      ),
                                    )
                                  : Icon(
                                      Icons.shield_outlined,
                                      color: theme.primaryColor,
                                      size: 32,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: _pickLeagueLogo,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.image_outlined, size: 14),
                            label: const Text(
                              'Change Logo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 2: Tournament Configuration Card
            _buildSectionCard(
              title: 'Tournament Configuration',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _teamCount,
                          decoration: _inputDecoration('Number of Teams'),
                          items: teamCountOptions
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    '$c Teams',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) _syncTeamsList(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _formatType,
                          decoration: _inputDecoration('Format Type'),
                          items: const [
                            DropdownMenuItem(
                              value: 'League Only',
                              child: Text(
                                'League Only',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'League + Knockout',
                              child: Text(
                                'League + Playoffs',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Knockout',
                              child: Text(
                                'Knockout Only',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            // പുതിയതായി ചേർത്ത Group + Knockout ഓപ്ഷൻ
                            DropdownMenuItem(
                              value: 'Group + Knockout',
                              child: Text(
                                'Group + Knockout',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _formatType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // റൗണ്ടുകൾ സെലക്ട് ചെയ്യാനുള്ള ഡ്രോപ്പ്ഡൗൺ
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _roundsMultiplier,
                          decoration: _inputDecoration('Duration / Rounds'),
                          items: const [
                            DropdownMenuItem(
                              value: 1,
                              child: Text(
                                'Single (1x) - One Leg',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 2,
                              child: Text(
                                'Double (2x) - Home & Away',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3,
                              child: Text(
                                'Triple (3x) - Three Legs',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _roundsMultiplier = val);
                            }
                          },
                        ),
                      ),

                      // League + Knockout ആണെങ്കിൽ Top 4/6 ചോദിക്കാൻ
                      if (_formatType == 'League + Knockout') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _playoffQualifiers,
                            decoration: _inputDecoration('Qualification Line'),
                            items: const [
                              DropdownMenuItem(
                                value: 4,
                                child: Text(
                                  'Top 4 Qualify',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 6,
                                child: Text(
                                  'Top 6 Qualify',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _playoffQualifiers = val);
                            },
                          ),
                        ),
                      ],

                      // Group + Knockout ആണെങ്കിൽ ഓരോ ഗ്രൂപ്പിൽ നിന്നും എത്ര പേർ പോകണം എന്ന് ചോദിക്കാൻ
                      if (_formatType == 'Group + Knockout') ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _qualifiersPerGroup,
                            decoration: _inputDecoration(
                              'Qualifiers (per group)',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 1,
                                child: Text(
                                  'Top 1 Advances',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 2,
                                child: Text(
                                  'Top 2 Advances',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _qualifiersPerGroup = val);
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Section 3: Team Registration List
            _buildSectionCard(
              title: 'Team Registration (${_teams.length})',
              trailing: TextButton.icon(
                onPressed: _addSingleTeam,
                icon: const Icon(Icons.add_circle, size: 18),
                label: const Text(
                  'Add Team',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final team = _teams[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _pickTeamLogo(index),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: ClipOval(
                              child:
                                  team.logoPath != null &&
                                      File(team.logoPath!).existsSync()
                                  ? Image.file(
                                      File(team.logoPath!),
                                      fit: BoxFit.contain,
                                    )
                                  : Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 18,
                                      color: theme.primaryColor,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _teamControllers[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter Team Name',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _pickTeamLogo(index),
                          icon: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF475569),
                            size: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeSingleTeam(index),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFE11D48),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            onPressed: _startTournament,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              'START TOURNAMENT',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}

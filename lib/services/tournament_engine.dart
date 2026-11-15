import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/tournament_models.dart';

class TournamentEngine {
  static const String _storageKey = 'yb_efootball_tournaments_v1';

  // 1. Pick PNG Logo from Gallery
  static Future<String?> pickAndSaveLogo() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Adjust Logo',
          toolbarColor: const Color(0xFF0A1D56),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: true,
        ),
        IOSUiSettings(title: 'Adjust Logo', aspectRatioLockEnabled: false),
      ],
    );

    if (croppedFile == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final logosDir = Directory('${appDir.path}/logos');
    if (!await logosDir.exists()) {
      await logosDir.create(recursive: true);
    }

    final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
    final savedFile = await File(
      croppedFile.path,
    ).copy('${logosDir.path}/$fileName');
    return savedFile.path;
  }

  // 2. Load & Save Tournaments
  static Future<List<Tournament>> loadTournaments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Tournament.fromJson(e)).toList();
  }

  static Future<void> saveTournaments(List<Tournament> tournaments) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(tournaments.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  static Future<void> saveSingleTournament(Tournament tournament) async {
    final tournaments = await loadTournaments();
    final index = tournaments.indexWhere((t) => t.id == tournament.id);
    if (index >= 0) {
      tournaments[index] = tournament;
    } else {
      tournaments.add(tournament);
    }
    await saveTournaments(tournaments);
  }

  static Future<void> deleteTournament(String id) async {
    final tournaments = await loadTournaments();
    tournaments.removeWhere((t) => t.id == id);
    await saveTournaments(tournaments);
  }

  // 3. Generate Fixtures (League, Knockout, Group+Knockout)
  static List<MatchFixture> generateFixtures({
    required List<Team> teams,
    bool isDoubleRoundRobin = false,
    int roundsMultiplier = 1,
    int roundsCount = 1,
    String formatType = 'League + Playoffs',
  }) {
    final isDouble =
        isDoubleRoundRobin || roundsMultiplier == 2 || roundsCount == 2;

    if (formatType == 'Knockout Only' || formatType == 'Knockout') {
      return _generateInitialKnockout(teams);
    }

    if (formatType == 'Group + Knockout') {
      return _generateGroupStage(teams, isDouble);
    }

    List<MatchFixture> matches = [];
    if (teams.length < 2) return matches;

    List<Team> t = List.from(teams);
    if (t.length % 2 != 0) {
      t.add(Team(id: 'bye', name: 'BYE'));
    }

    int numDays = t.length - 1;
    int halfSize = t.length ~/ 2;

    for (int day = 0; day < numDays; day++) {
      for (int i = 0; i < halfSize; i++) {
        Team home = t[i];
        Team away = t[t.length - 1 - i];

        if (home.id != 'bye' && away.id != 'bye') {
          matches.add(
            MatchFixture(
              id: 'm_${day}_$i',
              round: day + 1,
              homeTeamId: home.id,
              awayTeamId: away.id,
              stage: 'League',
            ),
          );
        }
      }
      t.insert(1, t.removeLast());
    }

    if (isDouble) {
      List<MatchFixture> reverseMatches = [];
      for (var match in matches) {
        reverseMatches.add(
          MatchFixture(
            id: '${match.id}_rev',
            round: match.round + numDays,
            homeTeamId: match.awayTeamId,
            awayTeamId: match.homeTeamId,
            stage: 'League',
          ),
        );
      }
      matches.addAll(reverseMatches);
    }
    return matches;
  }

  static List<MatchFixture> _generateGroupStage(
    List<Team> teams,
    bool isDouble,
  ) {
    List<MatchFixture> matches = [];
    List<String> groupNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

    int numGroups = (teams.length / 4).ceil();
    if (numGroups == 0) numGroups = 1;
    if (numGroups > groupNames.length) numGroups = groupNames.length;

    List<List<Team>> groups = List.generate(numGroups, (_) => []);

    for (int i = 0; i < teams.length; i++) {
      int gIndex = i % numGroups;
      teams[i].groupId = 'Group ${groupNames[gIndex]}';
      groups[gIndex].add(teams[i]);
    }

    int matchIdCounter = 0;
    for (int g = 0; g < groups.length; g++) {
      String gName = 'Group ${groupNames[g]}';
      List<Team> t = List.from(groups[g]);
      if (t.length < 2) continue;

      if (t.length % 2 != 0) t.add(Team(id: 'bye', name: 'BYE'));

      int numDays = t.length - 1;
      int halfSize = t.length ~/ 2;

      for (int day = 0; day < numDays; day++) {
        for (int i = 0; i < halfSize; i++) {
          Team home = t[i];
          Team away = t[t.length - 1 - i];

          if (home.id != 'bye' && away.id != 'bye') {
            matches.add(
              MatchFixture(
                id: 'g_${gName}_${matchIdCounter++}',
                round: day + 1,
                stage: 'Group Stage',
                groupId: gName,
                homeTeamId: home.id,
                awayTeamId: away.id,
              ),
            );
          }
        }
        t.insert(1, t.removeLast());
      }

      if (isDouble) {
        List<MatchFixture> reverse = [];
        for (var match in matches.where((m) => m.groupId == gName)) {
          reverse.add(
            MatchFixture(
              id: 'g_${gName}_${matchIdCounter++}_rev',
              round: match.round + numDays,
              stage: 'Group Stage',
              groupId: gName,
              homeTeamId: match.awayTeamId,
              awayTeamId: match.homeTeamId,
            ),
          );
        }
        matches.addAll(reverse);
      }
    }
    return matches;
  }

  static List<MatchFixture> _generateInitialKnockout(List<Team> teams) {
    List<MatchFixture> matches = [];
    String title = _getKnockoutStageName(teams.length);
    for (int i = 0; i + 1 < teams.length; i += 2) {
      matches.add(
        MatchFixture(
          id: 'ko_1_$i',
          round: 1,
          stage: 'Knockout',
          knockoutTitle: title,
          homeTeamId: teams[i].id,
          awayTeamId: teams[i + 1].id,
        ),
      );
    }
    return matches;
  }

  static String _getKnockoutStageName(int teamCount) {
    if (teamCount <= 2) return 'Final';
    if (teamCount <= 4) return 'Semi Final';
    if (teamCount <= 8) return 'Quarter Final';
    return 'Round of $teamCount';
  }

  // 4. Generate Playoffs (ISL Top 6, Standard, and Group+Knockout)
  static List<MatchFixture> generatePlayoffsFromStandings(
    Tournament tournament,
  ) {
    if (tournament.formatType == 'Group + Knockout') {
      return _generatePlayoffsFromGroups(tournament);
    }

    final standings = calculateStandings(tournament);
    final int topN = tournament.playoffQualifiers.clamp(2, standings.length);
    final qualified = standings.take(topN).map((s) => s.team).toList();

    List<MatchFixture> playoffs = [];
    int highestRound = tournament.matches.isEmpty
        ? 0
        : tournament.matches
              .map((m) => m.round)
              .reduce((a, b) => a > b ? a : b);
    int nextRound = highestRound + 1;

    if (topN == 6 && qualified.length >= 6) {
      playoffs.add(
        MatchFixture(
          id: 'ko_${DateTime.now().millisecondsSinceEpoch}_1',
          round: nextRound,
          stage: 'Knockout',
          knockoutTitle: 'Eliminator 1 (3rd vs 6th)',
          homeTeamId: qualified[2].id,
          awayTeamId: qualified[5].id,
        ),
      );
      playoffs.add(
        MatchFixture(
          id: 'ko_${DateTime.now().millisecondsSinceEpoch}_2',
          round: nextRound,
          stage: 'Knockout',
          knockoutTitle: 'Eliminator 2 (4th vs 5th)',
          homeTeamId: qualified[3].id,
          awayTeamId: qualified[4].id,
        ),
      );
    } else {
      String title = _getKnockoutStageName(qualified.length);
      for (int i = 0; i < qualified.length ~/ 2; i++) {
        playoffs.add(
          MatchFixture(
            id: 'ko_${DateTime.now().millisecondsSinceEpoch}_$i',
            round: nextRound,
            stage: 'Knockout',
            knockoutTitle: title,
            homeTeamId: qualified[i].id,
            awayTeamId: qualified[qualified.length - 1 - i].id,
          ),
        );
      }
    }
    return playoffs;
  }

  static List<MatchFixture> _generatePlayoffsFromGroups(Tournament tournament) {
    final allStandings = calculateStandings(tournament);
    Map<String, List<TeamStanding>> groupedStandings = {};

    for (var s in allStandings) {
      String gId = s.team.groupId ?? 'Group A';
      groupedStandings.putIfAbsent(gId, () => []).add(s);
    }

    List<Team> qualifiedTeams = [];
    var sortedGroups = groupedStandings.keys.toList()..sort();

    for (var g in sortedGroups) {
      var groupTeams = groupedStandings[g]!;
      int topN = tournament.qualifiersPerGroup.clamp(1, groupTeams.length);
      for (int i = 0; i < topN; i++) {
        qualifiedTeams.add(groupTeams[i].team);
      }
    }

    List<MatchFixture> playoffs = [];
    int highestRound = tournament.matches.isEmpty
        ? 0
        : tournament.matches
              .map((m) => m.round)
              .reduce((a, b) => a > b ? a : b);
    int nextRound = highestRound + 1;
    String title = _getKnockoutStageName(qualifiedTeams.length);

    for (int i = 0; i < qualifiedTeams.length ~/ 2; i++) {
      playoffs.add(
        MatchFixture(
          id: 'ko_${DateTime.now().millisecondsSinceEpoch}_$i',
          round: nextRound,
          stage: 'Knockout',
          knockoutTitle: title,
          homeTeamId: qualifiedTeams[i].id,
          awayTeamId: qualifiedTeams[qualifiedTeams.length - 1 - i].id,
        ),
      );
    }
    return playoffs;
  }

  // 5. Calculate Standings
  static List<TeamStanding> calculateStandings(Tournament tournament) {
    Map<String, TeamStanding> table = {};
    for (var team in tournament.teams) {
      table[team.id] = TeamStanding(team: team);
    }

    for (var match in tournament.matches) {
      if (match.isCompleted &&
          (match.stage == 'League' || match.stage == 'Group Stage')) {
        final home = table[match.homeTeamId];
        final away = table[match.awayTeamId];
        if (home == null || away == null) continue;

        home.mp++;
        away.mp++;

        home.gf += match.homeScore!;
        home.ga += match.awayScore!;
        away.gf += match.awayScore!;
        away.ga += match.homeScore!;

        if (match.homeScore! > match.awayScore!) {
          home.w++;
          home.points += 3;
          home.last5.insert(0, 'W');
          away.l++;
          away.last5.insert(0, 'L');
        } else if (match.awayScore! > match.homeScore!) {
          away.w++;
          away.points += 3;
          away.last5.insert(0, 'W');
          home.l++;
          home.last5.insert(0, 'L');
        } else {
          home.d++;
          home.points += 1;
          home.last5.insert(0, 'D');
          away.d++;
          away.points += 1;
          away.last5.insert(0, 'D');
        }

        if (home.last5.length > 5) home.last5.removeLast();
        if (away.last5.length > 5) away.last5.removeLast();
      }
    }

    List<TeamStanding> standings = table.values.toList();
    standings.sort((a, b) {
      if (b.points != a.points) return b.points.compareTo(a.points);
      if (b.gd != a.gd) return b.gd.compareTo(a.gd);
      if (b.gf != a.gf) return b.gf.compareTo(a.gf);
      return a.team.name.compareTo(b.team.name);
    });
    return standings;
  }

  // 6. Stats - Top Scorers
  static List<PlayerStat> calculateTopScorers(Tournament tournament) {
    Map<String, PlayerStat> scorers = {};
    for (var match in tournament.matches) {
      if (match.isCompleted) {
        for (var goal in match.scorers) {
          String key = '${goal.teamId}_${goal.playerName.toLowerCase().trim()}';
          if (scorers.containsKey(key)) {
            scorers[key]!.count += goal.goals;
          } else {
            final team = tournament.teams.firstWhere(
              (t) => t.id == goal.teamId,
              orElse: () => Team(id: goal.teamId, name: 'Unknown'),
            );
            scorers[key] = PlayerStat(
              playerName: goal.playerName,
              teamId: team.id,
              teamName: team.name,
              teamLogo: team.logoPath,
              count: goal.goals,
            );
          }
        }
      }
    }
    var list = scorers.values.toList();
    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  // 7. Stats - Clean Sheets
  static List<PlayerStat> calculateCleanSheets(Tournament tournament) {
    Map<String, PlayerStat> cleanSheets = {};
    for (var match in tournament.matches) {
      if (match.isCompleted) {
        for (var cs in match.cleanSheets) {
          String key = '${cs.teamId}_${cs.goalkeeperName.toLowerCase().trim()}';
          if (cleanSheets.containsKey(key)) {
            cleanSheets[key]!.count++;
          } else {
            final team = tournament.teams.firstWhere(
              (t) => t.id == cs.teamId,
              orElse: () => Team(id: cs.teamId, name: 'Unknown'),
            );
            cleanSheets[key] = PlayerStat(
              playerName: cs.goalkeeperName,
              teamId: team.id,
              teamName: team.name,
              teamLogo: team.logoPath,
              count: 1,
            );
          }
        }
      }
    }
    var list = cleanSheets.values.toList();
    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }
}

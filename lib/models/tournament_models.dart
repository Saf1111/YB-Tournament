class Team {
  String id;
  String name;
  String? logoPath; // Gallery PNG logo path
  String?
  groupId; // ഗ്രൂപ്പ് സിസ്റ്റത്തിന് വേണ്ടി പുതിയതായി ചേർത്തത് (e.g., 'Group A', 'Group B')

  Team({required this.id, required this.name, this.logoPath, this.groupId});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoPath': logoPath,
    'groupId': groupId,
  };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: json['id'],
    name: json['name'],
    logoPath: json['logoPath'],
    groupId: json['groupId'],
  );
}

class MatchGoalEvent {
  String id;
  String teamId;
  String playerName;
  int goals;

  MatchGoalEvent({
    required this.id,
    required this.teamId,
    required this.playerName,
    this.goals = 1,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamId': teamId,
    'playerName': playerName,
    'goals': goals,
  };

  factory MatchGoalEvent.fromJson(Map<String, dynamic> json) => MatchGoalEvent(
    id: json['id'],
    teamId: json['teamId'],
    playerName: json['playerName'],
    goals: json['goals'] ?? 1,
  );
}

class MatchCleanSheet {
  String teamId;
  String goalkeeperName;

  MatchCleanSheet({required this.teamId, required this.goalkeeperName});

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'goalkeeperName': goalkeeperName,
  };

  factory MatchCleanSheet.fromJson(Map<String, dynamic> json) =>
      MatchCleanSheet(
        teamId: json['teamId'],
        goalkeeperName: json['goalkeeperName'],
      );
}

class MatchFixture {
  String id;
  int round;
  String stage; // 'League', 'Group', or 'Knockout'
  String? knockoutTitle; // e.g., 'Quarter Final', 'Semi Final', 'Final'
  String?
  groupId; // ഗ്രൂപ്പ് മാച്ച് ആണെങ്കിൽ ഏത് ഗ്രൂപ്പിലെ മാച്ച് ആണ് എന്ന് തിരിച്ചറിയാൻ
  String homeTeamId;
  String awayTeamId;
  int? homeScore;
  int? awayScore;
  bool isCompleted;
  List<MatchGoalEvent> scorers;
  List<MatchCleanSheet> cleanSheets;

  MatchFixture({
    required this.id,
    required this.round,
    this.stage = 'League',
    this.knockoutTitle,
    this.groupId,
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeScore,
    this.awayScore,
    this.isCompleted = false,
    List<MatchGoalEvent>? scorers,
    List<MatchCleanSheet>? cleanSheets,
  }) : scorers = scorers ?? [],
       cleanSheets = cleanSheets ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'round': round,
    'stage': stage,
    'knockoutTitle': knockoutTitle,
    'groupId': groupId,
    'homeTeamId': homeTeamId,
    'awayTeamId': awayTeamId,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'isCompleted': isCompleted,
    'scorers': scorers.map((e) => e.toJson()).toList(),
    'cleanSheets': cleanSheets.map((e) => e.toJson()).toList(),
  };

  factory MatchFixture.fromJson(Map<String, dynamic> json) => MatchFixture(
    id: json['id'],
    round: json['round'],
    stage: json['stage'] ?? 'League',
    knockoutTitle: json['knockoutTitle'],
    groupId: json['groupId'],
    homeTeamId: json['homeTeamId'],
    awayTeamId: json['awayTeamId'],
    homeScore: json['homeScore'],
    awayScore: json['awayScore'],
    isCompleted: json['isCompleted'] ?? false,
    scorers:
        (json['scorers'] as List?)
            ?.map((e) => MatchGoalEvent.fromJson(e))
            .toList() ??
        [],
    cleanSheets:
        (json['cleanSheets'] as List?)
            ?.map((e) => MatchCleanSheet.fromJson(e))
            .toList() ??
        [],
  );
}

class TeamStanding {
  final Team team;
  int mp;
  int w;
  int d;
  int l;
  int gf;
  int ga;
  int points;
  int cleanSheets;
  List<String> last5; // 'W', 'D', 'L'

  TeamStanding({
    required this.team,
    this.mp = 0,
    this.w = 0,
    this.d = 0,
    this.l = 0,
    this.gf = 0,
    this.ga = 0,
    this.points = 0,
    this.cleanSheets = 0,
    List<String>? last5,
  }) : last5 = last5 ?? [];

  int get gd => gf - ga;
}

class PlayerStat {
  final String playerName;
  final String teamId;
  final String teamName;
  final String? teamLogo;
  int count; // Goals or Clean Sheets

  PlayerStat({
    required this.playerName,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.count = 0,
  });
}

class Tournament {
  String id;
  String leagueId;
  String name;
  String seasonSubtitle;
  String? leagueLogoPath;
  String
  formatType; // 'League Only', 'Knockout Only', 'League + Playoffs', 'Group + Knockout'
  int roundsMultiplier; // 1 = Single, 2 = Double
  int playoffQualifiers; // Top 4 or Top 6 (For League+Playoffs)
  int qualifiersPerGroup; // Top 1 or Top 2 (For Group+Knockout)
  List<Team> teams;
  List<MatchFixture> matches;
  Map<String, int> manualGoalAdjustments;
  Map<String, int> manualCleanSheetAdjustments;
  DateTime createdAt;

  Tournament({
    required this.id,
    required this.leagueId,
    required this.name,
    this.seasonSubtitle = 'SEASON 2026-27',
    this.leagueLogoPath,
    this.formatType = 'League Only',
    this.roundsMultiplier = 1,
    this.playoffQualifiers = 4,
    this.qualifiersPerGroup = 2, // പുതിയതായി ചേർത്തത്
    required this.teams,
    required this.matches,
    Map<String, int>? manualGoalAdjustments,
    Map<String, int>? manualCleanSheetAdjustments,
    DateTime? createdAt,
  }) : manualGoalAdjustments = manualGoalAdjustments ?? {},
       manualCleanSheetAdjustments = manualCleanSheetAdjustments ?? {},
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'leagueId': leagueId,
    'name': name,
    'seasonSubtitle': seasonSubtitle,
    'leagueLogoPath': leagueLogoPath,
    'formatType': formatType,
    'roundsMultiplier': roundsMultiplier,
    'playoffQualifiers': playoffQualifiers,
    'qualifiersPerGroup': qualifiersPerGroup,
    'teams': teams.map((e) => e.toJson()).toList(),
    'matches': matches.map((e) => e.toJson()).toList(),
    'manualGoalAdjustments': manualGoalAdjustments,
    'manualCleanSheetAdjustments': manualCleanSheetAdjustments,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
    id: json['id'],
    leagueId: json['leagueId'],
    name: json['name'],
    seasonSubtitle: json['seasonSubtitle'] ?? 'SEASON 2026-27',
    leagueLogoPath: json['leagueLogoPath'],
    formatType: json['formatType'] ?? 'League Only',
    roundsMultiplier: json['roundsMultiplier'] ?? 1,
    playoffQualifiers: json['playoffQualifiers'] ?? 4,
    qualifiersPerGroup: json['qualifiersPerGroup'] ?? 2,
    teams: (json['teams'] as List).map((e) => Team.fromJson(e)).toList(),
    matches: (json['matches'] as List)
        .map((e) => MatchFixture.fromJson(e))
        .toList(),
    manualGoalAdjustments: Map<String, int>.from(
      json['manualGoalAdjustments'] ?? {},
    ),
    manualCleanSheetAdjustments: Map<String, int>.from(
      json['manualCleanSheetAdjustments'] ?? {},
    ),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );
}

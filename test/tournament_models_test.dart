import 'package:flutter_test/flutter_test.dart';
import 'package:yb_efootball/models/tournament_models.dart';

void main() {
  group('YB Tournament - Model Tests', () {
    test('Team creation and JSON conversion', () {
      final team = Team(id: 'team-1', name: 'Real Madrid', groupId: 'Group A');

      final restored = Team.fromJson(team.toJson());

      expect(restored.id, 'team-1');
      expect(restored.name, 'Real Madrid');
      expect(restored.groupId, 'Group A');
    });

    test('Match score and goal events are preserved', () {
      final fixture = MatchFixture(
        id: 'match-1',
        round: 1,
        homeTeamId: 'team-1',
        awayTeamId: 'team-2',
        homeScore: 2,
        awayScore: 1,
        isCompleted: true,
        scorers: [
          MatchGoalEvent(
            id: 'goal-1',
            teamId: 'team-1',
            playerName: 'Player One',
            goals: 2,
          ),
        ],
      );

      final restored = MatchFixture.fromJson(fixture.toJson());

      expect(restored.homeScore, 2);
      expect(restored.awayScore, 1);
      expect(restored.isCompleted, true);
      expect(restored.scorers.length, 1);
      expect(restored.scorers.first.goals, 2);
    });

    test('Tournament data survives JSON conversion', () {
      final tournament = Tournament(
        id: 'tournament-1',
        leagueId: 'league-1',
        name: 'YB Premier League',
        formatType: 'League Only',
        teams: [
          Team(id: 'team-1', name: 'Team A'),
          Team(id: 'team-2', name: 'Team B'),
        ],
        matches: [],
      );

      final restored = Tournament.fromJson(tournament.toJson());

      expect(restored.name, 'YB Premier League');
      expect(restored.teams.length, 2);
      expect(restored.matches, isEmpty);
      expect(restored.roundsMultiplier, 1);
      expect(restored.playoffQualifiers, 4);
    });

    test('Goal difference calculation', () {
      final standing = TeamStanding(
        team: Team(id: 'team-1', name: 'Team A'),
        gf: 12,
        ga: 5,
        points: 15,
      );

      expect(standing.gd, 7);
      expect(standing.points, 15);
    });
  });
}

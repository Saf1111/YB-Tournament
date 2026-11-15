import 'package:flutter_test/flutter_test.dart';
import 'package:yb_efootball/models/tournament_models.dart';
import 'package:yb_efootball/services/tournament_engine.dart';

void main() {
  test('Top scorer correctly totals multiple goals', () {
    final tournament = Tournament(
      id: 't1',
      leagueId: 'l1',
      name: 'YB League',
      teams: [
        Team(id: 'a', name: 'Team A'),
        Team(id: 'b', name: 'Team B'),
      ],
      matches: [
        MatchFixture(
          id: 'm1',
          round: 1,
          homeTeamId: 'a',
          awayTeamId: 'b',
          homeScore: 3,
          awayScore: 0,
          isCompleted: true,
          scorers: [
            MatchGoalEvent(
              id: 'g1',
              teamId: 'a',
              playerName: 'Player One',
              goals: 3,
            ),
          ],
        ),
        MatchFixture(
          id: 'm2',
          round: 2,
          homeTeamId: 'b',
          awayTeamId: 'a',
          homeScore: 0,
          awayScore: 2,
          isCompleted: true,
          scorers: [
            MatchGoalEvent(
              id: 'g2',
              teamId: 'a',
              playerName: 'Player One',
              goals: 2,
            ),
          ],
        ),
      ],
    );

    final scorers = TournamentEngine.calculateTopScorers(tournament);

    expect(scorers.length, 1);
    expect(scorers.first.playerName, 'Player One');
    expect(scorers.first.count, 5);
  });
}

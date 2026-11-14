import 'package:flutter/material.dart';
import '../models/tournament_models.dart';
import '../themes/league_themes.dart';

class AwardDetailsScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<PlayerStat> stats;
  final Color headerColor;
  final Color textColor;
  final bool isGoal;
  final LeagueTheme theme;

  const AwardDetailsScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.stats,
    required this.headerColor,
    required this.textColor,
    required this.isGoal,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
      body: stats.isEmpty
          ? const Center(
              child: Text(
                'No stats available yet.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: stats.length,
              separatorBuilder: (context, index) {
                if (index == 0) return const SizedBox.shrink();
                return const Divider(height: 1, color: Color(0xFFE2E8F0));
              },
              itemBuilder: (context, index) {
                final stat = stats[index];

                // Rank 1 - Premium Card
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: headerColor, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: headerColor.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: headerColor,
                          size: 56,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          stat.playerName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stat.teamName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: headerColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${stat.count}', // ഇവിടെ നിന്നും Goals/CS ഒഴിവാക്കി
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Rank 2 and below
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
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
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.person,
                        color: Color(0xFFCBD5E1),
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stat.playerName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stat.teamName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: headerColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${stat.count}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            fontSize: 14,
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

import 'package:flutter/material.dart';

class LeagueTheme {
  final String id;
  final String name;
  final String shortName;
  final Color primaryColor; // Main Header & Active Tab Color
  final Color accentColor; // Buttons, Badges & Top Border Strip
  final Color secondaryColor; // Gradient Accent
  final Color bgColor; // Clean White/Light Mode Background
  final Color cardColor; // Pure White Floating Card
  final Color textPrimary; // Dark Navy/Charcoal Text
  final Color textSecondary; // Muted Grey Text for Labels

  const LeagueTheme({
    required this.id,
    required this.name,
    required this.shortName,
    required this.primaryColor,
    required this.accentColor,
    required this.secondaryColor,
    this.bgColor = const Color(0xFFF4F6F9), // Soft Off-White
    this.cardColor = const Color(0xFFFFFFFF), // Pure White
    this.textPrimary = const Color(0xFF0F172A), // Crisp Dark Text
    this.textSecondary = const Color(0xFF64748B),
  });
}

class LeagueThemes {
  static const Map<String, LeagueTheme> themes = {
    'isl': LeagueTheme(
      id: 'isl',
      name: 'Indian Super League',
      shortName: 'ISL 2026-27',
      primaryColor: Color(0xFF0A1D56), // Official ISL Royal Midnight Blue
      accentColor: Color(0xFFE11D48), // Official ISL Crimson Red
      secondaryColor: Color(0xFFF59E0B), // Gold Accent
    ),
    'pl': LeagueTheme(
      id: 'pl',
      name: 'Premier League',
      shortName: 'PL 2026-27',
      primaryColor: Color(0xFF38003C), // Official PL Deep Purple
      accentColor: Color(0xFF00C86B), // Crisp PL Green for White Mode
      secondaryColor: Color(0xFF04F5FF), // PL Cyan
    ),
    'slk': LeagueTheme(
      id: 'slk',
      name: 'Super League Kerala',
      shortName: 'SLK 2026',
      primaryColor: Color(0xFF064E3B), // Kerala Emerald Teal
      accentColor: Color(0xFFD97706), // Rich Gold
      secondaryColor: Color(0xFF10B981), // Vibrant Green
    ),
    'laliga': LeagueTheme(
      id: 'laliga',
      name: 'LaLiga EA Sports',
      shortName: 'LALIGA 2026-27',
      primaryColor: Color(0xFF1E1E24), // Dark Charcoal
      accentColor: Color(0xFFFF4B44), // Official LaLiga Coral Red
      secondaryColor: Color(0xFFFF7849),
    ),
    'worldcup': LeagueTheme(
      id: 'worldcup',
      name: 'FIFA World Cup',
      shortName: 'WORLD CUP',
      primaryColor: Color(0xFF58001D), // Luxury Burgundy
      accentColor: Color(0xFFD4AF37), // Metallic Gold
      secondaryColor: Color(0xFF8A1538),
    ),
    'ileague': LeagueTheme(
      id: 'ileague',
      name: 'I-League',
      shortName: 'I-LEAGUE 2026-27',
      primaryColor: Color(0xFF1E3A8A), // Classic Navy Blue
      accentColor: Color(0xFFEA580C), // Saffron Orange
      secondaryColor: Color(0xFF16A34A), // India Green
    ),
  };

  static LeagueTheme getTheme(String leagueId) {
    return themes[leagueId] ?? themes['isl']!;
  }

  static List<LeagueTheme> get allLeagues => themes.values.toList();
}

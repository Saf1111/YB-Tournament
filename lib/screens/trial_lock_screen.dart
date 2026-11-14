import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrialManager {
  static const String _trialStartKey = 'trial_start_time';
  static const int trialDurationHours = 1;

  // App open cheyumbol trial expire aayo enn check cheyyan
  static Future<bool> isTrialExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeStr = prefs.getString(_trialStartKey);

    if (startTimeStr == null) {
      // App aadyamayi open cheyumbol current time save cheyyunnu
      await prefs.setString(_trialStartKey, DateTime.now().toIso8601String());
      return false; // Trial start cheythu, expire aayittilla
    }

    final startTime = DateTime.parse(startTimeStr);
    final expirationTime = startTime.add(
      const Duration(hours: trialDurationHours),
    );

    // Current time expiration time-nekkal kooduthal aanenkil expire aayi
    return DateTime.now().isAfter(expirationTime);
  }
}

class TrialLockScreen extends StatelessWidget {
  const TrialLockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_clock, size: 80, color: Color(0xFFE11D48)),
              const SizedBox(height: 24),
              const Text(
                'TRIAL EXPIRED',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your 1-hour trial period has ended. Please contact the developer to unlock the full version of YB eFootball.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // WhatsApp link-o contact info-o ivide add cheyyam
                },
                icon: const Icon(Icons.message, size: 18),
                label: const Text(
                  'Contact Developer',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

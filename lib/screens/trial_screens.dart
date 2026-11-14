import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TrialState { notStarted, active, expired }

class TrialManager {
  static const String _trialStartKey = 'yb_app_trial_start';
  // 30 മിനിറ്റ് ആക്കാൻ 0.5 മണിക്കൂർ എന്ന് കൊടുക്കുന്നു
  static const double trialDurationHours = 0.5;

  static Future<TrialState> getTrialState() async {
    final prefs = await SharedPreferences.getInstance();
    final startTimeStr = prefs.getString(_trialStartKey);

    if (startTimeStr == null) {
      return TrialState.notStarted;
    }

    final startTime = DateTime.parse(startTimeStr);
    final expirationTime = startTime.add(
      Duration(minutes: (trialDurationHours * 60).toInt()),
    );

    if (DateTime.now().isAfter(expirationTime)) {
      return TrialState.expired;
    }
    return TrialState.active;
  }

  static Future<void> startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trialStartKey, DateTime.now().toIso8601String());
  }
}

class TrialStartScreen extends StatelessWidget {
  final VoidCallback onStart;
  const TrialStartScreen({super.key, required this.onStart});

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
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(height: 24),
              const Text(
                'YB TOURNAMENT MANAGER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome! You have a 30-minute free trial to explore all premium tournament features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 8,
                ),
                onPressed: () async {
                  await TrialManager.startTrial();
                  onStart();
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text(
                  'START 30-MIN TRIAL',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                'Your 30-minute trial period has ended. Please contact the developer to unlock the full version of YB Tournament Manager.',
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
                onPressed: () {},
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

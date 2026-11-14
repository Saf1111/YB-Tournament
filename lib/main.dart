import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart'; // ഫയർബേസ് വെബ്ബിന് ഇത് നിർബന്ധമാണ്
import 'screens/home_screen.dart';
import 'screens/viewer_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // വെബ് ലിങ്കിലെ ഹാഷ് (#) ഒഴിവാക്കാൻ

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions
          .currentPlatform, // വെബ്ബിൽ ബ്ലാങ്ക് സ്ക്രീൻ വരാതിരിക്കാൻ
    );
  } catch (e) {
    debugPrint("Firebase Error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YB Tournament Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0F172A),
        useMaterial3: false,
      ),
      // URL റൂട്ടിംഗ് ലോജിക്
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');

        // ലിങ്കിൽ '?id=' ഉണ്ടോ എന്ന് ചെക്ക് ചെയ്യുന്നു
        if (uri.queryParameters.containsKey('id')) {
          String tournamentId = uri.queryParameters['id']!;
          // ഐഡി ഉണ്ടെങ്കിൽ നേരെ വ്യൂവർ സ്ക്രീനിലേക്ക് പോകും
          return MaterialPageRoute(
            builder: (context) => ViewerScreen(tournamentId: tournamentId),
          );
        }

        // ഐഡി ഇല്ലെങ്കിൽ നേരെ അഡ്മിൻ ഹോം സ്ക്രീനിലേക്ക് പോകും
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      },
    );
  }
}

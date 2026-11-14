import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAEz-yFeqzkPcdVfJIeyJOu9g1Z-V3PW-0',
    appId: '1:1065906958644:web:3de0df07f0c45936533561',
    messagingSenderId: '1065906958644',
    projectId: 'yb-tournament-app',
    authDomain: 'yb-tournament-app.firebaseapp.com',
    storageBucket: 'yb-tournament-app.appspot.com',
  );
}

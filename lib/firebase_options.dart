import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Only web is supported');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCcMVd1nRCoA0XD4OFF9PAyrHsICKRc8gg',
    appId: '1:804512005696:web:a652f9936b30c4a99be9a5',
    messagingSenderId: '804512005696',
    projectId: 'd-helper-f1331',
    authDomain: 'd-helper-f1331.firebaseapp.com',
    databaseURL: 'https://d-helper-f1331-default-rtdb.firebaseio.com',
    storageBucket: 'd-helper-f1331.firebasestorage.app',
    measurementId: 'G-CWYF16TPN5',
  );
}

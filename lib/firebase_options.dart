// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Fake options, change these to your Firebase project's options

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBTtqegCKi2EN7qdc_x9nkW2fH2ki4HSog',
    appId: '1:618598999953:web:13b36fe4d47311c4259c30',
    messagingSenderId: '618598999953',
    projectId: 'tricount-f74d3',
    authDomain: 'tricount-f74d3.firebaseapp.com',
    storageBucket: 'tricount-f74d3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCA6LSe5uNxQ5t27Ux-_3Ki0zRUp2IdJ2U',
    appId: '1:618598999953:ios:bee4178035e4d44f259c30',
    messagingSenderId: '618598999953',
    projectId: 'tricount-f74d3',
    storageBucket: 'tricount-f74d3.firebasestorage.app',
    iosBundleId: 'com.nicolasborlet.tricount.tricount',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCA6LSe5uNxQ5t27Ux-_3Ki0zRUp2IdJ2U',
    appId: '1:618598999953:ios:bee4178035e4d44f259c30',
    messagingSenderId: '618598999953',
    projectId: 'tricount-f74d3',
    storageBucket: 'tricount-f74d3.firebasestorage.app',
    iosBundleId: 'com.nicolasborlet.tricount.tricount',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBTtqegCKi2EN7qdc_x9nkW2fH2ki4HSog',
    appId: '1:618598999953:web:999ad701e43dba2f259c30',
    messagingSenderId: '618598999953',
    projectId: 'tricount-f74d3',
    authDomain: 'tricount-f74d3.firebaseapp.com',
    storageBucket: 'tricount-f74d3.firebasestorage.app',
  );

}
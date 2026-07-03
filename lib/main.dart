import 'dart:io';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:fndtv/src/ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Stripe.publishableKey = "<publishable-key>";
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Background audio + media notification (Spotify-style) for the radio player.

  // TODO: Remove it for production CODE !!!
  HttpOverrides.global = AppHttpOverrides();

  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.current  Platform,
  // );

  runApp(const App());
}

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(
//   RemoteMessage message,
// ) async {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );

//   // unawaited(firebaseService.showNotification(message));
// }

import 'dart:io';

import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:fndtv/src/ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Stripe.publishableKey = "<publishable-key>";
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Background audio + media notification (Spotify-style) for the radio player.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.fndtv.videoplayer.channel.audio',
    androidNotificationChannelName: 'FNDTV Radio',
    androidNotificationChannelDescription: 'FNDTV radio playback controls',
    androidNotificationIcon: 'drawable/ic_stat_fndtv',
    notificationColor: const Color(0xFFA83734), // brand red accent/tint
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );

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

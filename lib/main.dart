import 'dart:io';

import 'package:commons/commons.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:fndtv/src/ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _detectTvPlatform();
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

/// Latches [markPlatformAsTv] when the device itself is a television, so the
/// TV layout never depends on logical screen size alone (Fire TV sticks report
/// phone-sized logical dimensions — 1280×720 at xhdpi is 640×360).
Future<void> _detectTvPlatform() async {
  if (appFlavor == 'stb') {
    markPlatformAsTv();
    return;
  }
  if (!Platform.isAndroid) return;
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    final features = info.systemFeatures;
    if (features.contains('android.software.leanback') ||
        features.contains('amazon.hardware.fire_tv')) {
      markPlatformAsTv();
    }
  } catch (_) {
    // Detection is best-effort; the size heuristic still applies.
  }
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

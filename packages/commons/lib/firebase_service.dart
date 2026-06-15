// import 'dart:async';
// import 'dart:convert';

// import 'package:commons/commons.dart';
// import 'package:commons/http/api_list.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:firebase_remote_config/firebase_remote_config.dart';
// import 'package:flutter/widgets.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:flutter/foundation.dart';
// import 'package:app_logger/app_logger.dart';

// import 'package:http/http.dart' as http;

// final class FirebaseService {
//   BuildContext? context;
//   String? token;
//   final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

//   /// set MinimumFetchInterval to Low duration in testing
//   final RemoteConfigSettings _remoteConfigSettings = RemoteConfigSettings(
//     fetchTimeout: const Duration(minutes: 1),
//     minimumFetchInterval:
//         kDebugMode ? const Duration(minutes: 1) : const Duration(hours: 1),
//   );

//   final FirebaseMessaging messaging = FirebaseMessaging.instance;
//   final GetAuthTokenUseCase getAuthTokenUseCase;
//   bool firebasePermissionStatus = false;
//   int notificationId = 0;

//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   FirebaseService({required this.getAuthTokenUseCase});

//   /// Initialize Firebase and Remote Config
//   Future<void> initialize() async {
//     await remoteConfig.setConfigSettings(_remoteConfigSettings);
//     await remoteConfig.setDefaults(_defaultData);
//     await _initStreams();
//     await _fetchConfig();
//   }

//   /// Initialize onConfigUpdated Stream To cache Updated values for next app start
//   Future<void> _initStreams() async {
//     remoteConfig.onConfigUpdated.listen((event) async {
//       await _fetchConfig();
//     });
//   }

//   void initMessaging(int customerId) async {
//     await _requestFCMPermission(customerId);
//     await _setupInteractedMessage();

//     FirebaseMessaging.onMessage.listen((message) {
//       showNotification(message);
//     });
//   }

//   Future<void> _fetchConfig() async {
//     await remoteConfig.fetchAndActivate().onError((error, stackTrace) {
//       logger.e(error.toString(), stacktrace: stackTrace);
//       FirebaseCrashlytics.instance.recordError(error, stackTrace);
//       return false;
//     });
//   }

//   Future<void> showNotification(RemoteMessage message) async {
//     await _initLocalNotifications(message);

//     AndroidNotificationChannel channel = AndroidNotificationChannel(
//         UniqueKey().toString(), 'High Importance Notification',
//         importance: Importance.max);

//     AndroidNotificationDetails androidNotificationDetails =
//         AndroidNotificationDetails(
//       channel.id,
//       channel.name,
//       channelDescription: 'Turebi App Channel',
//       importance: Importance.max,
//       priority: Priority.high,
//       ticker: 'ticker',
//     );

//     DarwinNotificationDetails darwinNotificationDetails =
//         const DarwinNotificationDetails(
//             presentAlert: true, presentSound: true, presentBadge: true);

//     NotificationDetails notificationDetails = NotificationDetails(
//       android: androidNotificationDetails,
//       iOS: darwinNotificationDetails,
//     );

//     unawaited(_flutterLocalNotificationsPlugin.show(
//       notificationId++,
//       message.notification!.title,
//       message.notification!.body,
//       notificationDetails,
//     ));
//   }

//   Future<void> _requestFCMPermission(int customerId) async {
//     NotificationSettings settings = await messaging.requestPermission(
//       alert: true,
//       announcement: true,
//       badge: true,
//       carPlay: false,
//       criticalAlert: true,
//       provisional: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       logger.d('User granted permission');
//       firebasePermissionStatus = true;
//     } else if (settings.authorizationStatus ==
//         AuthorizationStatus.provisional) {
//       logger.d('User granted provisional permission');
//     } else {
//       logger.d('User declined or has not accepted permission');
//       firebasePermissionStatus = false;
//     }

//     if (!firebasePermissionStatus) return;

//     _saveFcmToken(customerId);
//   }

//   void _handleTopics(FirebaseMessaging firebaseMessaging) {
//     if (firebasePermissionStatus) {
//       firebaseMessaging.subscribeToTopic('defaultTopic');
//       logger.d('firebaseMessaging subscribed to defaultTopic');
//     } else {
//       firebaseMessaging.unsubscribeFromTopic('defaultTopic');
//       logger.d('firebaseMessaging unsubscribed to defaultTopic');
//     }
//   }

//   void _saveFcmToken(int customerId) async {
//     FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
//     _handleTopics(firebaseMessaging);

//     unawaited(
//       firebaseMessaging.getToken().then(
//             (token) => _tokenHandler(customerId, token),
//           ),
//     );
//     FirebaseMessaging.instance.onTokenRefresh.listen((event) {
//       _tokenHandler(customerId, event);
//     });
//   }

//   Future<String?> fetcFcmToken() {
//     return FirebaseMessaging.instance.getToken();
//   }

//   void _tokenHandler(int customerId, String? token) {
//     storeFcmTokenRequest(customerId, token);

//     token = token;
//     logger.i('FCM token is $token');
//   }

//   Future<void> _initLocalNotifications(RemoteMessage message) async {
//     const AndroidInitializationSettings androidInitialization =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const DarwinInitializationSettings iosInitialization =
//         DarwinInitializationSettings();
//     const InitializationSettings initializationSetting = InitializationSettings(
//         android: androidInitialization, iOS: iosInitialization);

//     await _flutterLocalNotificationsPlugin.initialize(
//       initializationSetting,
//     );
//   }

//   // It is assumed that all messages contain a data field with the key 'type'
//   Future<void> _setupInteractedMessage() async {
//     // Get any messages which caused the application to open from
//     // a terminated state.
//     RemoteMessage? initialMessage =
//         await FirebaseMessaging.instance.getInitialMessage();

//     // If the message also contains a data property with a "type" of "chat",
//     // navigate to a chat screen
//     if (initialMessage != null) {
//       _handleMessage(initialMessage);
//     }

//     // Also handle any interaction when the app is in the background via a
//     // Stream listener
//     FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
//   }

//   /// temporary
//   void _handleMessage(RemoteMessage message) {
//     if (message.data['type'] == 'route') {
//       if (context == null) return;

//       Navigator.pushNamed(
//         context!,
//         '/route',
//       );
//     }
//   }

//   // Send Request to store device token in the database
//   void storeFcmTokenRequest(int customerId, String? token) async {
//     if (token == null) {
//       logger.e(
//           '/// storeFcmTokenRequest FCM TOKEN IS NULL /// storeFcmTokenRequest');
//       return;
//     }

//     unawaited(http.post(
//       Uri.parse(APIList.storeFcmToken),
//       headers: {
//         'Authorization': 'Bearer ${await getAuthTokenUseCase()}',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode({'customerId': customerId, 'token': token}),
//     ));
//   }
// }

// final _defaultData = {
//   'onboarding': jsonEncode([
//     {
//       'title': {'en': 'Congrats!', 'ka': 'გილოცავ!'},
//       'subTitle': {
//         'ka': 'შენ წარმატებით გაიარე რეგისტრაცია',
//         'en': 'Hey Hey Hey, congrats on the registration'
//       },
//       'imageUrl': 'assets/svg/onboarding-1.svg'
//     },
//     {
//       'title': {'ka': 'დაგეგმეთ და მართეთ', 'en': 'Plan and Manage'},
//       'subTitle': {
//         'ka': 'თქვენ შეგიძლიათ დაგეგმოთ და მართოთ თქვენი ტური',
//         'en': 'You can plan and manage your trip here'
//       },
//       'imageUrl': 'assets/svg/onboarding-2.svg'
//     },
//     {
//       'title': {'ka': 'დოკუმენტები', 'en': 'Documents'},
//       'subTitle': {
//         'ka': 'შენ შეგიძლია ყველა საჭირო დოკუმენტი მოძებნო აქ',
//         'en': 'You can have all the travel documents in one place'
//       },
//       'imageUrl': 'assets/svg/onboarding-3.svg'
//     },
//     {
//       'title': {'ka': 'შეხსენებები', 'en': 'Reminder'},
//       'subTitle': {
//         'ka': 'შეხსენებები შენი ტურის შესახებ',
//         'en': 'Reminding everything about your trip'
//       },
//       'imageUrl': 'assets/svg/onboarding-4.svg'
//     },
//     {
//       'title': {'ka': 'რეკომენდაციები', 'en': 'Recommendations'},
//       'subTitle': {
//         'ka': 'არ დაგავიწყდეს რეკომენდაციების შემოწმება ჩვენს აპლიკაციაში',
//         'en': "Also don't forget to check the recommendations around the world"
//       },
//       'imageUrl': 'assets/svg/onboarding-5.svg'
//     }
//   ])
// };

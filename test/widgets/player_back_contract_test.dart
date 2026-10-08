import 'dart:async';

import 'package:app_localization/app_localization.dart';
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fndtv/src/bloc/bloc.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/app_video_player.dart';
import 'package:fndtv/src/ui/widgets/app_video_player/screens/vod_fullscreen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// Records the keep-screen-awake state the app asks for.
class _FakeWakelock extends WakelockPlusPlatformInterface {
  bool on = false;

  @override
  Future<void> toggle({required bool enable}) async => on = enable;

  @override
  Future<bool> get enabled async => on;
}

final _wakelock = _FakeWakelock();

/// The remote's Back contract for the normal-flavor player (Fire TV, Android
/// TV, phones): schedule open → Back closes it; otherwise Back leaves the
/// player. Driven through the REAL pop path ([handlePopRoute]) and real key
/// events, not by calling the widget's own methods — see the KB entry
/// android-tv-back-is-a-route-pop.

class _FakeAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Schedule fetch that never answers, so the sheet stays in its loading state.
class _PendingContentRepository implements ContentRepository {
  @override
  Future<ResponseModel<LiveModel>> getContentDetail({
    required int contentType,
    required int id,
    String? date,
  }) =>
      Completer<ResponseModel<LiveModel>>().future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A video platform that "opens" every stream at once, so the real
/// [AppVideoPlayer] — including whatever wraps its controls — gets built.
class _InstantVideoPlatform extends VideoPlayerPlatform {
  final _events = <int, StreamController<VideoEvent>>{};
  int _next = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async => _open();

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => _open();

  int _open() {
    final id = _next++;
    _events[id] = StreamController<VideoEvent>();
    scheduleMicrotask(() => _events[id]!.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(hours: 1),
          size: const Size(1920, 1080),
        )));
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => _events[playerId]!.stream;

  @override
  Future<void> dispose(int playerId) async => _events.remove(playerId)?.close();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> seekTo(int playerId, Duration position) async {}
  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
  @override
  Widget buildView(int playerId) => const SizedBox.expand();
  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const SizedBox.expand();
}

const _homeLabel = 'home-screen';

Future<void> _openPlayer(WidgetTester tester, ContentType type) async {
  final channel = LiveModel.fromJson(const {'id': 1, 'title': 'Test channel'});

  // VideoPlayerCubit is app-wide in the real app (above the navigator), so its
  // auto-hide timer outlives the player route — mirror that here.
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => VideoPlayerCubit(
        getAuthTokenUseCase: GetAuthTokenUseCase(_FakeAuthRepository()),
      ),
      child: ThemeColorListener(
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MultiRepositoryProvider(
                      providers: [
                        RepositoryProvider<ContentRepository>(
                          create: (_) => _PendingContentRepository(),
                        ),
                      ],
                      child: Scaffold(
                        backgroundColor: Colors.black,
                        body: AppVideoPlayer(
                          link: 'https://example.invalid/a.m3u8',
                          video: channel,
                          isLive: type != ContentType.dvr,
                          contentType: type,
                        ),
                      ),
                    ),
                  ),
                ),
                child: const Text(_homeLabel),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text(_homeLabel));
  await _settle(tester);
  expect(find.byType(VodFullScreen), findsOneWidget);
}

/// pumpAndSettle never settles here (the schedule hint bobs forever), so
/// advance a fixed slice instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Lets the controls' 6 s auto-hide timer fire and tears the tree down, so no
/// timer (auto-hide, the controller's position poll) is left pending.
Future<void> _drainTimers(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    VideoPlayerPlatform.instance = _InstantVideoPlatform();
    WakelockPlusPlatformInterface.instance = _wakelock;
  });
  setUp(() => _wakelock.on = false);

  // Fire TV's screensaver (and later sleep) must not cut into playback — the
  // player keeps the screen awake while video is actually playing.
  group('keep screen awake', () {
    testWidgets('on while playing, released on leaving', (tester) async {
      await _openPlayer(tester, ContentType.television);
      expect(_wakelock.on, isTrue, reason: 'playing');

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(_wakelock.on, isFalse, reason: 'left the player');
      await _drainTimers(tester);
    });

    testWidgets('released while paused, back on when resumed', (tester) async {
      await _openPlayer(tester, ContentType.television);
      await tester.sendKeyEvent(LogicalKeyboardKey.select); // pause
      await _settle(tester);
      expect(_wakelock.on, isFalse, reason: 'paused');

      await tester.sendKeyEvent(LogicalKeyboardKey.select); // play
      await _settle(tester);
      expect(_wakelock.on, isTrue, reason: 'resumed');
      await _drainTimers(tester);
    });

    testWidgets('leaving restores a wake lock the screen behind held',
        (tester) async {
      // The phone channel page holds its own wake lock while the full-screen
      // player is on top; closing the player must not switch it off.
      _wakelock.on = true;
      await _openPlayer(tester, ContentType.television);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(_wakelock.on, isTrue);
      await _drainTimers(tester);
    });
  });

  for (final type in [
    ContentType.television,
    ContentType.dvr,
    ContentType.radio
  ]) {
    testWidgets('Back leaves the player ($type)', (tester) async {
      await _openPlayer(tester, type);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(find.byType(VodFullScreen), findsNothing);
      expect(find.text(_homeLabel), findsOneWidget);
      await _drainTimers(tester);
    });
  }

  testWidgets('Back with the controls showing still leaves', (tester) async {
    await _openPlayer(tester, ContentType.television);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // reveal controls
    await _settle(tester);

    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(find.byType(VodFullScreen), findsNothing);
    await _drainTimers(tester);
  });

  testWidgets('Back closes the schedule first, then leaves', (tester) async {
    await _openPlayer(tester, ContentType.television);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // reveal controls
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // open schedule
    await _settle(tester);
    expect(find.text('Programme du jour'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('Programme du jour'), findsNothing,
        reason: 'first Back closes the schedule');
    expect(find.byType(VodFullScreen), findsOneWidget,
        reason: 'and stays in the player');

    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byType(VodFullScreen), findsNothing);
    await _drainTimers(tester);
  });

  testWidgets('no widget swallows the Back KEY — the pop decides',
      (tester) async {
    // Android re-dispatches an unhandled Back key as a route pop. Any widget
    // that marks goBack handled cuts that path and traps the viewer.
    await _openPlayer(tester, ContentType.television);
    // Test the key in each focus position the viewer can reach: play/pause,
    // play/pause with controls up, and ←.
    final presses = <LogicalKeyboardKey?>[
      null,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowUp,
    ];
    for (final move in presses) {
      if (move != null) {
        await tester.sendKeyEvent(move);
        await _settle(tester);
      }
      final down = await tester.sendKeyDownEvent(LogicalKeyboardKey.goBack,
          physicalKey: PhysicalKeyboardKey.browserBack, platform: 'web');
      final up = await tester.sendKeyUpEvent(LogicalKeyboardKey.goBack,
          physicalKey: PhysicalKeyboardKey.browserBack, platform: 'web');
      expect(down || up, isFalse, reason: 'after ${move ?? 'opening'}');
      await _settle(tester);
    }
    await _drainTimers(tester);
  });

  testWidgets('Up reaches ← and OK on it leaves the player', (tester) async {
    await _openPlayer(tester, ContentType.television);
    // Like Down: the first Up only reveals the controls, the second moves to ←.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await _settle(tester);

    expect(find.byType(VodFullScreen), findsNothing);
    await _drainTimers(tester);
  });

  testWidgets('player labels follow the app language', (tester) async {
    await _openPlayer(tester, ContentType.television);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // reveal controls
    await _settle(tester);

    expect(find.text('Programme'), findsOneWidget);
    expect(find.text('Schedule'), findsNothing);
    await _drainTimers(tester);
  });
}

import 'package:commons/commons.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/bloc/epg_cubit/epg_cubit.dart';
import 'package:fndtv/src/data/data_sources/content/content_data_source.dart';

import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/repositories/content/content_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/core/services/app_route_tracker.dart';
import 'package:fndtv/src/ui/widgets/stb/stb_power_guard.dart';
import 'package:fndtv/src/ui/widgets/stb/tv_identity_badge.dart';
import 'package:fndtv/src/ui/widgets/stb/tv_offline_overlay.dart';
import 'package:fndtv/src/ui/app_view.dart';
import 'package:fndtv/src/ui/pages/main/main_container_page.dart';
import 'package:fndtv/src/ui/pages/live_detail/new_live_detail_page.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:ui_kit/ui_kit.dart';
import 'package:app_localization/app_localization.dart';

/// Global navigator — lets the offline overlay (which lives OUTSIDE the
/// Navigator, in MaterialApp.builder) push the Network page.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    initBackground();
  }

  void initBackground() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.fndtv.videoplayer.channel.audio',
      androidNotificationChannelName: 'FNDTV Radio',
      androidNotificationChannelDescription: 'FNDTV radio playback controls',
      androidNotificationIcon: 'drawable/ic_stat_fndtv',
      notificationColor: const Color(0xFFA83734), // brand red accent/tint
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppProvider(
      child: AppBlocProvider(
        child: Builder(
          builder: (context) {
            if (!context.read<DeviceModelService>().isOrientationPortrait(
                  context,
                )) {
              // Landscape (e.g. fullscreen video) — hide the system bars.
              SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.manual,
                overlays: [],
              );
            } else {
              // Portrait — draw edge-to-edge so the device status bar
              // (time/battery) shows over the red app bar, with white icons.
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              SystemChrome.setSystemUIOverlayStyle(
                const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                ),
              );
            }
            return Shortcuts(
              shortcuts: <LogicalKeySet, Intent>{
                LogicalKeySet(LogicalKeyboardKey.select):
                    const ActivateIntent(),
              },
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                navigatorKey: appNavigatorKey,
                navigatorObservers: [AppRouteTracker()],
                // STB: power guard + global identity badge + offline overlay,
                // stacked over every route.
                builder: StbSystemService.isStb
                    ? (context, child) => StbPowerGuard(
                          child: Stack(
                            children: [
                              child ?? const SizedBox.shrink(),
                              const TvIdentityBadge(),
                              const TvOfflineOverlay(),
                            ],
                          ),
                        )
                    : null,
                locale: context.select<LocalizationCubit, Locale>(
                  (c) => c.state.locale,
                ),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                themeMode: ThemeMode.dark,
                darkTheme: _getTheme(context, Brightness.dark),
                initialRoute: SplashPage.path,
                onGenerateRoute: (settings) =>
                    onGenerateRoute(settings, context),
              ),
            );
          },
        ),
      ),
    );
  }
}

MaterialPageRoute<dynamic> onGenerateRoute(
  RouteSettings settings,
  BuildContext context,
) {
  Widget page;

  try {
    switch (settings.name) {
      case TermsOfUsePage.path:
        page = const TermsOfUsePage();

      case SplashPage.path:
        page = const SplashPage();

      case LoginPage.path:
        page = BlocProvider<LoginCubit>(
          create: (context) {
            final AuthRepository authRepo = context.read<AuthRepository>();
            return LoginCubit(LoginUseCase(authRepo));
          },
          child: context.isTv ? const TvLoginPage() : const LoginPage(),
        );

      case SignUpPage.path:
        page = BlocProvider<SignUpCubit>(
          create: (ctx) {
            final AuthRepository authRepo = ctx.read<AuthRepository>();

            return SignUpCubit(SignUpUseCase(authRepo));
          },
          child: context.isTv ? const TvSignUpPage() : const SignUpPage(),
        );

      case TvForgotPasswordPage.path:
        page = BlocProvider<ForgotPasswordCubit>(
          create: (ctx) {
            final AuthRepository authRepo = ctx.read<AuthRepository>();

            return ForgotPasswordCubit(ForgotPasswordUseCase(authRepo));
          },
          child: const TvForgotPasswordPage(),
        );

      case MainContainerPage.path:
        page = MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ContentRepository>(
              create: (context) => ContentRepositoryImpl(
                dataSource: ContentDataSource(context.read<CustomHTTPClient>()),
              ),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ContentCubit>(
                create: (context) => ContentCubit(
                  contentDataSource: context.read<ContentRepository>(),
                ),
              ),
            ],
            child: const MainContainerPage(),
          ),
        );

      case AppView.path:
        page = MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ContentRepository>(
              create: (context) => ContentRepositoryImpl(
                dataSource: ContentDataSource(context.read<CustomHTTPClient>()),
              ),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ContentCubit>(
                create: (context) => ContentCubit(
                  contentDataSource: context.read<ContentRepository>(),
                ),
              ),
            ],
            child: const AppView(),
          ),
        );

      case VideoPlayerPage.path:
        final args = settings.arguments as Map<String, dynamic>;
        final LiveModel content = args['channel'] as LiveModel;
        final contentType = args['contentType'] as ContentType;

        page = MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ContentRepository>(
              create: (context) => ContentRepositoryImpl(
                dataSource: ContentDataSource(context.read<CustomHTTPClient>()),
              ),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<EpgCubit>(
                create: (context) => EpgCubit(
                  contentDataSource: context.read<ContentRepository>(),
                ),
              ),
            ],
            child: VideoPlayerPage(video: content, contentType: contentType),
          ),
        );

      case NewLiveDetailPage.path:
        final args = settings.arguments as Map<String, dynamic>;
        final LiveModel channel = args['channel'] as LiveModel;

        page = RepositoryProvider<ContentRepository>(
          create: (context) => ContentRepositoryImpl(
            dataSource: ContentDataSource(context.read<CustomHTTPClient>()),
          ),
          child: NewLiveDetailPage(channel: channel),
        );

      case MobileChannelDetailPage.path:
        final args = settings.arguments as Map<String, dynamic>;
        final LiveModel content = args['channel'] as LiveModel;
        final contentType = args['contentType'] as ContentType;
        final contentCubit = args['contentCubit'] as ContentCubit;

        page = MultiRepositoryProvider(
          providers: [
            RepositoryProvider<ContentRepository>(
              create: (context) => ContentRepositoryImpl(
                dataSource: ContentDataSource(context.read<CustomHTTPClient>()),
              ),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: contentCubit),
            ],
            child: MobileChannelDetailPage(
                video: content, contentType: contentType),
          ),
        );

      // case SubscribePage.path:
      //   page = const SubscribePage();

      case PrivacyPolicyPage.path:
        page = const PrivacyPolicyPage();

      case SettingsPage.path:
        page = const SettingsPage();

      default:
        page = _ErrorPage('No route defined for ${settings.name}');
    }
  } catch (e) {
    debugPrint('Error in route generation: $e');
    page = _ErrorPage('Navigation error occurred: $e');
  }
  return MaterialPageRoute<dynamic>(
    builder: (context) => page,
    settings: settings,
  );
}

class _ErrorPage extends StatelessWidget {
  final String message;

  const _ErrorPage(this.message);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(message)));
  }
}

ThemeData _getTheme(BuildContext context, Brightness b) {
  return ThemeData(
    // focusColor: AppColors.greyscale[600],
    progressIndicatorTheme: Theme.of(
      context,
    ).progressIndicatorTheme.copyWith(color: Colors.black),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: ZoomPageTransitionsBuilder(
          allowEnterRouteSnapshotting: false,
        ),
      },
    ),
    scaffoldBackgroundColor:
        context.isTv ? context.uiColors.tvSurface : context.uiColors.surface,
    textTheme: GoogleFonts.soraTextTheme().copyWith(
      displayLarge: GoogleFonts.sora(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          color: context.uiKitColors.textPrimary),
      displayMedium: GoogleFonts.sora(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          color: context.uiKitColors.textPrimary),
      headlineLarge: GoogleFonts.sora(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: context.uiKitColors.textPrimary),
      headlineMedium: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: context.uiKitColors.textPrimary),
      titleLarge: GoogleFonts.sora(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: context.uiKitColors.textPrimary),
      titleMedium: GoogleFonts.sora(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: context.uiKitColors.textPrimary),
      titleSmall: GoogleFonts.sora(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.uiKitColors.textPrimary),
      bodyLarge: GoogleFonts.sora(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: context.uiKitColors.textPrimary),
      bodyMedium: GoogleFonts.sora(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: context.uiKitColors.textMuted),
      labelLarge: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.uiKitColors.textPrimary),
      labelSmall: GoogleFonts.sora(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: context.uiKitColors.textHint),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: context.uiColors.onSecondary,
      selectionColor: context.uiColors.primary.withOpacity(0.08),
      selectionHandleColor: context.uiColors.primary,
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: context.uiColors.primary,
      brightness: b,
    ),
    useMaterial3: true,
  );
}

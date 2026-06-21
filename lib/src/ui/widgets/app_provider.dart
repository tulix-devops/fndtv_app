import 'package:app_localization/app_localization.dart';
import 'package:commons/commons.dart';
import 'package:fndtv/src/ui/app_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:local_storage/local_storage.dart';
import 'package:fndtv/src/bloc/bloc.dart';
import 'package:fndtv/src/bloc/theme_cubit/theme_cubit.dart';
import 'package:fndtv/src/core/core.dart';
import 'package:ui_kit/ui_kit.dart';

class AppProvider extends StatefulWidget {
  const AppProvider({super.key, required this.child});

  final Widget child;
  @override
  State<AppProvider> createState() => _AppProviderState();
}

class _AppProviderState extends State<AppProvider> {
  final LocalStorage _localStorage = HiveLocalStorage();
  late final LocalAuthDataSource _localAuthDataSource = LocalAuthDataSource(
    _localStorage,
  );
  late final RemoteAuthDataSource _remoteAuthDataSource = RemoteAuthDataSource(
    _httpClient,
  );
  late final CustomHTTPClient _httpClient = CustomHTTPClient(_localAuthDataSource);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CustomHTTPClient>(
          create: (ctx) => _httpClient,
        ),
        RepositoryProvider.value(value: _localStorage),
        RepositoryProvider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            localAuthDataSource: _localAuthDataSource,
            remoteAuthDataSource: _remoteAuthDataSource,
          ),
        ),
        RepositoryProvider<DeviceModelService>(
          create: (ctx) => DeviceModelService(),
        ),
        // RepositoryProvider<FirebaseService>(
        //   lazy: false,
        //   create: (ctx) =>
        //       FirebaseService(getAuthTokenUseCase: GetAuthTokenUseCase(ctx.read<AuthRepository>()))..initialize(),
        // ),
      ],
      child: widget.child,
    );
  }
}

class AppBlocProvider extends StatelessWidget {
  const AppBlocProvider({super.key, required this.child});

  final Widget child;
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocalizationCubit>(
          create: (ctx) {
            final LocalLocalizationDataSource dataSource = LocalLocalizationDataSource(ctx.read<LocalStorage>());
            final LocalizationRepository repo = LocalizationRepositoryImpl(
              dataSource,
            );

            return LocalizationCubit(
              getLocaleUseCase: GetLocaleUseCase(localizationRepository: repo),
              setLocaleUseCase: SetLocaleUseCase(localizationRepository: repo),
            )..getLocale();
          },
        ),
        BlocProvider<VideoPlayerCubit>(
          create: (context) {
            return VideoPlayerCubit(
              getAuthTokenUseCase: GetAuthTokenUseCase(
                context.read<AuthRepository>(),
              ),
            );
          },
        ),
        BlocProvider<AppCubit>(
          create: (ctx) {
            final AuthRepository repo = ctx.read<AuthRepository>();

            return AppCubit(
              getAuthTokenUseCase: GetAuthTokenUseCase(repo),
              logoutUseCase: LogoutUseCase(repo),
              authStatusUseCase: AuthStatusUseCase(repo),
            );
          },
        ),
        BlocProvider<NotificationBannerCubit>(
          create: (context) => NotificationBannerCubit(),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(),
        ),
      ],
      child: BlocListener<AppCubit, AppState>(
        // Trigger router refresh for redirections on auth state or app init state changes
        // Logic is stored in gorouter redirector
        listenWhen: (previous, current) =>
            previous.isInitialized != current.isInitialized || previous.isAuthenticated != current.isAuthenticated,
        listener: (context, state) {
          if (!state.isInitialized) return;

          if (state.isAuthenticated && state.shouldNavigateToPaymentPage) {
            context.read<AppCubit>().hideDialog();

            if (state.isAuthenticated) {
              context.pushReplacementNamed(AppView.path);
            }

            // if (!Platform.isIOS) {
            //   router.pushReplacementNamed(SubscribePage.name);
            // }

            return;
          }
        },
        child: _ThemeWrapper(child: child),
      ),
    );
  }
}

class _ThemeWrapper extends StatefulWidget {
  final Widget child;

  const _ThemeWrapper({required this.child});

  @override
  State<_ThemeWrapper> createState() => _ThemeWrapperState();
}

class _ThemeWrapperState extends State<_ThemeWrapper> {
  final GlobalKey<ThemeColorListenerState> _themeKey = GlobalKey<ThemeColorListenerState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<ThemeCubit, ThemeState>(
      listener: (context, state) {
        // Update theme when ThemeCubit state changes
        final currentColors = context.read<ThemeCubit>().currentColors;
        _themeKey.currentState?.updateTheme(currentColors);
      },
      child: ThemeColorListener(
        key: _themeKey,
        initialTheme: UiKitColors.blue,
        child: widget.child,
      ),
    );
  }
}

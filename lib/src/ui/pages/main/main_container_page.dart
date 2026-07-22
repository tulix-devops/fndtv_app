import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/pages/home/new_home_page.dart';
import 'package:fndtv/src/ui/pages/live/new_live_page.dart';
import 'package:fndtv/src/ui/pages/on_demand/new_on_demand_page.dart';
import 'package:fndtv/src/ui/pages/radio/new_radio_page.dart';
import 'package:fndtv/src/ui/pages/about/new_about_page.dart';
import 'package:fndtv/src/ui/pages/settings/settings_page.dart';
import 'package:fndtv/src/ui/widgets/fndtv_bottom_navigation_bar.dart';
import 'package:fndtv/src/ui/widgets/radio/radio_mini_bar.dart';
import 'package:app_localization/app_localization.dart';
import 'package:ui_kit/ui_kit.dart';

class MainContainerPage extends StatefulWidget {
  static const path = '/main';
  static const name = 'main-container';

  const MainContainerPage({super.key});

  @override
  State<MainContainerPage> createState() => _MainContainerPageState();
}

class _MainContainerPageState extends State<MainContainerPage> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    // Show the device status bar (time/battery) over the red app bar with white
    // icons. Done once here — calling setEnabledSystemUIMode on every build
    // resets the overlay style to dark icons (invisible on red).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    // Load live (type 8) + radio (type 10) + on-demand/VOD (type 17).
    context.read<ContentCubit>().getContentForMultipleTypes([8, 10, 17]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final tabTitles = [
      l.tabTitleHome,
      l.tabTitleLive,
      l.tabTitleOnDemand,
      l.tabTitleRadio,
      l.tabTitleAbout,
    ];
    final tabSubtitles = [
      l.tabSubtitleHome,
      l.tabSubtitleLive,
      l.tabSubtitleOnDemand,
      l.tabSubtitleRadio,
      '',
    ];
    // Language drives both the UI locale and the channel-language filter; derive
    // it from the LocalizationCubit so a persisted locale stays in sync.
    final selectedLanguage = FndtvLanguage.fromLocaleCode(
      context.watch<LocalizationCubit>().state.locale.languageCode,
    );
    final pages = [
      NewHomePage(language: selectedLanguage),
      NewLivePage(language: selectedLanguage),
      NewOnDemandPage(language: selectedLanguage),
      NewRadioPage(language: selectedLanguage),
      NewAboutPage(language: selectedLanguage),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFA83734), // red strip (non-edge-to-edge fallback)
        statusBarIconBrightness: Brightness.light, // white icons (Android)
        statusBarBrightness: Brightness.dark, // white icons (iOS)
      ),
      child: Scaffold(
      body: Column(
        children: [
          // App bar
          Container(
              color: const Color(0xFFA83734),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/img/main_logo_transparent.png',
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tabTitles[_currentIndex],
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (tabSubtitles[_currentIndex].isNotEmpty)
                          Text(
                            tabSubtitles[_currentIndex],
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Language selector — switches both the UI locale and the
                  // channel-language filter.
                  _LanguageSelector(
                    selected: selectedLanguage,
                    onChanged: (lang) =>
                        context.read<LocalizationCubit>().setLocale(lang.localeCode),
                  ),
                  // Settings button on About tab (now index 4 after On Demand)
                  if (_currentIndex == 4) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pushNamed(SettingsPage.path),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const BouncingScrollPhysics(),
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spotify-style persistent radio mini-player (hidden when idle)
          const RadioMiniBar(),
          FNDTVBottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LANGUAGE SELECTOR (app bar)
// ═══════════════════════════════════════════════════════════════════════════

/// App-bar language button — a clean circular globe that opens a branded
/// bottom sheet listing the three languages.
class _LanguageSelector extends StatelessWidget {
  final FndtvLanguage selected;
  final ValueChanged<FndtvLanguage> onChanged;

  const _LanguageSelector({required this.selected, required this.onChanged});

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) => _LanguageSheet(
        selected: selected,
        onChanged: (lang) {
          Navigator.of(sheetContext).pop();
          if (lang != selected) onChanged(lang);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l.selectLanguage,
      child: InkWell(
        onTap: () => _openSheet(context),
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
          ),
          child: CountryFlag.fromCountryCode(
            selected.countryCode,
            height: 32,
            width: 32,
            shape: const Circle(),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for picking the app language.
class _LanguageSheet extends StatelessWidget {
  final FndtvLanguage selected;
  final ValueChanged<FndtvLanguage> onChanged;

  const _LanguageSheet({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l.selectLanguage,
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            for (final lang in FndtvLanguage.values)
              _LanguageRow(
                lang: lang,
                isSelected: lang == selected,
                colors: colors,
                onTap: () => onChanged(lang),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final FndtvLanguage lang;
  final bool isSelected;
  final UiKitColors colors;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.lang,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.accent.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? colors.accent : colors.border,
                width: isSelected ? 1.4 : 0.6,
              ),
            ),
            child: Row(
              children: [
                CountryFlag.fromCountryCode(
                  lang.countryCode,
                  height: 24,
                  width: 34,
                  shape: const RoundedRectangle(4),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    lang.endonym,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? colors.accent : colors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: colors.accent, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

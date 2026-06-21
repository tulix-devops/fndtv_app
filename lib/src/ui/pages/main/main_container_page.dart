import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/pages/home/new_home_page.dart';
import 'package:fndtv/src/ui/pages/live/new_live_page.dart';
import 'package:fndtv/src/ui/pages/radio/new_radio_page.dart';
import 'package:fndtv/src/ui/pages/about/new_about_page.dart';
import 'package:fndtv/src/ui/pages/settings/settings_page.dart';
import 'package:fndtv/src/ui/widgets/fndtv_bottom_navigation_bar.dart';
import 'package:fndtv/src/ui/widgets/radio/radio_mini_bar.dart';
import 'package:app_localization/app_localization.dart';

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
    // Load live (type 8) + radio (type 10) channels from the API.
    context.read<ContentCubit>().getContentForMultipleTypes([8, 10]);
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
    final tabTitles = [l.tabTitleHome, l.tabTitleLive, l.tabTitleRadio, l.tabTitleAbout];
    final tabSubtitles = [l.tabSubtitleHome, l.tabSubtitleLive, l.tabSubtitleRadio, ''];
    // Language drives both the UI locale and the channel-language filter; derive
    // it from the LocalizationCubit so a persisted locale stays in sync.
    final selectedLanguage = FndtvLanguage.fromLocaleCode(
      context.watch<LocalizationCubit>().state.locale.languageCode,
    );
    final pages = [
      NewHomePage(language: selectedLanguage),
      NewLivePage(language: selectedLanguage),
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
                  // Settings button on About tab
                  if (_currentIndex == 3) ...[
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

class _LanguageSelector extends StatelessWidget {
  final FndtvLanguage selected;
  final ValueChanged<FndtvLanguage> onChanged;

  const _LanguageSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<FndtvLanguage>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: context.l.selectLanguage,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => FndtvLanguage.values.map((lang) {
        final isSelected = lang == selected;
        return PopupMenuItem<FndtvLanguage>(
          value: lang,
          child: Row(
            children: [
              CountryFlag.fromCountryCode(
                lang.countryCode,
                height: 18,
                width: 26,
                shape: const RoundedRectangle(3),
              ),
              const SizedBox(width: 10),
              Text(
                lang.endonym,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFFA83734) : Colors.black87,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(Icons.check, size: 16, color: Color(0xFFA83734)),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountryFlag.fromCountryCode(
              selected.countryCode,
              height: 18,
              width: 26,
              shape: const RoundedRectangle(3),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

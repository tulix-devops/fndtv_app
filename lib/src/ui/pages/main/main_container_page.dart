import 'package:commons/commons.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/ui/widgets/fndtv_bottom_navigation_bar.dart';
import 'package:fndtv/src/ui/widgets/radio/radio_mini_bar.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart'
    show kTvBg, kTvAccent;
import 'package:fndtv/src/ui/widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/bloc/network_cubit/network_cubit.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/core/constants/stb_radio_policy.dart';
import 'package:fndtv/src/ui/pages/home/new_home_page.dart';
import 'package:fndtv/src/ui/pages/live/new_live_page.dart';
import 'package:fndtv/src/ui/pages/on_demand/new_on_demand_page.dart';
import 'package:fndtv/src/ui/pages/radio/new_radio_page.dart';
import 'package:fndtv/src/ui/pages/about/new_about_page.dart';
import 'package:fndtv/src/ui/pages/updates/tv_updates_page.dart';
import 'package:fndtv/src/ui/pages/network/tv_network_page.dart';
import 'package:fndtv/src/ui/pages/settings/tv_settings_page.dart';
import 'package:fndtv/src/ui/pages/settings/settings_page.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/services/stb_system_service.dart';
import 'package:ui_kit/ui_kit.dart';

enum _MainTab {
  home,
  live,
  onDemand,
  radio,
  about,
}

extension _MainTabX on _MainTab {
  String title(BuildContext context) => switch (this) {
        _MainTab.home => context.l.tabTitleHome,
        _MainTab.live => context.l.tabTitleLive,
        _MainTab.onDemand => context.l.tabTitleOnDemand,
        _MainTab.radio => context.l.tabTitleRadio,
        _MainTab.about => context.l.tabTitleAbout,
      };

  String subtitle(BuildContext context) => switch (this) {
        _MainTab.home => context.l.tabSubtitleHome,
        _MainTab.live => context.l.tabSubtitleLive,
        _MainTab.onDemand => context.l.tabSubtitleOnDemand,
        _MainTab.radio => context.l.tabSubtitleRadio,
        _MainTab.about => '',
      };

  /// Nav-rail icon. Lives with the tab so the rail can be built by iterating
  /// whichever tabs are visible, instead of a hand-indexed list.
  IconData get navIcon => switch (this) {
        _MainTab.home => Icons.home_rounded,
        _MainTab.live => Icons.podcasts_rounded,
        _MainTab.onDemand => Icons.ondemand_video_rounded,
        _MainTab.radio => Icons.mic_rounded,
        _MainTab.about => Icons.info_rounded,
      };

  Widget buildPage(FndtvLanguage language) => switch (this) {
        _MainTab.home => NewHomePage(language: language),
        _MainTab.live => NewLivePage(language: language),
        _MainTab.onDemand => NewOnDemandPage(language: language),
        _MainTab.radio => NewRadioPage(language: language),
        _MainTab.about => NewAboutPage(language: language),
      };

  bool get showsSettingsAction => this == _MainTab.about;
}

class MainContainerPage extends StatefulWidget {
  static const path = '/main';
  static const name = 'main-container';

  const MainContainerPage({super.key});

  @override
  State<MainContainerPage> createState() => _MainContainerPageState();
}

class _MainContainerPageState extends State<MainContainerPage> {
  static const _appBarColor = Color(0xFFA83734);

  int _currentIndex = 0;
  late PageController _pageController;

  /// STB only: when true, the network manager is shown INLINE as a nav tab
  /// (nav rail stays alive) instead of a pushed full-screen page. Set when the
  /// network item is selected while online; cleared when a real tab is chosen.
  bool _networkTabActive = false;

  /// Lets us restore D-pad focus to the TV nav rail after the language dialog
  /// closes (its item focus nodes get disposed while the dialog holds focus).
  final GlobalKey<AppScaffoldState> _scaffoldKey = GlobalKey<AppScaffoldState>();

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
    // Live (8), Radio (10), On Demand / VOD (17).
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
    if (index == _currentIndex) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Content tabs offered for [language].
  ///
  /// Radio is dropped entirely where the language has none — Spanish today. The
  /// client asked for "no mention of it", and a Radio tab whose only content is
  /// "no radio channel available" is both a mention and reads as a fault. See
  /// [isRadioAvailableForLanguage].
  List<_MainTab> _visibleTabs(FndtvLanguage language) =>
      isRadioAvailableForLanguage(language)
          ? _MainTab.values
          : _MainTab.values.where((t) => t != _MainTab.radio).toList();

  // The action items (language, updates, network, settings) sit AFTER the
  // content tabs, so their indices are derived from however many tabs are
  // showing rather than hardcoded — dropping Radio shifts every one of them.
  int _languageNavIndex(int tabCount) => tabCount;
  int _updatesNavIndex(int tabCount) => tabCount + 1;
  int _networkNavIndex(int tabCount) => tabCount + 2;
  int _settingsNavIndex(int tabCount) => tabCount + 3;

  void _onNavSelected(int index, int tabCount) {
    if (index == _languageNavIndex(tabCount)) {
      _openTvLanguageDialog();
      return;
    }
    if (index == _updatesNavIndex(tabCount)) {
      _openUpdatesPage();
      return;
    }
    if (index == _networkNavIndex(tabCount)) {
      _selectNetwork();
      return;
    }
    if (index == _settingsNavIndex(tabCount)) {
      _openSettingsPage();
      return;
    }
    // A real content tab — leave the inline network view if it was showing.
    if (_networkTabActive) setState(() => _networkTabActive = false);
    _onTabTapped(index);
  }

  /// Network nav item. ONLINE → embed the network manager as an inline tab so
  /// the nav rail stays alive (Right moves into it, Left/Back return to the
  /// rail, like every other tab). OFFLINE → nothing else is usable, and the
  /// offline overlay already covers the rail, so push it full-screen instead.
  void _selectNetwork() {
    final online = context.read<NetworkCubit>().state.online;
    if (online) {
      setState(() => _networkTabActive = true);
    } else {
      _openNetworkPage();
    }
  }

  /// TV software-update check — a full-screen pushed page; focus returns to the
  /// nav rail once it closes.
  Future<void> _openUpdatesPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TvUpdatesPage()),
    );
    if (mounted) _scaffoldKey.currentState?.requestNavFocus();
  }

  /// Box settings — a full-screen pushed page; focus returns to the nav rail
  /// once it closes, like Updates and Network.
  Future<void> _openSettingsPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TvSettingsPage()),
    );
    if (mounted) _scaffoldKey.currentState?.requestNavFocus();
  }

  Future<void> _openNetworkPage() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TvNetworkPage()),
    );
    if (mounted) _scaffoldKey.currentState?.requestNavFocus();
  }

  /// TV language picker. A full-screen pushed page (not a dialog/bottom sheet)
  /// so the remote gets its own focus scope with nothing interactive behind it,
  /// and focus is handed back to the nav rail once it closes.
  Future<void> _openTvLanguageDialog() async {
    final selected = FndtvLanguage.fromLocaleCode(
      context.read<LocalizationCubit>().state.locale.languageCode,
    );
    final localizationCubit = context.read<LocalizationCubit>();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _TvLanguagePage(
          selected: selected,
          onSelected: (lang) {
            if (lang != selected) {
              localizationCubit.setLocale(lang.localeCode);
            }
          },
        ),
      ),
    );
    if (mounted) _scaffoldKey.currentState?.requestNavFocus();
  }

  Widget _buildBody(
    BuildContext context,
    _MainTab currentTab,
    FndtvLanguage selectedLanguage,
    List<_MainTab> tabs,
  ) {
    return Column(
      children: [
        // App bar
        if (!context.isTv)
          Container(
            color: _appBarColor,
            padding: EdgeInsets.fromLTRB(
                16, MediaQuery.of(context).padding.top + 12, 16, 8),
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
                        currentTab.title(context),
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (currentTab.subtitle(context).isNotEmpty)
                        Text(
                          currentTab.subtitle(context),
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
                  onChanged: (lang) => context
                      .read<LocalizationCubit>()
                      .setLocale(lang.localeCode),
                ),
                // Settings button on About tab
                if (currentTab.showsSettingsAction) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.settings,
                        color: Colors.white, size: 26),
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(SettingsPage.path),
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: PageView.builder(
            scrollDirection: context.isTv ? Axis.vertical : Axis.horizontal,
            controller: _pageController,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemCount: tabs.length,
            itemBuilder: (context, index) => Padding(
              padding: context.isTv ? EdgeInsets.zero : const EdgeInsets.all(8.0),
              child: tabs[index].buildPage(selectedLanguage),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Language drives both the UI locale and the channel-language filter; derive
    // it from the LocalizationCubit so a persisted locale stays in sync.
    final selectedLanguage = FndtvLanguage.fromLocaleCode(
      context.watch<LocalizationCubit>().state.locale.languageCode,
    );

    // Switching to a language with fewer tabs (Spanish loses Radio) can leave
    // the cursor past the end — clamp before indexing, and pull the PageView
    // back in step after this frame.
    final tabs = _visibleTabs(selectedLanguage);
    if (_currentIndex >= tabs.length) {
      _currentIndex = tabs.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_currentIndex);
        }
      });
    }
    final currentTab = tabs[_currentIndex];

    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: _appBarColor, // red strip (non-edge-to-edge fallback)
          statusBarIconBrightness: Brightness.light, // white icons (Android)
          statusBarBrightness: Brightness.dark, // white icons (iOS)
        ),
        child: context.isTv
            ? AppScaffold(
                key: _scaffoldKey,
                color: kTvBg,
                currentNavIndex: _networkTabActive
                    ? _networkNavIndex(tabs.length)
                    : _currentIndex,
                onNavChanged: (i) => _onNavSelected(i, tabs.length),
                navigationItems: [
                  for (final tab in tabs)
                    (label: tab.title(context), icon: tab.navIcon),
                  // Language switcher — shows the active language, opens a popup.
                  (label: selectedLanguage.endonym, icon: Icons.language_rounded),
                  // Software update check — opens a popup.
                  (
                    label: context.l.navUpdates,
                    icon: Icons.system_update_rounded
                  ),
                  // STB: in-app network manager — inline tab when online,
                  // full-screen when offline.
                  if (StbSystemService.isStb)
                    (label: context.l.navNetwork, icon: Icons.wifi_rounded),
                  // STB: box settings — sits directly below Network.
                  if (StbSystemService.isStb)
                    (
                      label: context.l.navSettings,
                      icon: Icons.settings_rounded
                    ),
                ],
                body: _networkTabActive
                    ? const TvNetworkView(autofocusOnEnter: false)
                    : _buildBody(context, currentTab, selectedLanguage, tabs),
                hasNavbar: true,
              )
            : Scaffold(
                body: _buildBody(context, currentTab, selectedLanguage, tabs),
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
              ));
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
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.85), width: 1.5),
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

// ═══════════════════════════════════════════════════════════════════════════
// LANGUAGE PAGE (TV — full-screen, D-pad focusable)
// ═══════════════════════════════════════════════════════════════════════════

/// A full-screen, remote-focusable language picker for the TV UI. Pushed as its
/// own route so nothing is interactive behind it — the D-pad can only move
/// between the options here. Each option owns a [FocusNode]; the active
/// language is focused on open, and the select key applies it and pops.
class _TvLanguagePage extends StatefulWidget {
  final FndtvLanguage selected;
  final ValueChanged<FndtvLanguage> onSelected;

  const _TvLanguagePage({required this.selected, required this.onSelected});

  @override
  State<_TvLanguagePage> createState() => _TvLanguagePageState();
}

class _TvLanguagePageState extends State<_TvLanguagePage> {
  final _langs = FndtvLanguage.values;
  late final List<FocusNode> _nodes;
  late final int _selectedIndex;

  @override
  void initState() {
    super.initState();
    final idx = _langs.indexOf(widget.selected);
    _selectedIndex = idx < 0 ? 0 : idx;
    _nodes = List.generate(_langs.length, (i) {
      return FocusNode(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (i > 0) _nodes[i - 1].requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (i < _langs.length - 1) _nodes[i + 1].requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes[_selectedIndex].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _select(FndtvLanguage lang) {
    widget.onSelected(lang);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kTvBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.language_rounded,
                      color: kTvAccent, size: 30),
                  const SizedBox(width: 12),
                  Text(
                    context.l.selectLanguage,
                    style: GoogleFonts.sora(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              for (var i = 0; i < _langs.length; i++)
                _TvLangRow(
                  lang: _langs[i],
                  isSelected: _langs[i] == widget.selected,
                  focusNode: _nodes[i],
                  autofocus: i == _selectedIndex,
                  onTap: () => _select(_langs[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single focusable row in the TV language dialog. Highlights solid red when
/// the remote focuses it, red-tinted when it's the active language.
class _TvLangRow extends StatefulWidget {
  final FndtvLanguage lang;
  final bool isSelected;
  final FocusNode focusNode;
  final bool autofocus;
  final VoidCallback onTap;

  const _TvLangRow({
    required this.lang,
    required this.isSelected,
    required this.focusNode,
    required this.autofocus,
    required this.onTap,
  });

  @override
  State<_TvLangRow> createState() => _TvLangRowState();
}

class _TvLangRowState extends State<_TvLangRow> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool focused = _focused;
    final bool selected = widget.isSelected;

    final Color bg = focused
        ? kTvAccent
        : (selected ? kTvAccent.withValues(alpha: 0.16) : Colors.transparent);
    final Color fg =
        focused ? Colors.white : (selected ? kTvAccent : Colors.white70);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused || selected ? kTvAccent : Colors.white24,
                width: focused || selected ? 1.4 : 0.6,
              ),
            ),
            child: Row(
              children: [
                CountryFlag.fromCountryCode(
                  widget.lang.countryCode,
                  height: 26,
                  width: 36,
                  shape: const RoundedRectangle(4),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.lang.endonym,
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight:
                          focused || selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: fg, size: 22),
              ],
            ),
          ),
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
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? colors.accent : colors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded,
                      color: colors.accent, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

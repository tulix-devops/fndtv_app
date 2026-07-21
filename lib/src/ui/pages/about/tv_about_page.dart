import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/ui/widgets/tv/tv_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// About (TV) — dark, 10-foot layout. Scrolls with the D-pad: each block is a
/// focus stop, so pressing up/down walks through the content and scrolls it
/// into view. Includes the language switcher (the TV app bar has none).
class TvAboutPage extends StatelessWidget {
  final FndtvLanguage language;

  const TvAboutPage({super.key, required this.language});

  static const Map<FndtvLanguage, String> _donationUrls = {
    FndtvLanguage.english:
        'https://www.paypal.com/donate/?hosted_button_id=4N3KECJ66BZT8',
    FndtvLanguage.french:
        'https://www.paypal.com/donate/?hosted_button_id=JD4CNUCNAE688',
    FndtvLanguage.spanish:
        'https://www.paypal.com/donate/?hosted_button_id=GXRAG3GWKXDDQ',
  };

  /// TV can't easily open/navigate a browser with a remote, so show the
  /// donation URL as a QR code (scan with a phone) plus the link text.
  void _showDonateDialog(BuildContext context) {
    final url = _donationUrls[language]!;
    final l = context.l;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (dialogContext) => Dialog(
        backgroundColor: kTvSurface,
        insetPadding: const EdgeInsets.all(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.aboutSupportTitle,
                style: GoogleFonts.sora(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.donateScanHint,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 168,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTvAccent,
                ),
              ),
              const SizedBox(height: 16),
              _DialogCloseButton(onTap: () => Navigator.of(dialogContext).pop()),
            ],
          ),
        ),
      ),
    );
  }

  void _openLanguageSheet(BuildContext context, FndtvLanguage selected) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TvLanguageSheet(
        selected: selected,
        onPick: (lang) {
          Navigator.of(sheetContext).pop();
          if (lang != selected) {
            context.read<LocalizationCubit>().setLocale(lang.localeCode);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final intro = [
      l.aboutIntro1,
      l.aboutIntro2,
      l.aboutIntro3,
      l.aboutIntro4,
      l.aboutIntro5,
    ];
    final selectedLanguage = FndtvLanguage.fromLocaleCode(
      context.watch<LocalizationCubit>().state.locale.languageCode,
    );

    final paraStyle = GoogleFonts.sora(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.7,
      color: Colors.white70,
    );

    return Scaffold(
      backgroundColor: kTvBg,
      body: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(64, 40, 64, 64),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crest header
              _AboutSection(
                autofocus: true,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA83734),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/img/main_logo_transparent.png',
                      height: 74,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // What is FNDTV?
              TvSectionHeader(l.aboutWhatTitle),
              const SizedBox(height: 4),
              for (final paragraph in intro)
                _AboutSection(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(paragraph, style: paraStyle),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                l.aboutPlatform,
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kTvAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '502 N Central Ave Chicago, IL 60644 - USA',
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 34),

              // Support
              TvSectionHeader(l.aboutSupportTitle),
              const SizedBox(height: 8),
              Text(l.aboutDonatePrompt, style: paraStyle),
              const SizedBox(height: 18),
              _TvAboutButton(
                flagCountryCode: language.countryCode,
                label: l.donate,
                trailingIcon: Icons.qr_code_2_rounded,
                onTap: () => _showDonateDialog(context),
              ),
              const SizedBox(height: 34),

              // Language
              TvSectionHeader(l.selectLanguage),
              const SizedBox(height: 12),
              _TvAboutButton(
                flagCountryCode: selectedLanguage.countryCode,
                label: selectedLanguage.endonym,
                trailingIcon: Icons.expand_more_rounded,
                onTap: () => _openLanguageSheet(context, selectedLanguage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Non-interactive block that becomes a d-pad focus stop and scrolls itself
/// into view when focused.
class _AboutSection extends StatelessWidget {
  final Widget child;
  final bool autofocus;

  const _AboutSection({required this.child, this.autofocus = false});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Scrollable.ensureVisible(
                context,
                alignment: 0.25,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      },
      child: child,
    );
  }
}

/// A focusable pill button for TV (donate / language). Highlights red on focus
/// and scrolls into view.
class _TvAboutButton extends StatefulWidget {
  final String flagCountryCode;
  final String label;
  final IconData trailingIcon;
  final VoidCallback onTap;

  const _TvAboutButton({
    required this.flagCountryCode,
    required this.label,
    required this.trailingIcon,
    required this.onTap,
  });

  @override
  State<_TvAboutButton> createState() => _TvAboutButtonState();
}

class _TvAboutButtonState extends State<_TvAboutButton> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (!mounted) return;
    setState(() => _focused = _node.hasFocus);
    if (_node.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Scrollable.ensureVisible(context,
              alignment: 0.5, duration: const Duration(milliseconds: 260));
        }
      });
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        focusNode: _node,
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _focused ? kTvAccent : kTvSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused ? kTvAccent : Colors.white12,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CountryFlag.fromCountryCode(
                widget.flagCountryCode,
                height: 22,
                width: 30,
                shape: const RoundedRectangle(4),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              Icon(widget.trailingIcon, color: Colors.white70, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Focusable close button for the donate dialog (Back also dismisses).
class _DialogCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DialogCloseButton({required this.onTap});

  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() {
      if (mounted) setState(() => _focused = _node.hasFocus);
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      focusNode: _node,
      autofocus: true,
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: _focused ? kTvAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _focused ? kTvAccent : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'OK',
              style: GoogleFonts.sora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Language picker sheet for TV.
class _TvLanguageSheet extends StatelessWidget {
  final FndtvLanguage selected;
  final ValueChanged<FndtvLanguage> onPick;

  const _TvLanguageSheet({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: kTvSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                context.l.selectLanguage,
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            for (final (index, lang) in FndtvLanguage.values.indexed)
              _TvLanguageRow(
                lang: lang,
                isSelected: lang == selected,
                autofocus: index == 0,
                onTap: () => onPick(lang),
              ),
          ],
        ),
      ),
    );
  }
}

class _TvLanguageRow extends StatefulWidget {
  final FndtvLanguage lang;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onTap;

  const _TvLanguageRow({
    required this.lang,
    required this.isSelected,
    required this.autofocus,
    required this.onTap,
  });

  @override
  State<_TvLanguageRow> createState() => _TvLanguageRowState();
}

class _TvLanguageRowState extends State<_TvLanguageRow> {
  final FocusNode _node = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(() {
      if (mounted) setState(() => _focused = _node.hasFocus);
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = _focused || widget.isSelected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        focusNode: _node,
        autofocus: widget.autofocus,
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _focused
                ? kTvAccent
                : (widget.isSelected
                    ? kTvAccent.withValues(alpha: 0.16)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: highlight ? kTvAccent : Colors.white12,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              CountryFlag.fromCountryCode(
                widget.lang.countryCode,
                height: 22,
                width: 32,
                shape: const RoundedRectangle(4),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.lang.endonym,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

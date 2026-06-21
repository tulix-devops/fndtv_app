import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_localization/app_localization.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class NewAboutPage extends StatelessWidget {
  final FndtvLanguage language;

  const NewAboutPage({super.key, required this.language});

  /// Donation links by language.
  static const Map<FndtvLanguage, String> _donationUrls = {
    FndtvLanguage.english:
        'https://www.paypal.com/donate/?hosted_button_id=4N3KECJ66BZT8',
    FndtvLanguage.french:
        'https://www.paypal.com/donate/?hosted_button_id=JD4CNUCNAE688',
    FndtvLanguage.spanish:
        'https://www.paypal.com/donate/?hosted_button_id=GXRAG3GWKXDDQ',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;
    final l = context.l;
    final intro = [l.aboutIntro1, l.aboutIntro2, l.aboutIntro3, l.aboutIntro4, l.aboutIntro5];

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Branded crest header ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFA83734),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Center(
                child: Image.asset(
                  'assets/img/main_logo_transparent.png',
                  height: 92,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── What is FNDTV? ───
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Heading(text: l.aboutWhatTitle, colors: colors),
                  const SizedBox(height: 14),
                  for (final paragraph in intro) ...[
                    Text(
                      paragraph,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  // Address
                  Text(
                    l.aboutPlatform,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '502 N Central Ave Chicago, IL 60644 - USA',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ─── Donations ───
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Heading(text: l.aboutSupportTitle, colors: colors),
                  const SizedBox(height: 10),
                  Text(
                    l.aboutDonatePrompt,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DonationButton(
                    language: language,
                    url: _donationUrls[language]!,
                    colors: colors,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(width: 0.5, color: colors.border),
      ),
      child: child,
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  final UiKitColors colors;

  const _Heading({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.sora(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DonationButton extends StatelessWidget {
  final FndtvLanguage language;
  final String url;
  final UiKitColors colors;

  const _DonationButton({
    required this.language,
    required this.url,
    required this.colors,
  });

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.donationOpenError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.accent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _launch(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CountryFlag.fromCountryCode(
                language.countryCode,
                height: 20,
                width: 28,
                shape: const RoundedRectangle(3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.l.donate,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Icon(Icons.favorite, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Icon(Icons.open_in_new, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

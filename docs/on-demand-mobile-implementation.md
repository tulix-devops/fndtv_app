# On Demand tab — mobile implementation guide

Context doc for porting the **On Demand** (VOD) tab to the **Mobile Version
branch**, which currently has no On Demand tab. This describes the working
implementation on `feat/tv_version` (fndtv_app). Everything below is
mobile-only unless noted; the TV variant is included for reference.

---

## 1. What it is

On Demand is the selected language's **VOD library** — backend **content type
`17`**. It's a scrollable poster grid; tapping a poster opens the video player.
It sits as the 3rd bottom-nav tab (index 2), between Live and Radio.

## 2. Data flow (the important part)

VOD content comes from the **same `ContentCubit`** that already powers Home /
Live / Radio — no new cubit, repository, or endpoint is needed. Two facts:

1. **Content type 17 must be loaded.** Wherever the app kicks off content
   loading (on the main container's `initState`), the type list must include
   `17`:
   ```dart
   context.read<ContentCubit>().getContentForMultipleTypes([8, 10, 17]);
   //                                                          ^8 live ^10 radio ^17 VOD
   ```
   If the mobile branch currently loads only `[8, 10]`, add `17`.

2. **Read + filter by language.** VOD items live at
   `state.contentList?['17']?.data` (a `List<LiveModel>?`). Filter to the
   active language with the existing helper
   (`lib/src/core/constants/fndtv_channels.dart`):
   ```dart
   List<LiveModel> channelsForLanguage(List<LiveModel>? items, FndtvLanguage lang) {
     if (items == null) return const [];
     final code = lang.label.toLowerCase();
     return items
         .where((m) => (m.details?.language ?? '').toLowerCase() == code)
         .toList();
   }
   ```
   Usage: `channelsForLanguage(state.contentList?['17']?.data, language)`.

3. **Loading / error / empty states** reuse the shared widgets already used by
   the other tabs (from `channel_tiles.dart` / commons): `contentIsLoading(state)`,
   `ContentLoading(colors: ...)`, `ContentError(colors: ...)`, and an empty
   fallback.

## 3. Model fields used (`LiveModel`)

- `item.title` — poster title.
- `item.images.getBanner()` — poster image URL (16:9). Guard with an
  `errorBuilder` fallback icon.
- `item.details?.language` — used by the language filter above.

## 4. Opening a video

Reuse the existing `openChannel` helper (`channel_tiles.dart`) with
`ContentType.dvr` — On Demand items are DVR/archive content:
```dart
openChannel(context, item, ContentType.dvr);
// → Navigator.pushNamed(VideoPlayerPage.path, arguments: {
//      'channel': item, 'contentCubit': ..., 'contentType': ContentType.dvr });
```
The `VideoPlayerPage` route must be registered (it already is, since Live/Radio
use the same player). No new route needed.

## 5. The mobile page (drop-in)

`lib/src/ui/pages/on_demand/mobile_on_demand_page.dart` — single-column poster
grid, 16:9 cards with a bottom gradient + title, tap to play:

```dart
import 'package:commons/commons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fndtv/src/bloc/content_cubit/content_cubit.dart';
import 'package:fndtv/src/core/constants/fndtv_channels.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/ui/widgets/channel/channel_tiles.dart';
import 'package:ui_kit/ui_kit.dart';

/// On Demand (mobile) — a poster grid of the selected language's VOD items.
class MobileOnDemandPage extends StatelessWidget {
  final FndtvLanguage language;

  const MobileOnDemandPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return BlocBuilder<ContentCubit, ContentState>(
      builder: (context, state) {
        if (contentIsLoading(state)) return ContentLoading(colors: colors);
        if (state.status == Status.failure) {
          return ContentError(colors: colors);
        }

        final items =
            channelsForLanguage(state.contentList?['17']?.data, language);

        if (items.isEmpty) {
          return _Empty(colors: colors);
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            childAspectRatio: 16 / 9,
            mainAxisSpacing: 14,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _VodPosterCard(item: items[i]),
        );
      },
    );
  }
}

class _VodPosterCard extends StatelessWidget {
  final LiveModel item;

  const _VodPosterCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.uiKitColors;

    return GestureDetector(
      onTap: () => openChannel(context, item, ContentType.dvr),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              item.images.getBanner(),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: colors.bgSurface,
                child: Icon(Icons.movie_rounded,
                    size: 40, color: colors.textHint),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 92,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final UiKitColors colors;

  const _Empty({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_rounded, size: 44, color: colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No videos available',
            style: GoogleFonts.sora(color: colors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
```

**Dispatcher** — if the mobile branch has the TV/mobile split pattern, add
`lib/src/ui/pages/on_demand/new_on_demand_page.dart`:
```dart
class NewOnDemandPage extends StatelessWidget {
  final FndtvLanguage language;
  const NewOnDemandPage({super.key, required this.language});

  @override
  Widget build(BuildContext context) => context.isTv
      ? TvOnDemandPage(language: language)   // omit if the branch is mobile-only
      : MobileOnDemandPage(language: language);
}
```
If the Mobile branch has no TV code at all, skip `NewOnDemandPage`/`TvOnDemandPage`
and use `MobileOnDemandPage` directly.

## 6. Wiring it into the tab bar

The tabs are driven by a `_MainTab` enum + a `PageView` + the bottom nav in the
main container. On this branch On Demand is **index 2**. To add it on the
mobile branch:

1. **Enum** — add `onDemand` to `_MainTab` (order matters; it maps to the
   PageView index and the nav index):
   ```dart
   enum _MainTab { home, live, onDemand, radio, about }
   ```
2. **`buildPage`** — map it to the page:
   ```dart
   _MainTab.onDemand => MobileOnDemandPage(language: language),
   ```
   Plus its `title`/`subtitle` entries if the enum extension has them
   (`title` → `context.l.tabTitleOnDemand`).
3. **Bottom nav item** — add the item at index 2 in
   `FNDTVBottomNavigationBar` (keep indices aligned with the enum order):
   ```dart
   _NavItem(
     icon: Icons.ondemand_video_rounded,
     label: l.navOnDemand,
     isActive: currentIndex == 2,
     onTap: () => onTap(2),
   ),
   ```
   Make sure Radio/About shift to indices 3/4 accordingly.

## 7. Localization keys

Reuse existing keys if present, else add to `app_en.arb` / `app_es.arb` /
`app_fr.arb` and regenerate (`flutter gen-l10n` in `packages/app_localization`):
- `navOnDemand` — bottom-nav label (EN "On Demand", ES "Bajo demanda",
  FR "À la demande").
- `tabTitleOnDemand` / `tabSubtitleOnDemand` — if the container shows a title bar.
- `sectionOnDemand` — section header (TV only).

## 8. Checklist for the mobile branch

- [ ] `getContentForMultipleTypes([...])` includes `17`.
- [ ] `channelsForLanguage` helper present (it's shared — likely already there).
- [ ] `MobileOnDemandPage` added.
- [ ] `_MainTab` enum gains `onDemand`; `buildPage` maps it.
- [ ] Bottom-nav item added at index 2; Radio/About reindexed to 3/4.
- [ ] `navOnDemand` (+ any title keys) localized in en/es/fr.
- [ ] `VideoPlayerPage` route registered (already is if Live/Radio play).
- [ ] Verify: switch language → grid refilters; tap poster → player opens.

## 9. TV note (not needed on mobile, for reference)

The TV variant (`tv_on_demand_page.dart`) is a multi-column D-pad grid
(`SliverGridDelegateWithMaxCrossAxisExtent`, `maxCrossAxisExtent: 300`) with
focusable `_TvVodCard`s. **Focus-ring gotcha (fixed 2026-07-22):** a
`Container` `decoration` border insets its child by the border width, so a
1px→3px border change on focus resizes the poster ("twitch"). Keep the base
border a constant width and draw the focus ring via `foregroundDecoration`
(painted over the child, no inset). Mobile has no focus ring, so this doesn't
apply — but keep it in mind if a TV grid is ever added on the mobile branch.

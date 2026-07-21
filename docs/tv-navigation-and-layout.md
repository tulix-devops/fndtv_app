# Android TV — Navigation, Scroll Animation & Layout System

A reusable pattern for turning a mobile Flutter app into a proper 10‑foot TV
experience: a dark design system, a **fill‑to‑fit responsive layout**, a
**push‑content side navigation** with a slide animation, and **D‑pad
scrolling**. This document describes how it's built in FNDTV so it can be
lifted into other apps.

---

## 1. TV detection (`context.isTv`)

TV vs. mobile is decided purely by **screen size** — no platform check — so the
TV UI also renders on any large window (useful for previewing on a phone in
landscape or a desktop build).

```dart
// packages/commons/lib/shared/extensions.dart
extension MediaQueryExtensions on BuildContext {
  bool get isTv {
    final size = MediaQuery.of(this).size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    return size.width >= 720 && diagonal >= 1000; // logical px
  }
}
```

> ⚠️ **Density matters.** A "4K" TV emulator often runs at density 640 → a
> **960×540 logical** canvas, while a real 1080p TV is 1920×1080. Never hard‑code
> pixel sizes for "a TV" — size things responsively (see §3).

## 2. Per‑screen Tv/Mobile split

Each screen is a thin router that picks the variant. Keeps mobile untouched
while the TV layout evolves independently.

```dart
class NewHomePage extends StatelessWidget {
  final AppLanguage language;
  const NewHomePage({super.key, required this.language});

  @override
  Widget build(BuildContext context) => context.isTv
      ? TvHomePage(language: language)
      : MobileHomePage(language: language);
}
```

Files: `pages/<x>/new_<x>_page.dart` (router), `tv_<x>_page.dart`,
`mobile_<x>_page.dart`.

## 3. Fill‑to‑fit responsive layout

The single most important idea: **TV content is not a scrolling list — it fills
the screen and everything is visible.** Sizes derive from the space available,
so it adapts to any resolution/density and to any item count.

- The page is a `Column`, and each content row is wrapped in `Expanded`, so rows
  **share the available height** (no scrolling, nothing cut off).
- The row widget reads its height via `LayoutBuilder` and derives the card size,
  font sizes and gaps from it.
- The card width is **capped as a fraction of the available width**, so a
  single‑item page (or a narrowed row when the nav pushes content) never lets
  the poster eat the title.

```dart
// Page
Column(children: [
  for (final section in sections) ...[
    TvSectionHeader(section.title),
    Expanded(child: TvChannelRow(item: section.item)), // shares height
    const SizedBox(height: 8),
  ],
]);

// Row (poster left + title right), sizes from the given height
LayoutBuilder(builder: (context, c) {
  final h = c.maxHeight.isFinite ? c.maxHeight : 140;
  final maxW = c.maxWidth.isFinite ? c.maxWidth : 600;
  double cardH = (h - 12).clamp(56.0, 240.0);
  double cardW = cardH * (16 / 9);
  final cardWCap = maxW * 0.42;         // never > 42% of the width
  if (cardW > cardWCap) { cardW = cardWCap; cardH = cardW * (9 / 16); }
  final titleSize = (cardH * 0.22).clamp(15.0, 30.0);
  ...
});
```

## 4. Dark design system

A small shared kit (`ui/widgets/tv/tv_widgets.dart`) keeps TV screens
consistent. TV uses a **cinematic dark** palette, not the light mobile theme.

```dart
const kTvBg      = Color(0xFF0E0F13); // page background
const kTvSurface = Color(0xFF191B22); // cards / sheets
const kTvAccent  = Color(0xFFC7443F); // brand red, brightened for dark bg
```

- `TvSectionHeader` — red accent bar + white label.
- Focusable cards own a `FocusNode`, rebuild on focus change, and show a red
  border + glow (+ optional scale/play overlay) when focused (see §7).

## 5. Side navigation rail (push, not overlay)

Two pieces: `ui/widgets/app_scaffold.dart` (host + focus plumbing) and
`packages/ui_kit/lib/widgets/app_navigation_rail.dart` (the rail).

**Rail design** — one flat solid panel (no gradient → fewer tones), the app
logo on top, **Material icons matching the mobile bottom bar**, and the active/
focused item as a solid red pill:

```dart
Container(
  width: kTvNavWidth,                       // 268
  height: MediaQuery.of(context).size.height,
  decoration: const BoxDecoration(
    color: Color(0xFF15171C),
    border: Border(right: BorderSide(color: Colors.white12, width: 1)),
  ),
  child: Column(children: [logo, ...items]),
);

// nav items carry IconData (not svg strings) so they match mobile 1:1
final List<({String label, IconData icon})> navigationItems;
```

**Push + slide (the "dynamic" reveal).** When the rail is revealed (D‑pad left
focuses it), the content **slides right by the rail width** with an animation
and the rail slides in beside it — instead of dimming/overlapping the content
with a scrim. This removes the muddy multi‑layer look and keeps content bright.

```dart
final navOpen = context.isTv && hasNavbar &&
    (_placeHolderFocus.hasFocus || hasFocus);

Stack(children: [
  // content pushed right when the rail is open
  AnimatedPadding(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
    padding: EdgeInsets.only(left: navOpen ? kTvNavWidth : 0),
    child: content,
  ),
  // rail slides in from the left edge
  Positioned(left: 0, top: 0, bottom: 0,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, a) => SlideTransition(
        position: Tween(begin: const Offset(-1, 0), end: Offset.zero).animate(a),
        child: child),
      child: navOpen ? AppNavigationRail(...) : const _FocusCatcher(),
    ),
  ),
]);
```

The hidden `_FocusCatcher` (a `skipTraversal` Focus) is what catches the D‑pad
`left` press and requests the rail's focus, which flips `navOpen` and triggers
both animations. **No `Container(color: black26)` scrim** — the push does the
separation.

## 6. D‑pad scrolling (long / scrollable screens)

For genuinely tall content (e.g. an About page), TV can't touch‑scroll. Make
each block a **focus stop** and scroll it into view on focus. Pressing up/down
walks the content and scrolls smoothly; actionable items (buttons) also show a
visible focus state.

```dart
class _AboutSection extends StatelessWidget { // wraps a non‑interactive block
  final Widget child; final bool autofocus;
  @override
  Widget build(BuildContext context) => Focus(
    autofocus: autofocus,
    onFocusChange: (has) {
      if (!has) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Scrollable.ensureVisible(context,
            alignment: 0.25, duration: const Duration(milliseconds: 260));
        }
      });
    },
    child: child,
  );
}
```

Same trick powers overlays like the video **Archive** grid — focusable image
cards call `Scrollable.ensureVisible` so the grid follows the remote.

## 7. Focusable card pattern (reused everywhere)

Every remote‑navigable tile follows the same shape: own a `FocusNode`, rebuild
on focus, and render a red border + glow (+ scale / play overlay).

```dart
class _Card extends StatefulWidget { ... }
class _CardState extends State<_Card> {
  final _node = FocusNode();
  bool _focused = false;
  @override void initState() { super.initState(); _node.addListener(_f); }
  void _f() => setState(() => _focused = _node.hasFocus); // + ensureVisible if in a scroller
  @override void dispose() { _node.removeListener(_f); _node.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => InkWell(
    focusNode: _node, autofocus: widget.autofocus, onTap: widget.onTap,
    child: AnimatedScale(scale: _focused ? 1.04 : 1.0, duration: ..., child:
      Container(decoration: BoxDecoration(
        border: Border.all(color: _focused ? kTvAccent : Colors.transparent, width: 3),
        boxShadow: _focused ? [BoxShadow(color: kTvAccent.withValues(alpha: .45), blurRadius: 24)] : null,
      ), child: ...),
    ),
  );
}
```

> Keep the border **width constant** (transparent when unfocused) so focusing
> doesn't shift layout, and don't add an unfocused grey border — it reads as an
> extra "background colour".

## 8. Fullscreen semi‑transparent overlay (video Archive)

Overlays over a video (the DVR "Archive") are fullscreen and let the blurred
video show through, so the layout stays legible in context.

```dart
Positioned.fill(
  child: ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: .55), Colors.black.withValues(alpha: .80)])),
        child: Column(children: [header, dateChips, Expanded(child: imageGrid)]),
      ),
    ),
  ),
);
```

## Key files

| Concern | File |
|---|---|
| TV detection | `packages/commons/lib/shared/extensions.dart` (`isTv`) |
| Dark kit + rows | `lib/src/ui/widgets/tv/tv_widgets.dart` |
| TV screens | `lib/src/ui/pages/{home,live,radio}/tv_*_page.dart` |
| Scrollable About | `lib/src/ui/pages/about/tv_about_page.dart` |
| Nav host (push/slide, focus) | `lib/src/ui/widgets/app_scaffold.dart` |
| Nav rail (panel, icons, pill) | `packages/ui_kit/lib/widgets/app_navigation_rail.dart` |
| Video Archive overlay | `lib/src/ui/widgets/app_video_player/screens/vod_fullscreen.dart` |

## Porting checklist

1. Add `context.isTv` (size‑based).
2. Split each screen into `Tv*`/`Mobile*` behind a `new_*` router.
3. Build the dark kit (`kTvBg/kTvSurface/kTvAccent`, `TvSectionHeader`, card).
4. Lay pages out as `Column` + `Expanded` rows; size from `LayoutBuilder`; cap
   card width to ≤ ~42% of the row.
5. Wrap the nav host to **push content** (`AnimatedPadding`) + slide the rail;
   drop any scrim.
6. Give the rail a solid panel, logo, `IconData` icons matching mobile, red pill.
7. For long screens, make blocks focus stops + `Scrollable.ensureVisible`.

# FNDTV Screens Redesign — Design Spec

**Date:** 2026-06-14
**Scope:** Visual/layout redesign of the four tab screens — Home, Live, Radio, About.

## Goal & constraint

Make the screens feel modern and intentional **despite very limited data**. Channels
have only: name, logo/image URL, stream URL, language, group/type. No descriptions,
posters-with-art, schedules, ratings, or episode metadata. Language filtering means each
screen shows only 1–3 items. The redesign must **fill the screen without relying on
metadata**.

## Chosen direction: Editorial / poster (rounded)

Labeled sections with poster tiles on the light-grey canvas, soft rounded corners,
circular icon backers, and brand-color blocks + status treatments (LIVE pulse, equalizer)
standing in for missing metadata.

### Global design language
- Canvas: light grey `#ECEEF1` (unchanged), white poster tiles/cards.
- Brand: red `#A83734` (primary/accent), gold `#FFE088` (secondary/radio accent).
- Corners: soft — ~22px radius on tiles/cards (`borderRadius` 20–22).
- Icons: **rounded set**. Bottom nav keeps the approved glyphs — home / broadcast /
  microphone / info. Use Material rounded variants (`home_rounded`, a broadcast-style
  glyph, `mic_rounded`, `info_rounded`). Active tab sits in a soft red pill.
- **Play button: rounded play glyph** (`Icons.play_arrow_rounded`) — NOT the pointy
  triangle. Applies to every play affordance.
- Status bar: white icons over the red app bar (already done).
- **App bar: unchanged** in this redesign (explicit user request).

### Home
- Section `Live now` → poster tile for the selected language's live channel: the channel
  **image** as artwork, LIVE pill, name, rounded play.
- Section `Radio` → row card for the selected language's radio: circular gold mic icon,
  name, equalizer bars, rounded play.

### Live
- Same editorial pattern, three labeled sections: `Live TV`, `Radio`, `Chicago time`.
- Each shows the single channel for the selected language as a poster tile (Live TV &
  Chicago time use the channel image; Radio uses the row/equalizer treatment).

### Radio
- Sparsest screen → richest fill. Large "now playing" hero: big circular logo art with an
  **animated equalizer / waveform**, channel name, large rounded play button.

### About
- Editorial text sections. Crest as a soft rounded header element. "What is FNDTV?" copy,
  address block, single rounded Donate button for the selected language (unchanged logic).

## Key implementation notes
- Live tiles must render the channel image (`channel.logoUrl` / image) as the tile
  artwork, with graceful fallback (brand block + crest) when the image fails.
- Radio equalizer is a lightweight looping animation (no external data).
- Reuse `FndtvChannels` constants and existing navigation to `VideoPlayerPage`.
- Do not modify the app bar or the language-filter behavior.

## Out of scope
- App bar redesign, video player internals, VOD/Guide (removed), API wiring.

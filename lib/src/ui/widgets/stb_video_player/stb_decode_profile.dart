import 'package:app_logger/app_logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:media_kit/media_kit.dart';

/// libmpv decoder + video-output pair for this box.
class StbDecodeProfile {
  const StbDecodeProfile(
    this.hwdec,
    this.vo,
    this.reason, {
    this.lowPower = false,
  });
  final String hwdec;
  final String vo;

  /// Why this pair was chosen — logged so a field logcat says which path ran.
  final String reason;

  /// True on the legacy OMX boxes, where the decoded frame is copied through
  /// CPU memory instead of staying on a Surface. See [kStbLowPowerProps] for
  /// what that costs and what we do about it.
  final bool lowPower;
}

/// Picks the decode path from the Android API level, because the FNDTV fleet
/// spans two different media HALs and they need opposite settings:
///
/// * **API >= 31 (Codec2)** — e.g. X88 Pro 14, RK3528, Android 14, decoder
///   `c2.rk.avc.decoder`. Zero-copy works: `mediacodec` + `mediacodec_embed`
///   lets the decoder write straight into an Android Surface, no copy and no
///   Flutter texture upload. This is what fixed the stutter on that box.
///
/// * **API <= 30 (legacy OMX)** — e.g. X88pro10, RK3328, Android 11, decoder
///   `OMX.rk.video_decoder.avc`. Zero-copy is FATAL here. That component has no
///   metadata/DynamicANWBuffer mode, so the Surface handshake collapses during
///   buffer negotiation and MediaCodec dies before the first frame — nothing
///   plays at all. Box logcat, 2026-07-29:
///     setPortMode on output to DynamicANWBuffer failed w/ err -1010
///     error: SET buffer count: 30, count min: 19 NOW buffer count: 23
///     Failed to allocate buffers after transitioning to IDLE state (-22)
///   `mediacodec-copy` + `vo: gpu` uses ByteBuffer output instead, skipping that
///   handshake entirely, so the hardware decoder still runs.
///
/// Unknown/failed API read falls back to the copy path: slower but it plays
/// on the real hardware, and a stutter beats a black screen.
///
/// **The legacy path cannot be exercised on the Android TV emulator.** Forcing
/// it there gives a black picture — not a decoder problem (the emulator happily
/// allocates `c2.goldfish.h264.decoder`) but a render one: mpv's `vo=gpu` cannot
/// get a context, `eglCreateContext(): error 0x3004 (EGL_BAD_ATTRIBUTE)`.
/// Verified 2026-07-31 on Television_4K_2 / API 36. Anything about this branch
/// therefore has to be measured on a real RK3328 box; the emulator can only
/// confirm that mpv accepts the property names.
///
/// EVERY mpv player in the app must go through here — not just the channel
/// player. The splash boot animation ran on media_kit's defaults until
/// 2026-08-01 and showed a full-screen green picture with audio on both
/// Android 11 boxes QA tested, while the channel player (which had this
/// profile) showed no green at all on the same boxes in the same session.
Future<StbDecodeProfile> pickStbDecodeProfile() async {
  final sdk = await readAndroidSdkInt();
  if (sdk >= 31) {
    return StbDecodeProfile(
        'mediacodec', 'mediacodec_embed', 'Codec2, API $sdk');
  }
  return StbDecodeProfile(
    'mediacodec-copy',
    'gpu',
    'legacy OMX, API $sdk',
    lowPower: true,
  );
}

/// Android API level, or 0 if it cannot be read. Every decode-path decision in
/// the app keys off this one read.
Future<int> readAndroidSdkInt() async {
  try {
    return (await DeviceInfoPlugin().androidInfo).version.sdkInt;
  } catch (e) {
    logger.w('[STB] sdkInt read failed; assuming the oldest hardware: $e');
    return 0;
  }
}

/// Highest Android API level routed to the native SurfaceView player
/// (`StbSurfacePlayer`) instead of mpv.
///
/// 30 = Android 11, which is exactly where mpv is forced onto `mediacodec-copy`
/// and pays a memcpy + GL upload per frame. API >= 31 already gets zero-copy
/// through `mediacodec_embed` and plays correctly, so it deliberately stays on
/// mpv — moving a working box onto a newer path buys nothing and risks a
/// regression.
///
/// Widen to 33 if Android 12/13 boxes ever turn out to need it too; that is the
/// only edit required.
const int kStbSurfacePlayerMaxSdk = 30;

/// Network tuning for long-running live HLS on a flaky box link. Applied on
/// every box.
const Map<String, String> kStbNetworkProps = {
  // Without a timeout mpv can sit on a half-open socket indefinitely, which is
  // exactly the stall the watchdog would otherwise have to recover from.
  'network-timeout': '10',
  // ffmpeg-level reconnect handles most blips before we ever notice.
  'stream-lavf-o': 'reconnect=1,reconnect_streamed=1,reconnect_delay_max=5',
};

/// Extra tuning for the legacy OMX boxes (RK3328 / Android 11).
///
/// Why these are needed at all: `mediacodec-copy` is forced on that hardware
/// (zero-copy kills the OMX component outright — see [pickStbDecodeProfile]),
/// and the copy is not free. The master playlist carries a single rendition, so
/// there is nothing cheaper to fall back to, and the feed turns out to be
/// **1080i50** — interlaced, which the decoder bob-deinterlaces into 50
/// progressive frames/s. So the box memcpys ~2.3 MB of NV12 out of the codec 50
/// times a second and uploads the same again as GL textures, on DDR3 with a
/// Mali-450. The decode is fine — the RK3328 VPU handles 1080p60; the
/// copy-and-upload path is what runs out of budget.
///
/// These props make each frame as cheap as possible to DRAW. They cannot make
/// the box keep up on their own — only fewer frames can do that, and only the
/// encoder can send fewer frames.
const Map<String, String> kStbLowPowerProps = {
  // THE slow-motion fix. mpv's default (`vo`) only drops at the video output,
  // so a box that cannot keep up renders every frame late and playback drifts
  // steadily behind the audio clock — which is what "slow motion" looks like.
  // `decoder+vo` lets it discard frames early and stay on the clock.
  'framedrop': 'decoder+vo',

  // Cheapest scalers and no post-processing: mpv's `vo=gpu` defaults are tuned
  // for desktop GPUs. This is the same set as mpv's own `profile=fast`, spelled
  // out because profiles cannot be applied through mpv_set_property_string.
  'scale': 'bilinear',
  'dscale': 'bilinear',
  'cscale': 'bilinear',
  'dither': 'no',
  'deband': 'no',
  'correct-downscaling': 'no',
  'sigmoid-upscaling': 'no',
  'hdr-compute-peak': 'no',

  // `gpu-dumb-mode` history — keep it forced; it matches the last known-good
  // build. But its exact role is UNPROVEN:
  //
  // * 0.0.7+8 forced `yes`. The X88pro10 played (slow motion, occasional
  //   green, but frames flowed — last confirmed-good build on that box).
  // * 0.0.8+9 removed it → box failed to start (circling → "Playback failed").
  //   At the time that failure was attributed to this flag's removal.
  // * 0.0.9+10 restored it and the box still failed to start — which briefly
  //   made this flag look innocent. It was: bisection ran to the end
  //   (0.0.11+12 removed the startup-attached second mpv client, leaving mpv
  //   startup a strict subset of 0.0.7+8) and the box STILL failed, with
  //   `last mpv error: null` and no data arriving. The startup failures were
  //   ENVIRONMENT, not this app — from 0.0.13+14 onward the box starts
  //   reliably (first progress ~2s). So the original 0.0.8+9 attribution was
  //   never actually tested cleanly. Keep the flag forced: it matches the
  //   last configuration proven to play, and nothing since has argued
  //   against it.
  //
  // Init-window green in the channel player is handled by the black shield
  // (`_blankUntilFirstFrame`), not by this flag.
  'gpu-dumb-mode': 'yes',
};

/// Applies [kStbNetworkProps] plus, on the legacy boxes, [kStbLowPowerProps].
///
/// media_kit's `setProperty` calls `mpv_set_property_string` and throws the
/// return code away, so a name mpv does not know fails silently. When [verify]
/// is set every property is read back and the result logged — a field logcat
/// then says exactly which knobs took and which were ignored. Pass
/// `verify: false` for short-lived players where the log noise isn't worth it.
///
/// Set [network] to false for local assets, where the network props are inert.
Future<void> applyStbMpvTuning(
  Player player,
  StbDecodeProfile profile, {
  bool network = true,
  bool verify = true,
}) async {
  final platform = player.platform;
  if (platform is! NativePlayer) return;

  final props = <String, String>{
    if (network) ...kStbNetworkProps,
    if (profile.lowPower) ...kStbLowPowerProps,
  };
  if (props.isEmpty) return;

  for (final entry in props.entries) {
    await platform.setProperty(entry.key, entry.value);
  }
  if (!verify) return;

  final applied = <String>[];
  final unknown = <String>[];
  for (final entry in props.entries) {
    final actual = await platform.getProperty(entry.key);
    if (actual.isEmpty) {
      unknown.add(entry.key);
    } else {
      applied.add('${entry.key}=$actual');
    }
  }
  logger.i('[STB] mpv tuning applied — ${applied.join(' ')}');
  if (unknown.isNotEmpty) {
    logger.w('[STB] mpv does not know these properties, so they had NO '
        'effect: ${unknown.join(', ')}');
  }
}

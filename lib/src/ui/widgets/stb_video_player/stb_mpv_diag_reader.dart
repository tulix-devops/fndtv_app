import 'dart:async';
import 'dart:ffi' as ffi;

import 'package:app_logger/app_logger.dart';
import 'package:ffi/ffi.dart';
import 'package:media_kit/generated/libmpv/bindings.dart' as g;

/// Non-blocking mpv property reader for the STB player's diagnostics.
///
/// **Why this exists.** media_kit's `getProperty` is a synchronous
/// `mpv_get_property_string` FFI call on the UI isolate. Property access is
/// served between playloop iterations, so when the core wedges — a stalled
/// network demuxer being the everyday case on these boxes — a single read can
/// block the UI thread for up to our `network-timeout` (10s). No await or
/// timeout helps: the isolate is gone until the call returns. In the field
/// that surfaced as Android's "Waiting to send key … unprocessed events"
/// input-dispatcher warning on the X88pro10, and on the TV emulator it
/// escalated to a full ANR (signal 3, process killed) when the stream stalled
/// mid-test. Pacing the reads cannot fix this; the burst was never the
/// problem — the blocking call was.
///
/// **How it avoids all of that.** libmpv's client API is built for exactly
/// this: [create] attaches a *second client handle* to the running core
/// (`mpv_create_client`), and every read goes through
/// `mpv_get_property_async`, which only enqueues a request and returns.
/// Replies are collected by [drain] via `mpv_wait_event(timeout: 0)`, which
/// reads this client's own event queue and never touches the core lock.
/// Nothing in this class can block, no matter how wedged playback is — a
/// wedged core simply means replies arrive late and [read] resolves null on
/// its timeout, which is itself a useful signal (dashes on the diag chip ==
/// the core is not answering).
///
/// **Lifecycle contract.** [dispose] MUST be called before the owning
/// `Player.dispose()`: destroying our client first means core teardown never
/// waits on us and we never touch a dead core. The core can also shut down
/// first (it sends `MPV_EVENT_SHUTDOWN`), which [drain] answers by destroying
/// the handle immediately — mpv blocks core destruction until clients do
/// this, so the drain timer must keep running for the player's lifetime.
class StbMpvDiagReader {
  StbMpvDiagReader._(this._mpv, this._handle);

  final g.MPV _mpv;
  final ffi.Pointer<g.mpv_handle> _handle;

  bool _destroyed = false;
  int _nextId = 1;
  final Map<int, Completer<String?>> _pending = {};

  /// Attaches a diagnostics client to the core at [coreHandleAddress]
  /// (`player.handle`). Returns null if libmpv cannot be reached — callers
  /// degrade to "no runtime diagnostics", never to an error.
  static StbMpvDiagReader? create(int coreHandleAddress) {
    try {
      // The library is already loaded by media_kit; on Android this resolves
      // to the same libmpv.so image, no second copy.
      final mpv = g.MPV(ffi.DynamicLibrary.open('libmpv.so'));
      final core = ffi.Pointer<g.mpv_handle>.fromAddress(coreHandleAddress);
      final name = 'fndtv-diag'.toNativeUtf8();
      final handle = mpv.mpv_create_client(core, name.cast<ffi.Int8>());
      calloc.free(name);
      if (handle == ffi.nullptr) {
        logger.w('[STB] mpv_create_client returned null — '
            'runtime decode diagnostics disabled');
        return null;
      }
      return StbMpvDiagReader._(mpv, handle);
    } catch (e) {
      logger.w('[STB] async mpv reader unavailable: $e');
      return null;
    }
  }

  /// Enqueues an async read of [property]; resolves when [drain] collects the
  /// reply, or with null after [timeout] (core not answering) or on any error.
  Future<String?> read(
    String property, {
    Duration timeout = const Duration(seconds: 2),
  }) {
    if (_destroyed) return Future.value(null);
    final id = _nextId++;
    final completer = Completer<String?>();
    _pending[id] = completer;

    final name = property.toNativeUtf8();
    final err = _mpv.mpv_get_property_async(
      _handle,
      id,
      name.cast<ffi.Int8>(),
      g.mpv_format.MPV_FORMAT_STRING,
    );
    calloc.free(name);
    if (err < 0) {
      _pending.remove(id);
      return Future.value(null);
    }

    return completer.future.timeout(timeout, onTimeout: () {
      _pending.remove(id);
      return null;
    });
  }

  /// Enqueues an async write of [property] (never blocks — same contract as
  /// [read]). Fire-and-forget: success is silent, and a rejected name/value
  /// surfaces via the `MPV_EVENT_SET_PROPERTY_REPLY` error logged by [drain],
  /// so a field logcat shows whether the write actually took.
  void set(String property, String value) {
    if (_destroyed) return;
    final name = property.toNativeUtf8();
    // For MPV_FORMAT_STRING the data argument is a char** — a pointer to the
    // C string pointer.
    final str = value.toNativeUtf8();
    final holder = calloc<ffi.Pointer<Utf8>>();
    holder.value = str;
    final err = _mpv.mpv_set_property_async(
      _handle,
      _setReplyUserdata,
      name.cast<ffi.Int8>(),
      g.mpv_format.MPV_FORMAT_STRING,
      holder.cast<ffi.Void>(),
    );
    // libmpv copies the value during the call — safe to free immediately.
    calloc.free(holder);
    calloc.free(str);
    calloc.free(name);
    if (err < 0) {
      logger.w('[STB] async set $property=$value rejected at enqueue ($err)');
    }
  }

  /// reply_userdata tag for [set] requests, so [drain] can tell them apart
  /// from reads (read ids start at 1 and only grow).
  static const int _setReplyUserdata = 0;

  /// Collects pending replies. Non-blocking (`timeout: 0` reads only this
  /// client's queue); call from a periodic timer. Iterations are capped so a
  /// flood can never own the frame.
  void drain() {
    if (_destroyed) return;
    for (var i = 0; i < 64; i++) {
      final event = _mpv.mpv_wait_event(_handle, 0);
      final eventId = event.ref.event_id;
      if (eventId == g.mpv_event_id.MPV_EVENT_NONE) return;
      if (eventId == g.mpv_event_id.MPV_EVENT_SHUTDOWN) {
        // Core is going down and waits for us — answer immediately.
        _destroyNow();
        return;
      }
      if (eventId == g.mpv_event_id.MPV_EVENT_SET_PROPERTY_REPLY) {
        if (event.ref.error < 0) {
          logger.w('[STB] async property write failed '
              '(mpv error ${event.ref.error})');
        }
        continue;
      }
      if (eventId == g.mpv_event_id.MPV_EVENT_GET_PROPERTY_REPLY) {
        final completer = _pending.remove(event.ref.reply_userdata);
        if (completer == null || completer.isCompleted) continue;
        String? value;
        var format = g.mpv_format.MPV_FORMAT_NONE;
        var name = '?';
        if (event.ref.data != ffi.nullptr) {
          final prop = event.ref.data.cast<g.mpv_event_property>();
          format = prop.ref.format;
          if (prop.ref.name != ffi.nullptr) {
            name = prop.ref.name.cast<Utf8>().toDartString();
          }
          if (event.ref.error >= 0 &&
              format == g.mpv_format.MPV_FORMAT_STRING) {
            final str = prop.ref.data.cast<ffi.Pointer<Utf8>>().value;
            if (str != ffi.nullptr) value = str.toDartString();
          }
        }
        if (value == null) {
          // Field-debuggable: which property, which mpv error, which format.
          logger.d('[STB] diag read "$name" unresolved '
              '(error=${event.ref.error} format=$format)');
        }
        completer.complete(value);
      }
    }
  }

  /// Detaches from the core. Must run before the owning player's dispose.
  void dispose() => _destroyNow();

  void _destroyNow() {
    if (_destroyed) return;
    _destroyed = true;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.complete(null);
    }
    _pending.clear();
    _mpv.mpv_destroy(_handle);
  }
}

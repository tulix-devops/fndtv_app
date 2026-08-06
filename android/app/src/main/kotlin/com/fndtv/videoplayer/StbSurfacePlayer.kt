package com.fndtv.videoplayer

import android.content.Context
import android.media.MediaPlayer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.analytics.AnalyticsListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlin.math.roundToInt

/**
 * Video playback into a REAL Android [SurfaceView], exposed to Flutter as a
 * platform view.
 *
 * **Why this exists.** Every Flutter video engine we tried — media_kit/mpv,
 * `video_player`, flutter_vlc_player — renders into a Flutter SurfaceTexture. On
 * the legacy RK3328 boxes (Android 11, `OMX.rk.video_decoder.avc`) that forces
 * mpv onto `mediacodec-copy`, where every decoded frame costs a ~2.3 MB memcpy
 * out of MediaCodec plus a GL upload — paid whether or not the frame is shown.
 * The feed is 1080i50, bob-deinterlaced by the Rockchip IEP into 50 fps, so the
 * box pays that 50x/second to carry 25 frames of information and runs ~20% short
 * of realtime. On a real SurfaceView the decoder writes into a buffer
 * SurfaceFlinger scans out directly: no copy, no upload, dropped frames free.
 *
 * **Engine order is MediaPlayer first, and that is load-bearing.** A separate
 * native Android app (Desktop/FNDTV/IPTVPlayer) plays these exact channels well
 * on the exact boxes QA tests, confirmed by QA. Its entire video stack is
 * `android.widget.VideoView` — i.e. [MediaPlayer] on a [SurfaceView] — with no
 * ExoPlayer, no Media3 and no libVLC anywhere in its dependencies. Meanwhile
 * ExoPlayer, on the same hardware, accepts the interlaced Europe feeds and then
 * sits in STATE_BUFFERING forever without ever emitting a frame or raising an
 * error (QA, 0.0.8+9: red spinner, no picture, no error). So the platform player
 * is the KNOWN-GOOD path here and goes first; ExoPlayer stays as a secondary for
 * streams whose HLS the platform parser cannot handle.
 *
 * **Anamorphic correction is mandatory.** MediaPlayer reports coded frame size
 * and does NOT expose the bitstream's sample-aspect-ratio, so a 1440x1080
 * anamorphic Europe feed measures as 4:3 and renders visibly squashed unless the
 * display aspect is corrected by hand. The reference app does exactly this, and
 * it is why [displayAspectFor] exists. ExoPlayer does parse SAR, so on that
 * engine we use its `pixelWidthHeightRatio` instead of guessing.
 */
private const val TAG = "StbSurfacePlayer"

private const val ENGINE_MEDIAPLAYER = "mediaplayer"
private const val ENGINE_EXOPLAYER = "exoplayer"

class StbSurfacePlayerFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?> ?: emptyMap()
        return StbSurfacePlayerView(context, messenger, viewId, params)
    }

    companion object {
        const val VIEW_TYPE = "com.fndtv.videoplayer/surface_player"
    }
}

/** Engine-agnostic contract so MediaPlayer and ExoPlayer are interchangeable. */
private interface PlaybackEngine {
    val name: String
    fun open(url: String, autoplay: Boolean)
    fun play()
    fun pause()
    fun seekTo(ms: Long)
    fun positionMs(): Long
    fun durationMs(): Long
    fun droppedFrames(): Int
    fun release()
}

/**
 * Letterboxes its child to [displayAspect] instead of stretching it to the
 * platform view's bounds. Without this an anamorphic 1440x1080 stream fills a
 * 16:9 surface as 4:3 and everyone looks tall and thin.
 */
private class AspectFrameLayout(context: Context) : FrameLayout(context) {
    /** Display aspect (w/h) AFTER pixel-aspect correction. 0 = unknown, fill. */
    var displayAspect: Float = 0f
        set(value) {
            if (field != value) {
                field = value
                requestLayout()
            }
        }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        val availW = MeasureSpec.getSize(widthMeasureSpec)
        val availH = MeasureSpec.getSize(heightMeasureSpec)
        if (displayAspect <= 0f || availW == 0 || availH == 0) return

        var w = availW
        var h = (w / displayAspect).roundToInt()
        if (h > availH) {
            h = availH
            w = (h * displayAspect).roundToInt()
        }
        for (i in 0 until childCount) {
            getChildAt(i).measure(
                MeasureSpec.makeMeasureSpec(w, MeasureSpec.EXACTLY),
                MeasureSpec.makeMeasureSpec(h, MeasureSpec.EXACTLY),
            )
        }
    }
}

class StbSurfacePlayerView(
    private val context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    params: Map<String, Any?>,
) : PlatformView, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val surfaceView = SurfaceView(context)
    private val container = AspectFrameLayout(context).apply {
        addView(
            surfaceView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
                Gravity.CENTER,
            ),
        )
    }

    private val methodChannel =
        MethodChannel(messenger, "${StbSurfacePlayerFactory.VIEW_TYPE}/$viewId")
    private val eventChannel =
        EventChannel(messenger, "${StbSurfacePlayerFactory.VIEW_TYPE}/$viewId/events")

    private val main = Handler(Looper.getMainLooper())
    private var events: EventChannel.EventSink? = null
    private var engine: PlaybackEngine? = null

    /**
     * Platform player first — see the class doc. Order is the whole point.
     */
    private val engineOrder = listOf(ENGINE_MEDIAPLAYER, ENGINE_EXOPLAYER)
    private var engineIndex = 0

    private var surfaceReady = false
    private var pendingUrl: String? = null
    private var pendingAutoplay = true

    private var firstFrameSeen = false
    private var firstFrameWatchdog: Runnable? = null
    private var currentUrl: String = ""
    private var currentAutoplay = true

    private var statsTimer: Runnable? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)

        surfaceView.holder.addCallback(object : SurfaceHolder.Callback {
            override fun surfaceCreated(holder: SurfaceHolder) {
                surfaceReady = true
                pendingUrl?.let { url ->
                    pendingUrl = null
                    startEngine(url, pendingAutoplay)
                }
            }

            override fun surfaceChanged(h: SurfaceHolder, f: Int, w: Int, ht: Int) = Unit

            override fun surfaceDestroyed(holder: SurfaceHolder) {
                surfaceReady = false
            }
        })

        (params["url"] as? String)?.let { url ->
            openInternal(url, params["autoplay"] as? Boolean ?: true)
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        stopStats()
        cancelFirstFrameWatchdog()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        engine?.release()
        engine = null
        events = null
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "open" -> {
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) {
                    result.error("bad_args", "url is required", null)
                } else {
                    engineIndex = 0
                    openInternal(url, call.argument<Boolean>("autoplay") ?: true)
                    result.success(null)
                }
            }
            "play" -> { engine?.play(); result.success(null) }
            "pause" -> { engine?.pause(); result.success(null) }
            "seekTo" -> {
                val ms = (call.argument<Number>("positionMs") ?: 0).toLong()
                engine?.seekTo(ms)
                result.success(null)
            }
            "position" -> result.success(engine?.positionMs() ?: 0L)
            else -> result.notImplemented()
        }
    }

    private fun openInternal(url: String, autoplay: Boolean) {
        engine?.release()
        engine = null
        if (!surfaceReady) {
            pendingUrl = url
            pendingAutoplay = autoplay
            return
        }
        startEngine(url, autoplay)
    }

    private fun startEngine(url: String, autoplay: Boolean) {
        val name = engineOrder.getOrNull(engineIndex) ?: ENGINE_MEDIAPLAYER
        val next = when (name) {
            ENGINE_EXOPLAYER -> ExoPlayerEngine()
            else -> MediaPlayerEngine()
        }
        engine = next
        currentUrl = url
        currentAutoplay = autoplay
        firstFrameSeen = false
        Log.i(TAG, "engine=${next.name} opening $url")
        send(mapOf("event" to "engine", "name" to next.name))
        next.open(url, autoplay)
        armFirstFrameWatchdog(next.name)
        startStats()
    }

    /**
     * Moves to the next engine, or reports the stream unplayable if none is
     * left. Dart turns "unplayable" into a hand-off to the mpv path rather than
     * a dead channel.
     */
    private fun advanceEngine(why: String) {
        cancelFirstFrameWatchdog()
        if (engineIndex + 1 >= engineOrder.size) {
            Log.e(TAG, "all engines exhausted ($why)")
            send(
                mapOf(
                    "event" to "error",
                    "message" to "No engine could start this stream ($why)",
                    "code" to "NO_ENGINE",
                ),
            )
            return
        }
        engineIndex++
        Log.w(TAG, "engine ${engine?.name} failed ($why) — trying ${engineOrder[engineIndex]}")
        send(mapOf("event" to "buffering", "value" to true))
        engine?.release()
        engine = null
        main.post { startEngine(currentUrl, currentAutoplay) }
    }

    /**
     * Falls the engine forward if no picture ever arrives.
     *
     * A pipeline that fails by going QUIET is the case this catches: on these
     * boxes ExoPlayer accepts the interlaced feeds, queues input, and never
     * produces an output frame or an error, so no listener ever fires. Only
     * elapsed time detects that. Healthy channels start in ~2s here.
     */
    private fun armFirstFrameWatchdog(engineName: String) {
        cancelFirstFrameWatchdog()
        val timeoutMs =
            if (engineName == ENGINE_MEDIAPLAYER) MP_FIRST_FRAME_MS else EXO_FIRST_FRAME_MS
        val task = Runnable {
            if (firstFrameSeen) return@Runnable
            advanceEngine("no first frame in ${timeoutMs}ms on $engineName")
        }
        firstFrameWatchdog = task
        main.postDelayed(task, timeoutMs)
    }

    private fun cancelFirstFrameWatchdog() {
        firstFrameWatchdog?.let { main.removeCallbacks(it) }
        firstFrameWatchdog = null
    }

    private fun noteFirstFrame() {
        if (firstFrameSeen) return
        firstFrameSeen = true
        cancelFirstFrameWatchdog()
        Log.i(TAG, "first frame on ${engine?.name}")
        send(mapOf("event" to "firstFrame"))
    }

    /**
     * Display aspect for a coded frame, correcting for anamorphic pixels.
     *
     * [par] is the sample aspect ratio when the engine knows it (ExoPlayer does);
     * pass 0 when it does not (MediaPlayer), and the anamorphic HD convention is
     * applied — those streams carry 4:3 pixels and are meant to display 16:9.
     * ffprobe on the live feed: `1440x1080 [SAR 4:3 DAR 16:9]`.
     *
     * **Match a HEIGHT RANGE, not 1080 exactly.** The reference app can test
     * `height == 1080` because it runs on whatever its decoder reports, but this
     * stream is coded **1440x1088 with crop bottom 2** (verified by parsing its
     * SPS), and the 2020-era Rockchip OMX component reports the 16-aligned coded
     * height rather than the cropped display height. An exact 1080 test then
     * silently does nothing on exactly the hardware that needs it — which is why
     * 0.0.10+11 still rendered the Europe channels squashed on the X88pro10
     * while the Android 14 box (on mpv, which reads SAR itself) was correct.
     *
     * Returns 16:9 outright rather than `ratio * 4/3`, so the answer does not
     * drift with whichever height the decoder reports.
     */
    private fun displayAspectFor(width: Int, height: Int, par: Float): Float {
        if (width <= 0 || height <= 0) return 0f
        if (par > 0f) return (width.toFloat() / height) * par
        if (width == 1440 && height in 1080..1088) return 16f / 9f
        return width.toFloat() / height
    }

    private fun applyVideoSize(width: Int, height: Int, par: Float) {
        val aspect = displayAspectFor(width, height, par)
        main.post { container.displayAspect = aspect }
        Log.i(TAG, "video ${width}x$height par=$par -> displayAspect=$aspect")
        send(
            mapOf(
                "event" to "size",
                "width" to width,
                "height" to height,
                "displayAspect" to aspect,
            ),
        )
    }

    /**
     * Maps Dart's `asset:///assets/video/x.ts` onto the path it actually has
     * inside the APK, or null for an ordinary network URL.
     *
     * Flutter packages its bundle under `flutter_assets/`, so the pubspec key
     * `assets/video/bootanimation.ts` lives at
     * `flutter_assets/assets/video/bootanimation.ts`. Both engines need this:
     * ExoPlayer takes `asset:///<path>`, MediaPlayer needs the file descriptor.
     *
     * The `.ts` extension must also be excluded from APK compression
     * (`androidResources.noCompress` in build.gradle.kts) or `openFd` throws —
     * a compressed asset has no seekable descriptor.
     */
    private fun flutterAssetPath(url: String): String? =
        if (url.startsWith("asset:///")) {
            "flutter_assets/" + url.removePrefix("asset:///")
        } else {
            null
        }

    private fun send(payload: Map<String, Any?>) {
        main.post { events?.success(payload) }
    }

    /** Periodic stats so a QA logcat carries the verdict with no button presses. */
    private fun startStats() {
        stopStats()
        val task = object : Runnable {
            override fun run() {
                val e = engine ?: return
                Log.i(
                    TAG,
                    "perf engine=${e.name} pos=${e.positionMs()}ms " +
                        "dur=${e.durationMs()}ms droppedFrames=${e.droppedFrames()}",
                )
                send(
                    mapOf(
                        "event" to "stats",
                        "positionMs" to e.positionMs(),
                        "durationMs" to e.durationMs(),
                        "droppedFrames" to e.droppedFrames(),
                    ),
                )
                main.postDelayed(this, STATS_INTERVAL_MS)
            }
        }
        statsTimer = task
        main.postDelayed(task, STATS_INTERVAL_MS)
    }

    private fun stopStats() {
        statsTimer?.let { main.removeCallbacks(it) }
        statsTimer = null
    }

    // ---------------------------------------------------------------- engines

    /**
     * The platform player, and the primary path on these boxes — a separate
     * native app using exactly this (via `VideoView`) plays the same channels
     * well on the same hardware.
     */
    private inner class MediaPlayerEngine : PlaybackEngine {
        override val name = ENGINE_MEDIAPLAYER
        private var player: MediaPlayer? = null

        override fun open(url: String, autoplay: Boolean) {
            val p = MediaPlayer()
            player = p
            p.setDisplay(surfaceView.holder)
            p.setOnPreparedListener { mp ->
                // Matches the reference app; without it the platform decides
                // scaling itself and can crop.
                mp.setVideoScalingMode(MediaPlayer.VIDEO_SCALING_MODE_SCALE_TO_FIT)
                // par=0: MediaPlayer cannot report SAR, so the anamorphic
                // convention is applied in displayAspectFor.
                applyVideoSize(mp.videoWidth, mp.videoHeight, 0f)
                mp.setOnVideoSizeChangedListener { _, w, h -> applyVideoSize(w, h, 0f) }
                send(mapOf("event" to "buffering", "value" to false))
                send(mapOf("event" to "initialized", "durationMs" to durationMs()))
                if (autoplay) {
                    mp.start()
                    send(mapOf("event" to "playing", "value" to true))
                }
            }
            p.setOnInfoListener { _, what, _ ->
                when (what) {
                    MediaPlayer.MEDIA_INFO_VIDEO_RENDERING_START -> noteFirstFrame()
                    MediaPlayer.MEDIA_INFO_BUFFERING_START ->
                        send(mapOf("event" to "buffering", "value" to true))
                    MediaPlayer.MEDIA_INFO_BUFFERING_END ->
                        send(mapOf("event" to "buffering", "value" to false))
                }
                false
            }
            p.setOnCompletionListener { send(mapOf("event" to "completed")) }
            p.setOnErrorListener { _, what, extra ->
                Log.e(TAG, "MediaPlayer error what=$what extra=$extra")
                if (!firstFrameSeen) {
                    advanceEngine("MediaPlayer error $what/$extra")
                } else {
                    send(
                        mapOf(
                            "event" to "error",
                            "message" to "MediaPlayer error $what/$extra",
                            "code" to "MEDIAPLAYER_$what",
                        ),
                    )
                }
                true
            }
            send(mapOf("event" to "buffering", "value" to true))
            val assetPath = flutterAssetPath(url)
            if (assetPath != null) {
                // MediaPlayer cannot take an asset:// URI — it needs the fd.
                context.assets.openFd(assetPath).use { afd ->
                    p.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                }
            } else {
                p.setDataSource(url)
            }
            p.prepareAsync()
        }

        override fun play() { player?.start() }
        override fun pause() { if (player?.isPlaying == true) player?.pause() }
        override fun seekTo(ms: Long) { player?.seekTo(ms.toInt()) }
        override fun positionMs() = try {
            player?.currentPosition?.toLong() ?: 0L
        } catch (_: IllegalStateException) { 0L }
        override fun durationMs() = try {
            val d = player?.duration ?: 0
            if (d < 0) 0L else d.toLong()
        } catch (_: IllegalStateException) { 0L }

        /** MediaPlayer exposes no drop counter — reported as -1 ("unknown"). */
        override fun droppedFrames() = -1

        override fun release() {
            try {
                player?.reset()
                player?.release()
            } catch (_: Throwable) {
            }
            player = null
        }
    }

    /**
     * Secondary engine. Better HLS handling than the platform parser, and it
     * knows the bitstream SAR — but it is the one that wedges on the interlaced
     * feeds, so it is not tried first.
     */
    @OptIn(UnstableApi::class)
    private inner class ExoPlayerEngine : PlaybackEngine {
        override val name = ENGINE_EXOPLAYER
        private var player: ExoPlayer? = null
        private var dropped = 0

        override fun open(url: String, autoplay: Boolean) {
            val p = ExoPlayer.Builder(context).build()
            player = p
            p.setVideoSurfaceView(surfaceView)
            p.addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(state: Int) {
                    when (state) {
                        Player.STATE_BUFFERING ->
                            send(mapOf("event" to "buffering", "value" to true))
                        Player.STATE_READY -> {
                            send(mapOf("event" to "buffering", "value" to false))
                            send(
                                mapOf(
                                    "event" to "initialized",
                                    "durationMs" to durationMs(),
                                ),
                            )
                        }
                        Player.STATE_ENDED -> send(mapOf("event" to "completed"))
                    }
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    send(mapOf("event" to "playing", "value" to isPlaying))
                }

                override fun onVideoSizeChanged(size: VideoSize) {
                    // ExoPlayer parses SAR from the bitstream, so no guessing.
                    applyVideoSize(size.width, size.height, size.pixelWidthHeightRatio)
                }

                override fun onRenderedFirstFrame() = noteFirstFrame()

                override fun onPlayerError(error: PlaybackException) {
                    Log.e(TAG, "ExoPlayer error ${error.errorCodeName}", error)
                    if (!firstFrameSeen) {
                        advanceEngine("ExoPlayer ${error.errorCodeName}")
                    } else {
                        send(
                            mapOf(
                                "event" to "error",
                                "message" to (error.message ?: error.errorCodeName),
                                "code" to error.errorCodeName,
                            ),
                        )
                    }
                }
            })
            p.addAnalyticsListener(object : AnalyticsListener {
                override fun onDroppedVideoFrames(
                    eventTime: AnalyticsListener.EventTime,
                    droppedFrames: Int,
                    elapsedMs: Long,
                ) {
                    dropped += droppedFrames
                }
            })
            val assetPath = flutterAssetPath(url)
            val uri = if (assetPath != null) "asset:///$assetPath" else url
            p.setMediaItem(MediaItem.fromUri(uri))
            p.playWhenReady = autoplay
            p.prepare()
        }

        override fun play() { player?.play() }
        override fun pause() { player?.pause() }
        override fun seekTo(ms: Long) { player?.seekTo(ms) }
        override fun positionMs() = player?.currentPosition ?: 0L
        override fun durationMs(): Long {
            val d = player?.duration ?: 0L
            return if (d == C.TIME_UNSET) 0L else d
        }
        override fun droppedFrames() = dropped
        override fun release() {
            player?.release()
            player = null
        }
    }

    private companion object {
        const val STATS_INTERVAL_MS = 30_000L

        /** Known-good path — give the platform parser room to commit. */
        const val MP_FIRST_FRAME_MS = 15_000L

        /** Secondary; if it has not drawn by now it is the wedge case. */
        const val EXO_FIRST_FRAME_MS = 12_000L
    }
}

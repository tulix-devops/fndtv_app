import 'package:app_localization/app_localization.dart';
import 'package:app_logger/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:local_storage/local_storage.dart';
import 'package:ui_kit/ui_kit.dart';

/// Per-box picture-size calibration for the STB player.
///
/// **Why this exists.** These boxes drive TVs that overscan — the panel crops a
/// few percent off every edge, so the video's edges (and the FNDTV watermark)
/// fall outside the visible area. The box firmware ships its own screen-size
/// utility for exactly this, but in kiosk mode subscribers cannot reach system
/// settings, so the player carries its own.
///
/// Scoped to the PLAYER on purpose: it scales the video, not the whole UI, so a
/// mis-set value can never make the menus unreachable.
@immutable
class StbScreenSize {
  const StbScreenSize({this.width = 1.0, this.height = 1.0});

  /// Horizontal scale, 1.0 = fill the player.
  final double width;

  /// Vertical scale, 1.0 = fill the player.
  final double height;

  /// Shrink-only, and that is a safety decision.
  ///
  /// This scales the WHOLE application, not just the video. Anything above 1.0
  /// would push content past the panel edge — and on a kiosk box the first
  /// casualty is the nav rail, which is how a viewer would lose the ability to
  /// reach these settings and undo it. Capping at 1.0 makes that impossible.
  ///
  /// Nothing is lost by it: overscan compensation only ever wants to shrink
  /// content into the visible area. The opposite case (a TV that underscans and
  /// shows black borders) cannot be fixed from inside the app anyway — growing
  /// our content just clips it against the same framebuffer.
  static const double min = 0.70;
  static const double max = 1.00;

  /// One D-pad press. 1% is fine enough to land on a TV's exact visible area
  /// without the adjustment feeling sluggish.
  static const double step = 0.01;

  static const StbScreenSize identity = StbScreenSize();

  bool get isIdentity => width == 1.0 && height == 1.0;

  int get widthPercent => (width * 100).round();
  int get heightPercent => (height * 100).round();

  StbScreenSize copyWith({double? width, double? height}) => StbScreenSize(
        width: (width ?? this.width).clamp(min, max),
        height: (height ?? this.height).clamp(min, max),
      );

  StbScreenSize nudgeWidth(double delta) => copyWith(width: width + delta);
  StbScreenSize nudgeHeight(double delta) => copyWith(height: height + delta);

  @override
  bool operator ==(Object other) =>
      other is StbScreenSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Reads/writes [StbScreenSize]. One setting for the whole box — a viewer
/// calibrates their TV once, not per channel.
class StbScreenSizeStore {
  StbScreenSizeStore(this._storage);

  final LocalStorage _storage;

  static const String _kWidth = 'stb_screen_width';
  static const String _kHeight = 'stb_screen_height';

  Future<StbScreenSize> load() async {
    try {
      final w = double.tryParse(await _storage.get<String>(_kWidth) ?? '');
      final h = double.tryParse(await _storage.get<String>(_kHeight) ?? '');
      if (w == null && h == null) return StbScreenSize.identity;
      return StbScreenSize(
        width: (w ?? 1.0).clamp(StbScreenSize.min, StbScreenSize.max),
        height: (h ?? 1.0).clamp(StbScreenSize.min, StbScreenSize.max),
      );
    } catch (e) {
      logger.w('[STB] screen size load failed: $e');
      return StbScreenSize.identity;
    }
  }

  Future<void> save(StbScreenSize size) async {
    try {
      await _storage.store<String>(_kWidth, size.width.toString());
      await _storage.store<String>(_kHeight, size.height.toString());
      logger.i('[STB] screen size saved — '
          '${size.widthPercent}% x ${size.heightPercent}%');
    } catch (e) {
      logger.w('[STB] screen size save failed: $e');
    }
  }
}

/// The one live copy of the setting, shared by the app root, the settings page
/// and both players.
///
/// A singleton rather than a provider because it is genuinely one global device
/// preference — the same reasoning as `StbSystemService.isStb` — and because the
/// app root has to read it from inside `MaterialApp.builder`, above the point
/// where route-level providers exist.
///
/// [preview] changes the value WITHOUT persisting, so adjusting rescales the
/// whole UI immediately and Back can restore the saved value; [save] commits.
class StbScreenSizeController extends ValueNotifier<StbScreenSize> {
  StbScreenSizeController._() : super(StbScreenSize.identity);

  static final StbScreenSizeController instance = StbScreenSizeController._();

  StbScreenSizeStore? _store;

  /// Last persisted value — what [preview] changes are measured against.
  StbScreenSize saved = StbScreenSize.identity;

  /// Called once at startup, after LocalStorage is ready.
  Future<void> load(LocalStorage storage) async {
    final store = StbScreenSizeStore(storage);
    _store = store;
    final loaded = await store.load();
    saved = loaded;
    value = loaded;
  }

  /// Live, unsaved change.
  void preview(StbScreenSize size) => value = size;

  Future<void> save(StbScreenSize size) async {
    saved = size;
    value = size;
    await _store?.save(size);
  }

  /// Discards an in-progress adjustment.
  void revert() => value = saved;
}

/// Applies a [StbScreenSize] to whatever it wraps.
///
/// **A visual scale, NOT a smaller layout box.** The child is laid out against
/// the FULL screen and then drawn smaller, so every pixel of UI still exists —
/// it is just rendered inside the panel's visible area.
///
/// This was originally a `FractionallySizedBox`, and that was wrong. Measuring
/// the child at a fraction of the screen tells the app the display is shorter
/// than it is: widgets keep their natural size, there is simply less room, and
/// whatever sits last gets pushed off. QA hit exactly that — at reduced height
/// the nav rail's bottom entry ("Réglages") became unreachable-looking, focusable
/// but with nowhere to draw. Scaling instead of shrinking removes the problem at
/// source: the rail always has a full-height canvas, so nothing overflows and
/// nothing needs to scroll.
///
/// `transformHitTests` is on by default, so focus and taps land where the
/// content is drawn rather than where it would have been unscaled.
class StbScreenSizeScaler extends StatelessWidget {
  const StbScreenSizeScaler({
    super.key,
    required this.size,
    required this.child,
  });

  final StbScreenSize size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (size.isIdentity) return child;
    return Transform.scale(
      scaleX: size.width,
      scaleY: size.height,
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// The calibration panel. Shared by the settings page and the in-player ↓
/// overlay so the two cannot drift apart visually.
///
/// Reads as FNDTV rather than as a system dialog: the app's dark surface and
/// brand accent, its section-header rule, and Urbanist throughout. The two
/// values are separate blocks because they are adjusted by different keys —
/// tying each number to its axis is what makes the D-pad map self-evident
/// without reading the hint line.
class StbScreenSizePanel extends StatelessWidget {
  const StbScreenSizePanel({
    super.key,
    required this.size,
    this.savedSize,
  });

  final StbScreenSize size;

  /// When it differs from [size], the last saved value is shown so a viewer
  /// mid-adjustment can see what Back would restore.
  final StbScreenSize? savedSize;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final accent = context.uiColors.primary;
    final dirty = savedSize != null && savedSize != size;

    return Container(
      width: 620,
      padding: const EdgeInsets.fromLTRB(36, 30, 36, 28),
      decoration: BoxDecoration(
        color: const Color(0xF21A1C22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 40, spreadRadius: 4),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section header, matching the red rule used across the app.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 26,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                l.settingsScreenSizeTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _ValueBlock(
                  label: l.settingsScreenSizeWidth,
                  percent: size.widthPercent,
                  accent: accent,
                  // ←/→ drive width, and the block is tinted to say so.
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ValueBlock(
                  label: l.settingsScreenSizeHeight,
                  percent: size.heightPercent,
                  accent: accent,
                  highlighted: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _DpadDiagram(accent: accent),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionPill(
                keyLabel: 'OK',
                action: l.settingsScreenSizeSave,
                background: accent,
                foreground: Colors.white,
              ),
              const SizedBox(width: 14),
              _ActionPill(
                keyLabel: '←',
                action: l.settingsScreenSizeCancel,
                background: Colors.white10,
                foreground: Colors.white70,
              ),
            ],
          ),
          if (dirty) ...[
            const SizedBox(height: 14),
            Text(
              '${l.settingsScreenSizeSaved}: '
              '${savedSize!.widthPercent}% × ${savedSize!.heightPercent}%',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({
    required this.label,
    required this.percent,
    required this.accent,
    required this.highlighted,
  });

  final String label;
  final int percent;
  final Color accent;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: highlighted ? accent.withValues(alpha: 0.16) : Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? accent.withValues(alpha: 0.55) : Colors.white12,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: highlighted ? accent : Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// ←/→ tinted with the accent (width), ↑/↓ plain (height), with the axis named
/// beside each pair.
class _DpadDiagram extends StatelessWidget {
  const _DpadDiagram({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Key(icon: Icons.keyboard_arrow_up_rounded, color: Colors.white24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Key(icon: Icons.chevron_left_rounded, color: accent),
                Container(
                  width: 56,
                  height: 40,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                _Key(icon: Icons.chevron_right_rounded, color: accent),
              ],
            ),
            _Key(
              icon: Icons.keyboard_arrow_down_rounded,
              color: Colors.white24,
            ),
          ],
        ),
        const SizedBox(width: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _AxisLegend(
              glyph: '←  →',
              text: l.settingsScreenSizeAxisWidth,
              color: accent,
            ),
            const SizedBox(height: 8),
            _AxisLegend(
              glyph: '↑  ↓',
              text: l.settingsScreenSizeAxisHeight,
              color: Colors.white54,
            ),
          ],
        ),
      ],
    );
  }
}

class _AxisLegend extends StatelessWidget {
  const _AxisLegend({
    required this.glyph,
    required this.text,
    required this.color,
  });

  final String glyph;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            glyph,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          text,
          style: const TextStyle(color: Colors.white60, fontSize: 15),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tinted = color != Colors.white24;
    return Container(
      width: 48,
      height: 40,
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tinted ? color.withValues(alpha: 0.9) : color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.keyLabel,
    required this.action,
    required this.background,
    required this.foreground,
  });

  final String keyLabel;
  final String action;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              keyLabel,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            action,
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// In-player wrapper — the panel plus visibility.
class StbScreenSizeOverlay extends StatelessWidget {
  const StbScreenSizeOverlay({
    super.key,
    required this.size,
    required this.visible,
    this.savedSize,
  });

  final StbScreenSize size;
  final StbScreenSize? savedSize;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Center(
      child: StbScreenSizePanel(size: size, savedSize: savedSize),
    );
  }
}

/// The calibration target drawn behind the panel on the settings page.
///
/// Corner BRACKETS rather than filled blocks, plus a centre tick on each edge:
/// that is the standard crop-mark language, and it reads as an alignment target
/// instead of decoration. If a bracket's corner is off-screen the panel is
/// cropping there; the edge ticks show whether the cut is even or lopsided.
class StbScreenSizeFrame extends StatelessWidget {
  const StbScreenSizeFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(accent: context.uiColors.primary),
      child: const SizedBox.expand(),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Faint fill so the calibrated region is distinguishable from the black
    // surround even before any bracket reaches an edge.
    canvas.drawRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.03));

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = accent;
    canvas.drawRect(rect.deflate(1.5), border);

    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.square
      ..color = Colors.white;

    const inset = 34.0;
    final arm = size.shortestSide * 0.09;

    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * arm, y), bracket);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * arm), bracket);
    }

    corner(inset, inset, 1, 1);
    corner(size.width - inset, inset, -1, 1);
    corner(inset, size.height - inset, 1, -1);
    corner(size.width - inset, size.height - inset, -1, -1);

    // Centre ticks — reveal an off-centre crop that brackets alone would not.
    final tick = Paint()
      ..strokeWidth = 5
      ..color = Colors.white70;
    final tickLen = size.shortestSide * 0.04;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, tickLen), tick);
    canvas.drawLine(Offset(size.width / 2, size.height),
        Offset(size.width / 2, size.height - tickLen), tick);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(tickLen, size.height / 2), tick);
    canvas.drawLine(Offset(size.width, size.height / 2),
        Offset(size.width - tickLen, size.height / 2), tick);
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => oldDelegate.accent != accent;
}

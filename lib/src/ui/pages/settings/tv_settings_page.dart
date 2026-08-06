import 'package:app_localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fndtv/src/ui/widgets/stb_screen_size/stb_screen_size.dart';
import 'package:ui_kit/ui_kit.dart';

/// Set-top-box settings, reached from the nav rail below Network.
///
/// Deliberately a LIST rather than a single screen: this is the home for box
/// preferences from here on, and adding a row should not mean restructuring
/// anything. Today it holds one entry.
class TvSettingsPage extends StatelessWidget {
  const TvSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0F13),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(48, 32, 48, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.l.navSettings,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SettingsTile(
                autofocus: true,
                icon: Icons.aspect_ratio_rounded,
                title: context.l.settingsScreenSizeTitle,
                subtitle: context.l.settingsScreenSizeSubtitle,
                onSelected: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const TvScreenSizePage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatefulWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSelected,
    this.autofocus = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onSelected;
  final bool autofocus;

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          widget.onSelected();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: _focused ? context.uiColors.primary : Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: _focused ? Colors.white70 : Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white54, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picture-size calibration, previewed on the whole app.
///
/// There is deliberately NO local scaler here. The setting is applied once at
/// the app root (`MaterialApp.builder`), so every arrow press resizes this
/// entire screen — the frame, the panel, and everything behind it. What you see
/// while adjusting is literally what the app will look like, which is the point
/// of calibrating against a TV that crops.
///
/// The frame therefore marks the app's REAL edges: if a corner bracket is off
/// the panel, that is content the TV is cutting.
class TvScreenSizePage extends StatefulWidget {
  const TvScreenSizePage({super.key});

  @override
  State<TvScreenSizePage> createState() => _TvScreenSizePageState();
}

class _TvScreenSizePageState extends State<TvScreenSizePage> {
  final StbScreenSizeController _controller = StbScreenSizeController.instance;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _controller.save(_controller.value);
    if (mounted) Navigator.of(context).maybePop();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final current = _controller.value;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _controller.preview(current.nudgeWidth(-StbScreenSize.step));
      case LogicalKeyboardKey.arrowRight:
        _controller.preview(current.nudgeWidth(StbScreenSize.step));
      case LogicalKeyboardKey.arrowUp:
        _controller.preview(current.nudgeHeight(StbScreenSize.step));
      case LogicalKeyboardKey.arrowDown:
        _controller.preview(current.nudgeHeight(-StbScreenSize.step));
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        _save();
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // Leaving without OK discards the adjustment and snaps the app back to
      // the saved size.
      onPopInvokedWithResult: (didPop, _) => _controller.revert(),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: ValueListenableBuilder<StbScreenSize>(
            valueListenable: _controller,
            builder: (context, size, _) => Stack(
              fit: StackFit.expand,
              children: [
                const StbScreenSizeFrame(),
                Center(
                  child: StbScreenSizePanel(
                    size: size,
                    savedSize: _controller.saved,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

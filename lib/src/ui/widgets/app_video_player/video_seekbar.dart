part of 'app_video_player.dart';

class VideoSeekbar extends StatefulWidget {
  final VideoPlayerController controller;
  final FocusNode? focusNode;
  final bool isEnabled;
  final void Function(String link)? updateController;

  const VideoSeekbar({
    required this.controller,
    super.key,
    this.focusNode,
    required this.updateController,
    this.isEnabled = true,
  });

  @override
  State<VideoSeekbar> createState() => _VideoSeekbarState();
}

class _VideoSeekbarState extends State<VideoSeekbar> {
  double _value = 0.0;

  Duration get _position => widget.controller.value.position;
  Duration? get _duration => widget.controller.value.duration;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => _updateSeekbar());
  }

  void _updateSeekbar() {
    if (!mounted) return;
    final int position = _position.inSeconds;
    final int duration = _duration?.inSeconds ?? 0;
    final double newValue = duration != 0 ? position / duration : 0;
    setState(() {
      _value = duration != 0 ? newValue : 0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.focusNode != null) {
      widget.focusNode!.addListener(() {
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(() => _updateSeekbar());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          thumbShape: widget.isEnabled
              ? CustomThumbShape()
              : SliderComponentShape.noThumb,
          disabledActiveTrackColor: Colors.yellow,
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: MediaQuery(
          data: const MediaQueryData(
            navigationMode: NavigationMode.directional,
          ),
          child: Slider(
            focusNode: widget.focusNode,
            value: _value,
            inactiveColor: Colors.grey,
            min: 0.0,
            max: 1.0,
            onChanged: widget.isEnabled
                ? (newValue) {
                    if (mounted) {
                      setState(() {
                        _value = newValue;
                      });
                    }
                    final newProgress = Duration(
                      milliseconds:
                          (_value * _duration!.inMilliseconds).toInt(),
                    );
                    widget.controller.seekTo(newProgress);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class CustomThumbShape extends SliderComponentShape {
  final double thumbRadius = 6.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final fillPaint = Paint()
      ..color = sliderTheme.thumbColor!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius, fillPaint);
  }
}

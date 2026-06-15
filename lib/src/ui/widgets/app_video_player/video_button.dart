part of 'app_video_player.dart';

class VideoButton extends StatefulWidget {
  final FocusNode focusNode;
  final void Function(BuildContext) onPressed;
  final String icon;
  final String? label;
  final bool useDefaultButtonStyle;
  final ({Color defaultColor, Color focusedColor})? labelColor;
  const VideoButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.focusNode,
    this.label,
    this.labelColor,
    this.useDefaultButtonStyle = false,
  });

  @override
  State<VideoButton> createState() => _VideoButtonState();
}

class _VideoButtonState extends State<VideoButton> {
  @override
  Widget build(BuildContext context) {
    return FocusTextButton(
      label: widget.label,
      labelColor: widget.labelColor,
      backgroundColor: (
        defaultColor: Colors.transparent,
        focusedColor: context.uiColors.secondary
      ),
      iconColor: (
        defaultColor: context.uiColors.onSecondary,
        focusedColor: context.uiColors.primary
      ),
      useDefaultButtonStyle: widget.useDefaultButtonStyle,
      onPressed: widget.onPressed,
      icon: widget.icon,
      focusNode: widget.focusNode,
    );
  }
}

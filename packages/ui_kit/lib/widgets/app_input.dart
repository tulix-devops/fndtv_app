import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:flutter_multi_formatter/formatters/phone_input_formatter.dart';

class AppInput extends StatefulWidget {
  /// On changed callback tipically bloc method for validation
  final ValueChanged<String>? onChanged;

  /// Hint text for input
  final String? hintText;

  /// SVG Icon for input
  final String prefixIcon;

  final TextInputType type;
  final String? value;
  final bool isDisabled;
  final bool isFocused; // for tv borders
  final bool isDeviceTv;
  final FocusNode? focusNode;

  /// onFieldSubmitted is used for form submission if the textInputAction is [TextInputAction.done]
  final ValueChanged<String>? onFieldSubmitted;

  /// [TextInputAction.next] is for moving to the next input field, [TextInputAction.done] is for form submission
  final TextInputAction? textInputAction;

  final String? fieldError;

  /// i don't know if this is correct
  final TextEditingController? controller;

  const AppInput.none({
    super.key,
    required this.prefixIcon,
    this.isDisabled = false,
    this.isFocused = false,
    this.onChanged,
    this.hintText,
    this.controller,
    this.fieldError,
    this.value,
    this.onFieldSubmitted,
    this.textInputAction,
    this.focusNode,
    required this.isDeviceTv,
  }) : type = TextInputType.none;

  const AppInput.text(
      {super.key,
      required this.prefixIcon,
      this.isDisabled = false,
      this.isFocused = false,
      this.onChanged,
      this.hintText,
      this.controller,
      this.fieldError,
      this.value,
      this.onFieldSubmitted,
      this.textInputAction,
      this.focusNode,
      required this.isDeviceTv})
      : type = TextInputType.text;

  // const AppInput.number({
  //   super.key,
  //   required this.prefixIcon,
  //   this.isDisabled = false,
  //   this.onChanged,
  //
  //   this.hintText,
  //   this.controller,
  //   this.isValid,
  //   this.value,
  //   this.onFieldSubmitted,
  //   this.textInputAction,
  // }) : type = TextInputType.number;

  const AppInput.password(
      {super.key,
      required this.prefixIcon,
      this.isDisabled = false,
      this.isFocused = false,
      this.onChanged,
      this.hintText,
      this.controller,
      this.fieldError,
      this.value,
      this.onFieldSubmitted,
      this.textInputAction,
      this.focusNode,
      required this.isDeviceTv})
      : type = TextInputType.visiblePassword;

  const AppInput.email(
      {super.key,
      required this.prefixIcon,
      this.isFocused = false,
      this.isDisabled = false,
      this.onChanged,
      this.hintText,
      this.controller,
      this.fieldError,
      this.value,
      this.onFieldSubmitted,
      this.textInputAction,
      this.focusNode,
      required this.isDeviceTv})
      : type = TextInputType.emailAddress;

  // const AppInput.date({
  //   super.key,
  //   required this.prefixIcon,
  //   this.isDisabled = false,
  //   this.onChanged,
  //
  //   this.hintText,
  //   this.controller,
  //   this.isValid,
  //   this.value,
  //   this.onFieldSubmitted,
  //   this.textInputAction,
  // }) : type = TextInputType.datetime;

  const AppInput.phone({
    super.key,
    required this.prefixIcon,
    this.isDisabled = false,
    this.isFocused = false,
    this.onChanged,
    this.hintText,
    this.controller,
    this.fieldError,
    this.value,
    this.onFieldSubmitted,
    this.textInputAction,
    this.focusNode,
    required this.isDeviceTv,
  }) : type = TextInputType.phone;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  // We need to use it for passwword input to toggle obscureText
  late bool _obscureText = isPasswordInput;

  late InputDecoration decoration;

  late final TextEditingController _controller = _initController();

  late final FocusNode _focusNode = _initFocusNode();

  @override
  void initState() {
    _focusNode.addListener(_handleFocusChange);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant AppInput oldWidget) {
    if (widget.value != null && widget.value != oldWidget.value) {
      _controller.text = widget.value!;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }

    _focusNode.removeListener(_handleFocusChange);

    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UiColors uiColors = context.uiColors;

    decoration = InputStyle.decoration(
      uiColors.primary,
      uiColors.error,
    ).copyWith(
      filled: true,
      fillColor: fillColor,

      prefixIcon: _InputIcon(
        icon: widget.prefixIcon,
        isInputFocused: hasFocus,
        isInputDirty: isDirty,
        isInputValid: isValid,
      ),

      suffixIcon: isPasswordInput
          ? _InputIcon(
              icon: passwordPrefixIcon,
              isInputFocused: hasFocus,
              isInputDirty: isDirty,
              isInputValid: isValid,
              onPressed: _toggleTextObscurity,
            )
          : null,

      /// if hintText and label exist at the same time, label will be prioritized
      hintText: widget.hintText,
      errorText: widget.fieldError,
    );

    decoration = _handleSelectedBorder();

    return TextField(
      key: widget.key,
      controller: _controller,
      focusNode: _focusNode,
      canRequestFocus: !widget.isDeviceTv,
      decoration: decoration,
      style: TextStyles.bodyMediumSemiBold,
      keyboardType: widget.type,
      enabled: !widget.isDisabled,
      obscuringCharacter: '●',
      obscureText: _obscureText,
      inputFormatters: [
        if (isPhoneInput)
          PhoneInputFormatter(
            allowEndlessPhone: false,
            defaultCountryCode: 'US',
          )
      ],
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      onTap: _requestFocus,
      onTapOutside: (event) {
        FocusManager.instance.primaryFocus?.unfocus();
      },
    );
  }

  TextEditingController _initController() {
    final TextEditingController controller =
        widget.controller ?? TextEditingController();

    controller.text = widget.value ?? '';

    return controller;
  }

  FocusNode _initFocusNode() => widget.focusNode ?? FocusNode();

  void _handleFocusChange() => setState(() {});

  void _requestFocus() => FocusScope.of(context).requestFocus(_focusNode);

  void _toggleTextObscurity() => setState(() {
        _obscureText = !_obscureText;
      });

  InputDecoration _handleSelectedBorder() {
    return decoration.copyWith(
      enabledBorder: widget.isFocused
          ? decoration.enabledBorder?.copyWith(
              borderSide: BorderSide(color: context.uiColors.primary, width: 5),
            )
          : decoration.enabledBorder,
    );
  }

  // Input fill color depending on focus and dark, Colors from figma
  Color get fillColor {
    final Color color = context.isDarkMode
        ? AppColors.dark2
        : AppColors.greyscale[200] as Color;

    if (!hasFocus) return color;

    final Color inputColor =
        isValid ? context.uiColors.primary : context.uiColors.error;

    // 8% opacity for focused mode
    return Color.alphaBlend(inputColor.withOpacity(0.08), color);
  }

  String get passwordPrefixIcon =>
      _obscureText ? Assets.hidePassword : Assets.showPassword;

  bool get hasFocus => _focusNode.hasFocus;

  bool get isDirty => _controller.text.isNotEmpty;

  bool get isDarkMode => context.isDarkMode;

  bool get isValid => widget.fieldError == null;

  bool get isPasswordInput =>
      widget.type == TextInputType.visiblePassword && !widget.isDeviceTv;

  bool get isPhoneInput => widget.type == TextInputType.phone;
}

class _InputIcon extends StatelessWidget {
  const _InputIcon({
    this.onPressed,
    required this.icon,
    required this.isInputFocused,
    required this.isInputDirty,
    required this.isInputValid,
  });

  final VoidCallback? onPressed;
  final bool isInputFocused;
  final bool isInputDirty;
  final bool isInputValid;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final UiColors uiColors = context.uiColors;

    return AppTextButton.rounded(
      onPressed: onPressed,
      icon: (asset: icon, size: 20),
      childColor: _getColor(uiColors),
    );
  }

  Color _getColor(UiColors uiColors) {
    return isInputFocused
        ? _getFocusedColor(uiColors)
        : _getUnFocusedColor(uiColors);
  }

  Color _getFocusedColor(UiColors uiColors) {
    return isInputValid ? uiColors.primary : uiColors.error;
  }

  Color _getUnFocusedColor(UiColors uiColors) {
    return isInputDirty ? uiColors.primary : AppColors.greyscale[500] as Color;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';

const _shiftKey = '\u{25B2}';

enum AppKeyboardType { text, email }

class AppKeyboard extends StatefulWidget {
  const AppKeyboard.text({
    super.key,
    required this.onChanged,
    required this.onDeleted,
  }) : _type = AppKeyboardType.text;

  const AppKeyboard.email({
    super.key,
    required this.onChanged,
    required this.onDeleted,
  }) : _type = AppKeyboardType.email;

  final ValueChanged<String> onChanged;
  final VoidCallback onDeleted;
  final AppKeyboardType _type;

  @override
  State<AppKeyboard> createState() => _AppKeyboardState();
}

class _AppKeyboardState extends State<AppKeyboard> {
  bool isUpperCase = false;

  late List<List<(String key, FocusNode focusNode)>> commonKeys = [
    [
      ('1', FocusNode()),
      ('2', FocusNode()),
      ('3', FocusNode()),
      ('4', FocusNode()),
      ('5', FocusNode()),
      ('6', FocusNode()),
      ('7', FocusNode()),
      ('8', FocusNode()),
      ('9', FocusNode()),
      ('0', FocusNode()),
    ],
    [
      ('q', FocusNode()),
      ('w', FocusNode()),
      ('e', FocusNode()),
      ('r', FocusNode()),
      ('t', FocusNode()),
      ('y', FocusNode()),
      ('u', FocusNode()),
      ('i', FocusNode()),
      ('o', FocusNode()),
      ('p', FocusNode()),
    ],
    [
      ('a', FocusNode()),
      ('s', FocusNode()),
      ('d', FocusNode()),
      ('f', FocusNode()),
      ('g', FocusNode()),
      ('h', FocusNode()),
      ('j', FocusNode()),
      ('k', FocusNode()),
      ('l', FocusNode()),
      ('-', FocusNode()),
    ],
    [
      (_shiftKey, FocusNode()),
      ('z', FocusNode()),
      ('x', FocusNode()),
      ('c', FocusNode()),
      ('v', FocusNode()),
      ('b', FocusNode()),
      ('n', FocusNode()),
      ('m', FocusNode()),
      ('_', FocusNode()),
    ],
  ];

  late List<List<(String key, FocusNode focusNode)>> textKeys = [
    [
      ('.', FocusNode()),
      ('DEL', FocusNode()),
    ]
  ];

  late List<List<(String key, FocusNode focusNode)>> emailKeys = [
    [
      ('@gmail.com', FocusNode()),
      ('@yahoo.com', FocusNode()),
      ('@hotmail.com', FocusNode()),
    ],
    [
      ('@', FocusNode()),
      ('.', FocusNode()),
      ('.com', FocusNode()),
      ('DEL', FocusNode()),
    ]
  ];

  late final List<List<(String key, FocusNode focusNode)>> keys;

  @override
  void initState() {
    (switch (widget._type) {
      AppKeyboardType.text => _initTextKeys(),
      AppKeyboardType.email => _initEmailKeys(),
    });

    Future.microtask(() {
      keys[0].first.$2.requestFocus();
      setState(() {});
    });

    super.initState();
  }

  void _initEmailKeys() {
    keys = [...commonKeys, ...emailKeys];
  }

  void _initTextKeys() {
    keys = [...commonKeys, ...textKeys];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final keyRow in keys)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final item in keyRow)
                Expanded(
                  flex: item.$1 == _shiftKey ? 2 : 1,
                  child: Focus(
                    focusNode: item.$2,
                    onFocusChange: (hasFocus) {
                      setState(() {});
                    },
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;

                      if (event.logicalKey != LogicalKeyboardKey.select) {
                        return KeyEventResult.ignored;
                      }

                      return _onChanged(_getKey(item.$1));
                    },
                    child: _KeyContainer(
                      hasFocus: item.$2.hasFocus,
                      child: _Text(
                        keyCode: _getKey(item.$1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  KeyEventResult _onChanged(String keyCode) {
    (switch (keyCode) {
      'DEL' => widget.onDeleted(),
      _shiftKey => _setUppercase(),
      _ => widget.onChanged(keyCode),
    });

    return KeyEventResult.handled;
  }

  void _setUppercase() {
    setState(() {
      isUpperCase = !isUpperCase;
    });
  }

  String _getKey(String key) {
    return isUpperCase ? key.toUpperCase() : key;
  }
}

class _KeyContainer extends StatelessWidget {
  const _KeyContainer({
    required this.hasFocus,
    required this.child,
  });

  final bool hasFocus;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: AnimatedContainer(
        curve: Curves.easeInOut,
        duration: Durations.medium3,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: hasFocus ? context.uiColors.primary : AppColors.dark3,
        ),
        child: child,
      ),
    );
  }
}

class _Text extends StatelessWidget {
  const _Text({
    required this.keyCode,
  });

  final String keyCode;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        keyCode,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: TextStyles.bodyLargeBold.white,
      ),
    );
  }
}

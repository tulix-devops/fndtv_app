import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:ensure_visible_when_focused/ensure_visible_when_focused.dart';

/// A widget that displays a list of tags
class TagsWidget extends StatefulWidget {
  const TagsWidget({
    super.key,
    required this.attributes,
    required this.isTv,
  });

  final Map<String, String?> attributes;
  final bool isTv;

  @override
  State<TagsWidget> createState() => _TagsWidgetState();
}

class _TagsWidgetState extends State<TagsWidget> {
  late final ScrollController _controller;

  @override
  void initState() {
    _controller = ScrollController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var (index, item) in widget.attributes.entries.indexed)
          Row(
            children: [
              _Title(
                title: item.key,
              ),
              const SizedBox(width: 10),
              _InfoBlock(
                controller: _controller,
                entry: item,
              ),
            ],
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _Title extends StatelessWidget {
  const _Title({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 5),
            child: Text(
              title,
              style: TextStyles.bodyMediumMedium.copyWith(
                color: context.uiColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          AppIcon(
            Assets.singleArrowRight,
            color: context.uiColors.primary,
          )
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    super.key,
    required this.controller,
    required this.entry,
  });

  final ScrollController controller;
  final MapEntry<String, String?> entry;

  @override
  Widget build(BuildContext context) {
    final tags = entry.value?.split(',') ?? [];

    return Flexible(
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: controller,
          child: Row(
            children: [
              for (int index = 0; index < tags.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Chip(
                    label: tags[index], // Access each tag by index
                  ),
                )
            ],
          )),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.focusNode});
  final String label;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.all(
          Radius.circular(8.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.uiColors.primary,
              width: 1.5,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(8.0),
            ),
          ),
          child: Text(
            label,
            style: TextStyles.bodyXSmallSemiBold.surface(context),
          ),
        ),
      ),
    );
  }
}

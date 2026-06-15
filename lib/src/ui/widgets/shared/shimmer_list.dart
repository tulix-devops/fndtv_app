import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    required this.width,
    required this.height,
    required this.itemCount,
    required this.scrollDirection,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.radious = 16,
  });

  final double width;
  final double height;
  final int itemCount;
  final Axis scrollDirection;
  final EdgeInsets margin;
  final double radious;

  const ShimmerList.categoryShimmer(
      {super.key,
      required this.itemCount,
      required this.scrollDirection,
      this.margin = const EdgeInsets.symmetric(horizontal: 16),
      this.radious = 16})
      : height = 80,
        width = 180;
  const ShimmerList.vodCard(
      {super.key,
      required this.itemCount,
      required this.scrollDirection,
      this.margin = const EdgeInsets.symmetric(horizontal: 16),
      this.radious = 16})
      : height = 250,
        width = 150;

  const ShimmerList.liveCard(
      {super.key,
      required this.itemCount,
      required this.scrollDirection,
      this.margin = const EdgeInsets.symmetric(horizontal: 16),
      this.radious = 16})
      : height = 185,
        width = 190;

  const ShimmerList.button(
      {super.key,
      required this.itemCount,
      required this.scrollDirection,
      this.margin = const EdgeInsets.symmetric(horizontal: 10),
      this.radious = 16})
      : width = 120,
        height = 60;

  List<Padding> shimmerContent() {
    return List.generate(
      itemCount,
      (index) => Padding(
        padding: margin,
        child: ShimmerLoading(
          isLoading: true,
          child: Skeleton(
            radius: radious,
            width: width,
            height: height,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      isAccentColor: true,
      child: scrollDirection == Axis.horizontal
          ? Row(
              children: shimmerContent(),
            )
          : Column(
              children: shimmerContent(),
            ),
    );
  }
}

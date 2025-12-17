import 'package:flutter/rendering.dart';

class SliverGridDelegateWithMinCrossAxisExtent extends SliverGridDelegate {
  final double minCrossAxisExtent;
  final double mainAxisExtent;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const SliverGridDelegateWithMinCrossAxisExtent({
    required this.minCrossAxisExtent,
    required this.mainAxisExtent,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    // calculate how many columns we can fit without shrinking below min extent
    int crossAxisCount = (constraints.crossAxisExtent / (minCrossAxisExtent + crossAxisSpacing)).floor();

    // ensure at least one column
    if (crossAxisCount < 1) crossAxisCount = 1;

    // calculate the actual width of the items (they will stretch to fill space)
    final double usableCrossAxisExtent = constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1);
    final double childCrossAxisExtent = usableCrossAxisExtent / crossAxisCount;

    // return the layout geometry
    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: mainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: mainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection)
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateWithMinCrossAxisExtent oldDelegate) {
    return oldDelegate.minCrossAxisExtent != minCrossAxisExtent ||
      oldDelegate.mainAxisExtent != mainAxisExtent ||
      oldDelegate.crossAxisSpacing != crossAxisSpacing ||
      oldDelegate.mainAxisSpacing != mainAxisSpacing;
  }
}
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/colors.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const RoundedRectangleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.backgroundSecondary,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: AppColors.surface,
          shape: shapeBorder,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:frontend/shared/widgets/shimmer_loading.dart';

class SeriesCardShimmer extends StatelessWidget {
  const SeriesCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      width: 180,
      height: 300,
      shapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}
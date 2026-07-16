import 'package:flutter/material.dart';
import 'package:frontend/shared/widgets/shimmer_loading.dart';

class EpisodeCardShimmer extends StatelessWidget {
  const EpisodeCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      width: double.infinity,
      height: 104, // Matches the approximate height of EpisodeCard
      shapeBorder: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}
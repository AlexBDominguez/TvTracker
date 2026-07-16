import 'package:flutter/material.dart';
import 'package:frontend/data/models/series.dart';
import 'package:frontend/shared/widgets/series_card.dart';

class HorizontalCarousel extends StatelessWidget {
  final String title;
  final List<Series> series;
  final VoidCallback? onSeeAll;

  const HorizontalCarousel({
    super.key,
    required this.title,
    required this.series,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: textTheme.displaySmall),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text('Ver todo'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: series.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 180,
                  child: SeriesCard(series: series[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
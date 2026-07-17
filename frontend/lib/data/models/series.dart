import 'package:freezed_annotation/freezed_annotation.dart';

part 'series.freezed.dart';
part 'series.g.dart';

enum SeriesStatus { watching, completed, paused, dropped, planToWatch }

@freezed
class Series with _$Series {
  const factory Series({
    required int id,
    required String name,
    required String? posterPath,
    required String? backdropPath,
    required String overview,
    required double voteAverage,
    required int numberOfSeasons,
    SeriesStatus? status, // Added status
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
}
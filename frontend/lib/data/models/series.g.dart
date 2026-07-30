// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeriesImpl _$$SeriesImplFromJson(Map<String, dynamic> json) => _$SeriesImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      overview: json['overview'] as String,
      voteAverage: (json['voteAverage'] as num).toDouble(),
      numberOfSeasons: (json['numberOfSeasons'] as num).toInt(),
      status: $enumDecodeNullable(_$SeriesStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$$SeriesImplToJson(_$SeriesImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'posterPath': instance.posterPath,
      'backdropPath': instance.backdropPath,
      'overview': instance.overview,
      'voteAverage': instance.voteAverage,
      'numberOfSeasons': instance.numberOfSeasons,
      'status': _$SeriesStatusEnumMap[instance.status],
    };

const _$SeriesStatusEnumMap = {
  SeriesStatus.watching: 'watching',
  SeriesStatus.completed: 'completed',
  SeriesStatus.paused: 'paused',
  SeriesStatus.dropped: 'dropped',
  SeriesStatus.planToWatch: 'planToWatch',
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EpisodeImpl _$$EpisodeImplFromJson(Map<String, dynamic> json) =>
    _$EpisodeImpl(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      seasonNumber: (json['seasonNumber'] as num).toInt(),
      episodeNumber: (json['episodeNumber'] as num).toInt(),
      stillPath: json['stillPath'] as String?,
      overview: json['overview'] as String,
      airDate: json['airDate'] == null
          ? null
          : DateTime.parse(json['airDate'] as String),
      seriesId: (json['seriesId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$EpisodeImplToJson(_$EpisodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'seasonNumber': instance.seasonNumber,
      'episodeNumber': instance.episodeNumber,
      'stillPath': instance.stillPath,
      'overview': instance.overview,
      'airDate': instance.airDate?.toIso8601String(),
      'seriesId': instance.seriesId,
    };

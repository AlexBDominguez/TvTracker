// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'episode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Episode _$EpisodeFromJson(Map<String, dynamic> json) {
  return _Episode.fromJson(json);
}

/// @nodoc
mixin _$Episode {
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get seasonNumber => throw _privateConstructorUsedError;
  int get episodeNumber => throw _privateConstructorUsedError;
  String? get stillPath => throw _privateConstructorUsedError;
  String get overview => throw _privateConstructorUsedError;
  DateTime? get airDate => throw _privateConstructorUsedError;
  int? get seriesId => throw _privateConstructorUsedError;

  /// Serializes this Episode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpisodeCopyWith<Episode> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpisodeCopyWith<$Res> {
  factory $EpisodeCopyWith(Episode value, $Res Function(Episode) then) =
      _$EpisodeCopyWithImpl<$Res, Episode>;
  @useResult
  $Res call({
    int id,
    String name,
    int seasonNumber,
    int episodeNumber,
    String? stillPath,
    String overview,
    DateTime? airDate,
    int? seriesId,
  });
}

/// @nodoc
class _$EpisodeCopyWithImpl<$Res, $Val extends Episode>
    implements $EpisodeCopyWith<$Res> {
  _$EpisodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? seasonNumber = null,
    Object? episodeNumber = null,
    Object? stillPath = freezed,
    Object? overview = null,
    Object? airDate = freezed,
    Object? seriesId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            seasonNumber: null == seasonNumber
                ? _value.seasonNumber
                : seasonNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            episodeNumber: null == episodeNumber
                ? _value.episodeNumber
                : episodeNumber // ignore: cast_nullable_to_non_nullable
                      as int,
            stillPath: freezed == stillPath
                ? _value.stillPath
                : stillPath // ignore: cast_nullable_to_non_nullable
                      as String?,
            overview: null == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String,
            airDate: freezed == airDate
                ? _value.airDate
                : airDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            seriesId: freezed == seriesId
                ? _value.seriesId
                : seriesId // ignore: cast_nullable_to_non_nullable
                      as int?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EpisodeImplCopyWith<$Res> implements $EpisodeCopyWith<$Res> {
  factory _$$EpisodeImplCopyWith(
    _$EpisodeImpl value,
    $Res Function(_$EpisodeImpl) then,
  ) = __$$EpisodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    String name,
    int seasonNumber,
    int episodeNumber,
    String? stillPath,
    String overview,
    DateTime? airDate,
    int? seriesId,
  });
}

/// @nodoc
class __$$EpisodeImplCopyWithImpl<$Res>
    extends _$EpisodeCopyWithImpl<$Res, _$EpisodeImpl>
    implements _$$EpisodeImplCopyWith<$Res> {
  __$$EpisodeImplCopyWithImpl(
    _$EpisodeImpl _value,
    $Res Function(_$EpisodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? seasonNumber = null,
    Object? episodeNumber = null,
    Object? stillPath = freezed,
    Object? overview = null,
    Object? airDate = freezed,
    Object? seriesId = freezed,
  }) {
    return _then(
      _$EpisodeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        seasonNumber: null == seasonNumber
            ? _value.seasonNumber
            : seasonNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        episodeNumber: null == episodeNumber
            ? _value.episodeNumber
            : episodeNumber // ignore: cast_nullable_to_non_nullable
                  as int,
        stillPath: freezed == stillPath
            ? _value.stillPath
            : stillPath // ignore: cast_nullable_to_non_nullable
                  as String?,
        overview: null == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String,
        airDate: freezed == airDate
            ? _value.airDate
            : airDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        seriesId: freezed == seriesId
            ? _value.seriesId
            : seriesId // ignore: cast_nullable_to_non_nullable
                  as int?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EpisodeImpl implements _Episode {
  const _$EpisodeImpl({
    required this.id,
    required this.name,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.stillPath,
    required this.overview,
    required this.airDate,
    this.seriesId,
  });

  factory _$EpisodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpisodeImplFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final int seasonNumber;
  @override
  final int episodeNumber;
  @override
  final String? stillPath;
  @override
  final String overview;
  @override
  final DateTime? airDate;
  @override
  final int? seriesId;

  @override
  String toString() {
    return 'Episode(id: $id, name: $name, seasonNumber: $seasonNumber, episodeNumber: $episodeNumber, stillPath: $stillPath, overview: $overview, airDate: $airDate, seriesId: $seriesId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpisodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.seasonNumber, seasonNumber) ||
                other.seasonNumber == seasonNumber) &&
            (identical(other.episodeNumber, episodeNumber) ||
                other.episodeNumber == episodeNumber) &&
            (identical(other.stillPath, stillPath) ||
                other.stillPath == stillPath) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.airDate, airDate) || other.airDate == airDate) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    seasonNumber,
    episodeNumber,
    stillPath,
    overview,
    airDate,
    seriesId,
  );

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpisodeImplCopyWith<_$EpisodeImpl> get copyWith =>
      __$$EpisodeImplCopyWithImpl<_$EpisodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpisodeImplToJson(this);
  }
}

abstract class _Episode implements Episode {
  const factory _Episode({
    required final int id,
    required final String name,
    required final int seasonNumber,
    required final int episodeNumber,
    required final String? stillPath,
    required final String overview,
    required final DateTime? airDate,
    final int? seriesId,
  }) = _$EpisodeImpl;

  factory _Episode.fromJson(Map<String, dynamic> json) = _$EpisodeImpl.fromJson;

  @override
  int get id;
  @override
  String get name;
  @override
  int get seasonNumber;
  @override
  int get episodeNumber;
  @override
  String? get stillPath;
  @override
  String get overview;
  @override
  DateTime? get airDate;
  @override
  int? get seriesId;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpisodeImplCopyWith<_$EpisodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

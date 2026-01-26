// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'modification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Modification _$ModificationFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'audioMute':
      return AudioMute.fromJson(json);
    case 'audioBeep':
      return AudioBeep.fromJson(json);
    case 'audioReplace':
      return AudioReplace.fromJson(json);
    case 'videoBlur':
      return VideoBlur.fromJson(json);
    case 'videoPixelate':
      return VideoPixelate.fromJson(json);
    case 'videoBlackBox':
      return VideoBlackBox.fromJson(json);
    case 'videoSkip':
      return VideoSkip.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'Modification',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$Modification {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() audioMute,
    required TResult Function(int frequency, double volume) audioBeep,
    required TResult Function(String audioPath, double volume, bool loop)
        audioReplace,
    required TResult Function(int intensity) videoBlur,
    required TResult Function(int blockSize) videoPixelate,
    required TResult Function(String color, double opacity) videoBlackBox,
    required TResult Function() videoSkip,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? audioMute,
    TResult? Function(int frequency, double volume)? audioBeep,
    TResult? Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult? Function(int intensity)? videoBlur,
    TResult? Function(int blockSize)? videoPixelate,
    TResult? Function(String color, double opacity)? videoBlackBox,
    TResult? Function()? videoSkip,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? audioMute,
    TResult Function(int frequency, double volume)? audioBeep,
    TResult Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult Function(int intensity)? videoBlur,
    TResult Function(int blockSize)? videoPixelate,
    TResult Function(String color, double opacity)? videoBlackBox,
    TResult Function()? videoSkip,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AudioMute value) audioMute,
    required TResult Function(AudioBeep value) audioBeep,
    required TResult Function(AudioReplace value) audioReplace,
    required TResult Function(VideoBlur value) videoBlur,
    required TResult Function(VideoPixelate value) videoPixelate,
    required TResult Function(VideoBlackBox value) videoBlackBox,
    required TResult Function(VideoSkip value) videoSkip,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AudioMute value)? audioMute,
    TResult? Function(AudioBeep value)? audioBeep,
    TResult? Function(AudioReplace value)? audioReplace,
    TResult? Function(VideoBlur value)? videoBlur,
    TResult? Function(VideoPixelate value)? videoPixelate,
    TResult? Function(VideoBlackBox value)? videoBlackBox,
    TResult? Function(VideoSkip value)? videoSkip,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AudioMute value)? audioMute,
    TResult Function(AudioBeep value)? audioBeep,
    TResult Function(AudioReplace value)? audioReplace,
    TResult Function(VideoBlur value)? videoBlur,
    TResult Function(VideoPixelate value)? videoPixelate,
    TResult Function(VideoBlackBox value)? videoBlackBox,
    TResult Function(VideoSkip value)? videoSkip,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this Modification to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModificationCopyWith<$Res> {
  factory $ModificationCopyWith(
          Modification value, $Res Function(Modification) then) =
      _$ModificationCopyWithImpl<$Res, Modification>;
}

/// @nodoc
class _$ModificationCopyWithImpl<$Res, $Val extends Modification>
    implements $ModificationCopyWith<$Res> {
  _$ModificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AudioMuteImplCopyWith<$Res> {
  factory _$$AudioMuteImplCopyWith(
          _$AudioMuteImpl value, $Res Function(_$AudioMuteImpl) then) =
      __$$AudioMuteImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$AudioMuteImplCopyWithImpl<$Res>
    extends _$ModificationCopyWithImpl<$Res, _$AudioMuteImpl>
    implements _$$AudioMuteImplCopyWith<$Res> {
  __$$AudioMuteImplCopyWithImpl(
      _$AudioMuteImpl _value, $Res Function(_$AudioMuteImpl) _then)
      : super(_value, _then);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$AudioMuteImpl extends AudioMute {
  const _$AudioMuteImpl({final String? $type})
      : $type = $type ?? 'audioMute',
        super._();

  factory _$AudioMuteImpl.fromJson(Map<String, dynamic> json) =>
      _$$AudioMuteImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Modification.audioMute()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$AudioMuteImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() audioMute,
    required TResult Function(int frequency, double volume) audioBeep,
    required TResult Function(String audioPath, double volume, bool loop)
        audioReplace,
    required TResult Function(int intensity) videoBlur,
    required TResult Function(int blockSize) videoPixelate,
    required TResult Function(String color, double opacity) videoBlackBox,
    required TResult Function() videoSkip,
  }) {
    return audioMute();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? audioMute,
    TResult? Function(int frequency, double volume)? audioBeep,
    TResult? Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult? Function(int intensity)? videoBlur,
    TResult? Function(int blockSize)? videoPixelate,
    TResult? Function(String color, double opacity)? videoBlackBox,
    TResult? Function()? videoSkip,
  }) {
    return audioMute?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? audioMute,
    TResult Function(int frequency, double volume)? audioBeep,
    TResult Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult Function(int intensity)? videoBlur,
    TResult Function(int blockSize)? videoPixelate,
    TResult Function(String color, double opacity)? videoBlackBox,
    TResult Function()? videoSkip,
    required TResult orElse(),
  }) {
    if (audioMute != null) {
      return audioMute();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AudioMute value) audioMute,
    required TResult Function(AudioBeep value) audioBeep,
    required TResult Function(AudioReplace value) audioReplace,
    required TResult Function(VideoBlur value) videoBlur,
    required TResult Function(VideoPixelate value) videoPixelate,
    required TResult Function(VideoBlackBox value) videoBlackBox,
    required TResult Function(VideoSkip value) videoSkip,
  }) {
    return audioMute(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AudioMute value)? audioMute,
    TResult? Function(AudioBeep value)? audioBeep,
    TResult? Function(AudioReplace value)? audioReplace,
    TResult? Function(VideoBlur value)? videoBlur,
    TResult? Function(VideoPixelate value)? videoPixelate,
    TResult? Function(VideoBlackBox value)? videoBlackBox,
    TResult? Function(VideoSkip value)? videoSkip,
  }) {
    return audioMute?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AudioMute value)? audioMute,
    TResult Function(AudioBeep value)? audioBeep,
    TResult Function(AudioReplace value)? audioReplace,
    TResult Function(VideoBlur value)? videoBlur,
    TResult Function(VideoPixelate value)? videoPixelate,
    TResult Function(VideoBlackBox value)? videoBlackBox,
    TResult Function(VideoSkip value)? videoSkip,
    required TResult orElse(),
  }) {
    if (audioMute != null) {
      return audioMute(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AudioMuteImplToJson(
      this,
    );
  }
}

abstract class AudioMute extends Modification {
  const factory AudioMute() = _$AudioMuteImpl;
  const AudioMute._() : super._();

  factory AudioMute.fromJson(Map<String, dynamic> json) =
      _$AudioMuteImpl.fromJson;
}

/// @nodoc
abstract class _$$AudioBeepImplCopyWith<$Res> {
  factory _$$AudioBeepImplCopyWith(
          _$AudioBeepImpl value, $Res Function(_$AudioBeepImpl) then) =
      __$$AudioBeepImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int frequency, double volume});
}

/// @nodoc
class __$$AudioBeepImplCopyWithImpl<$Res>
    extends _$ModificationCopyWithImpl<$Res, _$AudioBeepImpl>
    implements _$$AudioBeepImplCopyWith<$Res> {
  __$$AudioBeepImplCopyWithImpl(
      _$AudioBeepImpl _value, $Res Function(_$AudioBeepImpl) _then)
      : super(_value, _then);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frequency = null,
    Object? volume = null,
  }) {
    return _then(_$AudioBeepImpl(
      frequency: null == frequency
          ? _value.frequency
          : frequency // ignore: cast_nullable_to_non_nullable
              as int,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AudioBeepImpl extends AudioBeep {
  const _$AudioBeepImpl(
      {this.frequency = 1000, this.volume = 0.5, final String? $type})
      : $type = $type ?? 'audioBeep',
        super._();

  factory _$AudioBeepImpl.fromJson(Map<String, dynamic> json) =>
      _$$AudioBeepImplFromJson(json);

  /// Frequency of the beep in Hz (default: 1000)
  @override
  @JsonKey()
  final int frequency;

  /// Volume level (0.0 to 1.0, default: 0.5)
  @override
  @JsonKey()
  final double volume;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Modification.audioBeep(frequency: $frequency, volume: $volume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioBeepImpl &&
            (identical(other.frequency, frequency) ||
                other.frequency == frequency) &&
            (identical(other.volume, volume) || other.volume == volume));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, frequency, volume);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioBeepImplCopyWith<_$AudioBeepImpl> get copyWith =>
      __$$AudioBeepImplCopyWithImpl<_$AudioBeepImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() audioMute,
    required TResult Function(int frequency, double volume) audioBeep,
    required TResult Function(String audioPath, double volume, bool loop)
        audioReplace,
    required TResult Function(int intensity) videoBlur,
    required TResult Function(int blockSize) videoPixelate,
    required TResult Function(String color, double opacity) videoBlackBox,
    required TResult Function() videoSkip,
  }) {
    return audioBeep(frequency, volume);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? audioMute,
    TResult? Function(int frequency, double volume)? audioBeep,
    TResult? Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult? Function(int intensity)? videoBlur,
    TResult? Function(int blockSize)? videoPixelate,
    TResult? Function(String color, double opacity)? videoBlackBox,
    TResult? Function()? videoSkip,
  }) {
    return audioBeep?.call(frequency, volume);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? audioMute,
    TResult Function(int frequency, double volume)? audioBeep,
    TResult Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult Function(int intensity)? videoBlur,
    TResult Function(int blockSize)? videoPixelate,
    TResult Function(String color, double opacity)? videoBlackBox,
    TResult Function()? videoSkip,
    required TResult orElse(),
  }) {
    if (audioBeep != null) {
      return audioBeep(frequency, volume);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AudioMute value) audioMute,
    required TResult Function(AudioBeep value) audioBeep,
    required TResult Function(AudioReplace value) audioReplace,
    required TResult Function(VideoBlur value) videoBlur,
    required TResult Function(VideoPixelate value) videoPixelate,
    required TResult Function(VideoBlackBox value) videoBlackBox,
    required TResult Function(VideoSkip value) videoSkip,
  }) {
    return audioBeep(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AudioMute value)? audioMute,
    TResult? Function(AudioBeep value)? audioBeep,
    TResult? Function(AudioReplace value)? audioReplace,
    TResult? Function(VideoBlur value)? videoBlur,
    TResult? Function(VideoPixelate value)? videoPixelate,
    TResult? Function(VideoBlackBox value)? videoBlackBox,
    TResult? Function(VideoSkip value)? videoSkip,
  }) {
    return audioBeep?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AudioMute value)? audioMute,
    TResult Function(AudioBeep value)? audioBeep,
    TResult Function(AudioReplace value)? audioReplace,
    TResult Function(VideoBlur value)? videoBlur,
    TResult Function(VideoPixelate value)? videoPixelate,
    TResult Function(VideoBlackBox value)? videoBlackBox,
    TResult Function(VideoSkip value)? videoSkip,
    required TResult orElse(),
  }) {
    if (audioBeep != null) {
      return audioBeep(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AudioBeepImplToJson(
      this,
    );
  }
}

abstract class AudioBeep extends Modification {
  const factory AudioBeep({final int frequency, final double volume}) =
      _$AudioBeepImpl;
  const AudioBeep._() : super._();

  factory AudioBeep.fromJson(Map<String, dynamic> json) =
      _$AudioBeepImpl.fromJson;

  /// Frequency of the beep in Hz (default: 1000)
  int get frequency;

  /// Volume level (0.0 to 1.0, default: 0.5)
  double get volume;

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AudioBeepImplCopyWith<_$AudioBeepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AudioReplaceImplCopyWith<$Res> {
  factory _$$AudioReplaceImplCopyWith(
          _$AudioReplaceImpl value, $Res Function(_$AudioReplaceImpl) then) =
      __$$AudioReplaceImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String audioPath, double volume, bool loop});
}

/// @nodoc
class __$$AudioReplaceImplCopyWithImpl<$Res>
    extends _$ModificationCopyWithImpl<$Res, _$AudioReplaceImpl>
    implements _$$AudioReplaceImplCopyWith<$Res> {
  __$$AudioReplaceImplCopyWithImpl(
      _$AudioReplaceImpl _value, $Res Function(_$AudioReplaceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? audioPath = null,
    Object? volume = null,
    Object? loop = null,
  }) {
    return _then(_$AudioReplaceImpl(
      audioPath: null == audioPath
          ? _value.audioPath
          : audioPath // ignore: cast_nullable_to_non_nullable
              as String,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      loop: null == loop
          ? _value.loop
          : loop // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AudioReplaceImpl extends AudioReplace {
  const _$AudioReplaceImpl(
      {required this.audioPath,
      this.volume = 1.0,
      this.loop = false,
      final String? $type})
      : $type = $type ?? 'audioReplace',
        super._();

  factory _$AudioReplaceImpl.fromJson(Map<String, dynamic> json) =>
      _$$AudioReplaceImplFromJson(json);

  /// Path to the replacement audio file
  @override
  final String audioPath;

  /// Volume level (0.0 to 1.0, default: 1.0)
  @override
  @JsonKey()
  final double volume;

  /// Whether to loop the audio if it's shorter than the region
  @override
  @JsonKey()
  final bool loop;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Modification.audioReplace(audioPath: $audioPath, volume: $volume, loop: $loop)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioReplaceImpl &&
            (identical(other.audioPath, audioPath) ||
                other.audioPath == audioPath) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.loop, loop) || other.loop == loop));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, audioPath, volume, loop);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioReplaceImplCopyWith<_$AudioReplaceImpl> get copyWith =>
      __$$AudioReplaceImplCopyWithImpl<_$AudioReplaceImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() audioMute,
    required TResult Function(int frequency, double volume) audioBeep,
    required TResult Function(String audioPath, double volume, bool loop)
        audioReplace,
    required TResult Function(int intensity) videoBlur,
    required TResult Function(int blockSize) videoPixelate,
    required TResult Function(String color, double opacity) videoBlackBox,
    required TResult Function() videoSkip,
  }) {
    return audioReplace(audioPath, volume, loop);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? audioMute,
    TResult? Function(int frequency, double volume)? audioBeep,
    TResult? Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult? Function(int intensity)? videoBlur,
    TResult? Function(int blockSize)? videoPixelate,
    TResult? Function(String color, double opacity)? videoBlackBox,
    TResult? Function()? videoSkip,
  }) {
    return audioReplace?.call(audioPath, volume, loop);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? audioMute,
    TResult Function(int frequency, double volume)? audioBeep,
    TResult Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult Function(int intensity)? videoBlur,
    TResult Function(int blockSize)? videoPixelate,
    TResult Function(String color, double opacity)? videoBlackBox,
    TResult Function()? videoSkip,
    required TResult orElse(),
  }) {
    if (audioReplace != null) {
      return audioReplace(audioPath, volume, loop);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AudioMute value) audioMute,
    required TResult Function(AudioBeep value) audioBeep,
    required TResult Function(AudioReplace value) audioReplace,
    required TResult Function(VideoBlur value) videoBlur,
    required TResult Function(VideoPixelate value) videoPixelate,
    required TResult Function(VideoBlackBox value) videoBlackBox,
    required TResult Function(VideoSkip value) videoSkip,
  }) {
    return audioReplace(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AudioMute value)? audioMute,
    TResult? Function(AudioBeep value)? audioBeep,
    TResult? Function(AudioReplace value)? audioReplace,
    TResult? Function(VideoBlur value)? videoBlur,
    TResult? Function(VideoPixelate value)? videoPixelate,
    TResult? Function(VideoBlackBox value)? videoBlackBox,
    TResult? Function(VideoSkip value)? videoSkip,
  }) {
    return audioReplace?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AudioMute value)? audioMute,
    TResult Function(AudioBeep value)? audioBeep,
    TResult Function(AudioReplace value)? audioReplace,
    TResult Function(VideoBlur value)? videoBlur,
    TResult Function(VideoPixelate value)? videoPixelate,
    TResult Function(VideoBlackBox value)? videoBlackBox,
    TResult Function(VideoSkip value)? videoSkip,
    required TResult orElse(),
  }) {
    if (audioReplace != null) {
      return audioReplace(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$AudioReplaceImplToJson(
      this,
    );
  }
}

abstract class AudioReplace extends Modification {
  const factory AudioReplace(
      {required final String audioPath,
      final double volume,
      final bool loop}) = _$AudioReplaceImpl;
  const AudioReplace._() : super._();

  factory AudioReplace.fromJson(Map<String, dynamic> json) =
      _$AudioReplaceImpl.fromJson;

  /// Path to the replacement audio file
  String get audioPath;

  /// Volume level (0.0 to 1.0, default: 1.0)
  double get volume;

  /// Whether to loop the audio if it's shorter than the region
  bool get loop;

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AudioReplaceImplCopyWith<_$AudioReplaceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VideoBlurImplCopyWith<$Res> {
  factory _$$VideoBlurImplCopyWith(
          _$VideoBlurImpl value, $Res Function(_$VideoBlurImpl) then) =
      __$$VideoBlurImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int intensity});
}

/// @nodoc
class __$$VideoBlurImplCopyWithImpl<$Res>
    extends _$ModificationCopyWithImpl<$Res, _$VideoBlurImpl>
    implements _$$VideoBlurImplCopyWith<$Res> {
  __$$VideoBlurImplCopyWithImpl(
      _$VideoBlurImpl _value, $Res Function(_$VideoBlurImpl) _then)
      : super(_value, _then);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? intensity = null,
  }) {
    return _then(_$VideoBlurImpl(
      intensity: null == intensity
          ? _value.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoBlurImpl extends VideoBlur {
  const _$VideoBlurImpl({this.intensity = 20, final String? $type})
      : $type = $type ?? 'videoBlur',
        super._();

  factory _$VideoBlurImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoBlurImplFromJson(json);

  /// Blur intensity (1-100, default: 20)
  @override
  @JsonKey()
  final int intensity;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Modification.videoBlur(intensity: $intensity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoBlurImpl &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, intensity);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoBlurImplCopyWith<_$VideoBlurImpl> get copyWith =>
      __$$VideoBlurImplCopyWithImpl<_$VideoBlurImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() audioMute,
    required TResult Function(int frequency, double volume) audioBeep,
    required TResult Function(String audioPath, double volume, bool loop)
        audioReplace,
    required TResult Function(int intensity) videoBlur,
    required TResult Function(int blockSize) videoPixelate,
    required TResult Function(String color, double opacity) videoBlackBox,
    required TResult Function() videoSkip,
  }) {
    return videoBlur(intensity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? audioMute,
    TResult? Function(int frequency, double volume)? audioBeep,
    TResult? Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult? Function(int intensity)? videoBlur,
    TResult? Function(int blockSize)? videoPixelate,
    TResult? Function(String color, double opacity)? videoBlackBox,
    TResult? Function()? videoSkip,
  }) {
    return videoBlur?.call(intensity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? audioMute,
    TResult Function(int frequency, double volume)? audioBeep,
    TResult Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult Function(int intensity)? videoBlur,
    TResult Function(int blockSize)? videoPixelate,
    TResult Function(String color, double opacity)? videoBlackBox,
    TResult Function()? videoSkip,
    required TResult orElse(),
  }) {
    if (videoBlur != null) {
      return videoBlur(intensity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AudioMute value) audioMute,
    required TResult Function(AudioBeep value) audioBeep,
    required TResult Function(AudioReplace value) audioReplace,
    required TResult Function(VideoBlur value) videoBlur,
    required TResult Function(VideoPixelate value) videoPixelate,
    required TResult Function(VideoBlackBox value) videoBlackBox,
    required TResult Function(VideoSkip value) videoSkip,
  }) {
    return videoBlur(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AudioMute value)? audioMute,
    TResult? Function(AudioBeep value)? audioBeep,
    TResult? Function(AudioReplace value)? audioReplace,
    TResult? Function(VideoBlur value)? videoBlur,
    TResult? Function(VideoPixelate value)? videoPixelate,
    TResult? Function(VideoBlackBox value)? videoBlackBox,
    TResult? Function(VideoSkip value)? videoSkip,
  }) {
    return videoBlur?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AudioMute value)? audioMute,
    TResult Function(AudioBeep value)? audioBeep,
    TResult Function(AudioReplace value)? audioReplace,
    TResult Function(VideoBlur value)? videoBlur,
    TResult Function(VideoPixelate value)? videoPixelate,
    TResult Function(VideoBlackBox value)? videoBlackBox,
    TResult Function(VideoSkip value)? videoSkip,
    required TResult orElse(),
  }) {
    if (videoBlur != null) {
      return videoBlur(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoBlurImplToJson(
      this,
    );
  }
}

abstract class VideoBlur extends Modification {
  const factory VideoBlur({final int intensity}) = _$VideoBlurImpl;
  const VideoBlur._() : super._();

  factory VideoBlur.fromJson(Map<String, dynamic> json) =
      _$VideoBlurImpl.fromJson;

  /// Blur intensity (1-100, default: 20)
  int get intensity;

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoBlurImplCopyWith<_$VideoBlurImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VideoPixelateImplCopyWith<$Res> {
  factory _$$VideoPixelateImplCopyWith(
          _$VideoPixelateImpl value, $Res Function(_$VideoPixelateImpl) then) =
      __$$VideoPixelateImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int blockSize});
}

/// @nodoc
class __$$VideoPixelateImplCopyWithImpl<$Res>
    extends _$ModificationCopyWithImpl<$Res, _$VideoPixelateImpl>
    implements _$$VideoPixelateImplCopyWith<$Res> {
  __$$VideoPixelateImplCopyWithImpl(
      _$VideoPixelateImpl _value, $Res Function(_$VideoPixelateImpl) _then)
      : super(_value, _then);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? blockSize = null,
  }) {
    return _then(_$VideoPixelateImpl(
      blockSize: null == blockSize
          ? _value.blockSize
          : blockSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoPixelateImpl extends VideoPixelate {
  const _$VideoPixelateImpl({this.blockSize = 16, final String? $type})
      : $type = $type ?? 'videoPixelate',
        super._();

  factory _$VideoPixelateImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoPixelateImplFromJson(json);

  /// Size of pixelation blocks in pixels (default: 16)
  @override
  @JsonKey()
  final int blockSize;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Modification.videoPixelate(blockSize: $blockSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoPixelateImpl &&
            (identical(other.blockSize, blockSize) ||
                other.blockSize == blockSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, blockSize);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoPixelateImplCopyWith<_$VideoPixelateImpl> get copyWith =>
      __$$VideoPixelateImplCopyWithImpl<_$VideoPixelateImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() audioMute,
    required TResult Function(int frequency, double volume) audioBeep,
    required TResult Function(String audioPath, double volume, bool loop)
        audioReplace,
    required TResult Function(int intensity) videoBlur,
    required TResult Function(int blockSize) videoPixelate,
    required TResult Function(String color, double opacity) videoBlackBox,
    required TResult Function() videoSkip,
  }) {
    return videoPixelate(blockSize);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? audioMute,
    TResult? Function(int frequency, double volume)? audioBeep,
    TResult? Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult? Function(int intensity)? videoBlur,
    TResult? Function(int blockSize)? videoPixelate,
    TResult? Function(String color, double opacity)? videoBlackBox,
    TResult? Function()? videoSkip,
  }) {
    return videoPixelate?.call(blockSize);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? audioMute,
    TResult Function(int frequency, double volume)? audioBeep,
    TResult Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult Function(int intensity)? videoBlur,
    TResult Function(int blockSize)? videoPixelate,
    TResult Function(String color, double opacity)? videoBlackBox,
    TResult Function()? videoSkip,
    required TResult orElse(),
  }) {
    if (videoPixelate != null) {
      return videoPixelate(blockSize);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AudioMute value) audioMute,
    required TResult Function(AudioBeep value) audioBeep,
    required TResult Function(AudioReplace value) audioReplace,
    required TResult Function(VideoBlur value) videoBlur,
    required TResult Function(VideoPixelate value) videoPixelate,
    required TResult Function(VideoBlackBox value) videoBlackBox,
    required TResult Function(VideoSkip value) videoSkip,
  }) {
    return videoPixelate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AudioMute value)? audioMute,
    TResult? Function(AudioBeep value)? audioBeep,
    TResult? Function(AudioReplace value)? audioReplace,
    TResult? Function(VideoBlur value)? videoBlur,
    TResult? Function(VideoPixelate value)? videoPixelate,
    TResult? Function(VideoBlackBox value)? videoBlackBox,
    TResult? Function(VideoSkip value)? videoSkip,
  }) {
    return videoPixelate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AudioMute value)? audioMute,
    TResult Function(AudioBeep value)? audioBeep,
    TResult Function(AudioReplace value)? audioReplace,
    TResult Function(VideoBlur value)? videoBlur,
    TResult Function(VideoPixelate value)? videoPixelate,
    TResult Function(VideoBlackBox value)? videoBlackBox,
    TResult Function(VideoSkip value)? videoSkip,
    required TResult orElse(),
  }) {
    if (videoPixelate != null) {
      return videoPixelate(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoPixelateImplToJson(
      this,
    );
  }
}

abstract class VideoPixelate extends Modification {
  const factory VideoPixelate({final int blockSize}) = _$VideoPixelateImpl;
  const VideoPixelate._() : super._();

  factory VideoPixelate.fromJson(Map<String, dynamic> json) =
      _$VideoPixelateImpl.fromJson;

  /// Size of pixelation blocks in pixels (default: 16)
  int get blockSize;

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoPixelateImplCopyWith<_$VideoPixelateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VideoBlackBoxImplCopyWith<$Res> {
  factory _$$VideoBlackBoxImplCopyWith(
          _$VideoBlackBoxImpl value, $Res Function(_$VideoBlackBoxImpl) then) =
      __$$VideoBlackBoxImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String color, double opacity});
}

/// @nodoc
class __$$VideoBlackBoxImplCopyWithImpl<$Res>
    extends _$ModificationCopyWithImpl<$Res, _$VideoBlackBoxImpl>
    implements _$$VideoBlackBoxImplCopyWith<$Res> {
  __$$VideoBlackBoxImplCopyWithImpl(
      _$VideoBlackBoxImpl _value, $Res Function(_$VideoBlackBoxImpl) _then)
      : super(_value, _then);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? color = null,
    Object? opacity = null,
  }) {
    return _then(_$VideoBlackBoxImpl(
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      opacity: null == opacity
          ? _value.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoBlackBoxImpl extends VideoBlackBox {
  const _$VideoBlackBoxImpl(
      {this.color = '#000000', this.opacity = 1.0, final String? $type})
      : $type = $type ?? 'videoBlackBox',
        super._();

  factory _$VideoBlackBoxImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoBlackBoxImplFromJson(json);

  /// Optional color in hex format (default: black)
  @override
  @JsonKey()
  final String color;

  /// Opacity level (0.0 to 1.0, default: 1.0)
  @override
  @JsonKey()
  final double opacity;

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Modification.videoBlackBox(color: $color, opacity: $opacity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoBlackBoxImpl &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.opacity, opacity) || other.opacity == opacity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, color, opacity);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoBlackBoxImplCopyWith<_$VideoBlackBoxImpl> get copyWith =>
      __$$VideoBlackBoxImplCopyWithImpl<_$VideoBlackBoxImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() audioMute,
    required TResult Function(int frequency, double volume) audioBeep,
    required TResult Function(String audioPath, double volume, bool loop)
        audioReplace,
    required TResult Function(int intensity) videoBlur,
    required TResult Function(int blockSize) videoPixelate,
    required TResult Function(String color, double opacity) videoBlackBox,
    required TResult Function() videoSkip,
  }) {
    return videoBlackBox(color, opacity);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? audioMute,
    TResult? Function(int frequency, double volume)? audioBeep,
    TResult? Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult? Function(int intensity)? videoBlur,
    TResult? Function(int blockSize)? videoPixelate,
    TResult? Function(String color, double opacity)? videoBlackBox,
    TResult? Function()? videoSkip,
  }) {
    return videoBlackBox?.call(color, opacity);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? audioMute,
    TResult Function(int frequency, double volume)? audioBeep,
    TResult Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult Function(int intensity)? videoBlur,
    TResult Function(int blockSize)? videoPixelate,
    TResult Function(String color, double opacity)? videoBlackBox,
    TResult Function()? videoSkip,
    required TResult orElse(),
  }) {
    if (videoBlackBox != null) {
      return videoBlackBox(color, opacity);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AudioMute value) audioMute,
    required TResult Function(AudioBeep value) audioBeep,
    required TResult Function(AudioReplace value) audioReplace,
    required TResult Function(VideoBlur value) videoBlur,
    required TResult Function(VideoPixelate value) videoPixelate,
    required TResult Function(VideoBlackBox value) videoBlackBox,
    required TResult Function(VideoSkip value) videoSkip,
  }) {
    return videoBlackBox(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AudioMute value)? audioMute,
    TResult? Function(AudioBeep value)? audioBeep,
    TResult? Function(AudioReplace value)? audioReplace,
    TResult? Function(VideoBlur value)? videoBlur,
    TResult? Function(VideoPixelate value)? videoPixelate,
    TResult? Function(VideoBlackBox value)? videoBlackBox,
    TResult? Function(VideoSkip value)? videoSkip,
  }) {
    return videoBlackBox?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AudioMute value)? audioMute,
    TResult Function(AudioBeep value)? audioBeep,
    TResult Function(AudioReplace value)? audioReplace,
    TResult Function(VideoBlur value)? videoBlur,
    TResult Function(VideoPixelate value)? videoPixelate,
    TResult Function(VideoBlackBox value)? videoBlackBox,
    TResult Function(VideoSkip value)? videoSkip,
    required TResult orElse(),
  }) {
    if (videoBlackBox != null) {
      return videoBlackBox(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoBlackBoxImplToJson(
      this,
    );
  }
}

abstract class VideoBlackBox extends Modification {
  const factory VideoBlackBox({final String color, final double opacity}) =
      _$VideoBlackBoxImpl;
  const VideoBlackBox._() : super._();

  factory VideoBlackBox.fromJson(Map<String, dynamic> json) =
      _$VideoBlackBoxImpl.fromJson;

  /// Optional color in hex format (default: black)
  String get color;

  /// Opacity level (0.0 to 1.0, default: 1.0)
  double get opacity;

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoBlackBoxImplCopyWith<_$VideoBlackBoxImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VideoSkipImplCopyWith<$Res> {
  factory _$$VideoSkipImplCopyWith(
          _$VideoSkipImpl value, $Res Function(_$VideoSkipImpl) then) =
      __$$VideoSkipImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$VideoSkipImplCopyWithImpl<$Res>
    extends _$ModificationCopyWithImpl<$Res, _$VideoSkipImpl>
    implements _$$VideoSkipImplCopyWith<$Res> {
  __$$VideoSkipImplCopyWithImpl(
      _$VideoSkipImpl _value, $Res Function(_$VideoSkipImpl) _then)
      : super(_value, _then);

  /// Create a copy of Modification
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
@JsonSerializable()
class _$VideoSkipImpl extends VideoSkip {
  const _$VideoSkipImpl({final String? $type})
      : $type = $type ?? 'videoSkip',
        super._();

  factory _$VideoSkipImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoSkipImplFromJson(json);

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'Modification.videoSkip()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$VideoSkipImpl);
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() audioMute,
    required TResult Function(int frequency, double volume) audioBeep,
    required TResult Function(String audioPath, double volume, bool loop)
        audioReplace,
    required TResult Function(int intensity) videoBlur,
    required TResult Function(int blockSize) videoPixelate,
    required TResult Function(String color, double opacity) videoBlackBox,
    required TResult Function() videoSkip,
  }) {
    return videoSkip();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? audioMute,
    TResult? Function(int frequency, double volume)? audioBeep,
    TResult? Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult? Function(int intensity)? videoBlur,
    TResult? Function(int blockSize)? videoPixelate,
    TResult? Function(String color, double opacity)? videoBlackBox,
    TResult? Function()? videoSkip,
  }) {
    return videoSkip?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? audioMute,
    TResult Function(int frequency, double volume)? audioBeep,
    TResult Function(String audioPath, double volume, bool loop)? audioReplace,
    TResult Function(int intensity)? videoBlur,
    TResult Function(int blockSize)? videoPixelate,
    TResult Function(String color, double opacity)? videoBlackBox,
    TResult Function()? videoSkip,
    required TResult orElse(),
  }) {
    if (videoSkip != null) {
      return videoSkip();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AudioMute value) audioMute,
    required TResult Function(AudioBeep value) audioBeep,
    required TResult Function(AudioReplace value) audioReplace,
    required TResult Function(VideoBlur value) videoBlur,
    required TResult Function(VideoPixelate value) videoPixelate,
    required TResult Function(VideoBlackBox value) videoBlackBox,
    required TResult Function(VideoSkip value) videoSkip,
  }) {
    return videoSkip(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AudioMute value)? audioMute,
    TResult? Function(AudioBeep value)? audioBeep,
    TResult? Function(AudioReplace value)? audioReplace,
    TResult? Function(VideoBlur value)? videoBlur,
    TResult? Function(VideoPixelate value)? videoPixelate,
    TResult? Function(VideoBlackBox value)? videoBlackBox,
    TResult? Function(VideoSkip value)? videoSkip,
  }) {
    return videoSkip?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AudioMute value)? audioMute,
    TResult Function(AudioBeep value)? audioBeep,
    TResult Function(AudioReplace value)? audioReplace,
    TResult Function(VideoBlur value)? videoBlur,
    TResult Function(VideoPixelate value)? videoPixelate,
    TResult Function(VideoBlackBox value)? videoBlackBox,
    TResult Function(VideoSkip value)? videoSkip,
    required TResult orElse(),
  }) {
    if (videoSkip != null) {
      return videoSkip(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoSkipImplToJson(
      this,
    );
  }
}

abstract class VideoSkip extends Modification {
  const factory VideoSkip() = _$VideoSkipImpl;
  const VideoSkip._() : super._();

  factory VideoSkip.fromJson(Map<String, dynamic> json) =
      _$VideoSkipImpl.fromJson;
}

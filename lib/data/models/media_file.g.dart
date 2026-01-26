// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MediaFileImpl _$$MediaFileImplFromJson(Map<String, dynamic> json) =>
    _$MediaFileImpl(
      id: json['id'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      duration:
          const DurationConverter().fromJson((json['duration'] as num).toInt()),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      fileSize: (json['fileSize'] as num).toInt(),
      codec: json['codec'] as String?,
      container: json['container'] as String?,
      mediaType: $enumDecode(_$MediaTypeEnumMap, json['mediaType']),
    );

Map<String, dynamic> _$$MediaFileImplToJson(_$MediaFileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'path': instance.path,
      'name': instance.name,
      'duration': const DurationConverter().toJson(instance.duration),
      'width': instance.width,
      'height': instance.height,
      'fileSize': instance.fileSize,
      'codec': instance.codec,
      'container': instance.container,
      'mediaType': _$MediaTypeEnumMap[instance.mediaType]!,
    };

const _$MediaTypeEnumMap = {
  MediaType.video: 'video',
  MediaType.audio: 'audio',
};

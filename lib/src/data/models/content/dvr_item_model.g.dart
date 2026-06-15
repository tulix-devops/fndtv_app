// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dvr_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DvrItemModelImpl _$$DvrItemModelImplFromJson(Map<String, dynamic> json) =>
    _$DvrItemModelImpl(
      id: (json['id'] as num).toInt(),
      title: json['name'] as String,
      descr: json['descr'] as String,
      duration: json['length'] as String?,
      thumb: json['hdposterurl'] as String?,
      stream: json['hls'] as String,
      downloadurl: json['downloadurl'] as String?,
      isLive: (json['islive'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DvrItemModelImplToJson(_$DvrItemModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.title,
      'descr': instance.descr,
      'length': instance.duration,
      'hdposterurl': instance.thumb,
      'hls': instance.stream,
      'downloadurl': instance.downloadurl,
      'islive': instance.isLive,
    };

_$DvrDataModelImpl _$$DvrDataModelImplFromJson(Map<String, dynamic> json) =>
    _$DvrDataModelImpl(
      items: (json['items'] as List<dynamic>)
          .map((e) => DvrItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$DvrDataModelImplToJson(_$DvrDataModelImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
    };

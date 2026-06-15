// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VodListModelImpl _$$VodListModelImplFromJson(Map<String, dynamic> json) =>
    _$VodListModelImpl(
      videos: (json['data'] as List<dynamic>)
          .map((e) => VodModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$VodListModelImplToJson(_$VodListModelImpl instance) =>
    <String, dynamic>{
      'data': instance.videos,
    };

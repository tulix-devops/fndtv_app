// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_home_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VodHomeListModelImpl _$$VodHomeListModelImplFromJson(
        Map<String, dynamic> json) =>
    _$VodHomeListModelImpl(
      videos: (json['data'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => VodModel.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
    );

Map<String, dynamic> _$$VodHomeListModelImplToJson(
        _$VodHomeListModelImpl instance) =>
    <String, dynamic>{
      'data': instance.videos,
    };

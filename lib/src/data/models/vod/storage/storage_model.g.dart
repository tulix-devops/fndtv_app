// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StorageModelImpl _$$StorageModelImplFromJson(Map<String, dynamic> json) =>
    _$StorageModelImpl(
      id: (json['id'] as num).toInt(),
      statusId: (json['statusId'] as num).toInt(),
      typeId: (json['typeId'] as num).toInt(),
      record: RecordModel.fromJson(json['record'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$StorageModelImplToJson(_$StorageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'statusId': instance.statusId,
      'typeId': instance.typeId,
      'record': instance.record,
    };

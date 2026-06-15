// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actor_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActorModelImpl _$$ActorModelImplFromJson(Map<String, dynamic> json) =>
    _$ActorModelImpl(
      id: (json['id'] as num).toInt(),
      storageRecordId: (json['storageRecordId'] as num).toInt(),
      storageRecordTypeId: (json['storageRecordTypeId'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      birthYear: (json['birthYear'] as num).toInt(),
    );

Map<String, dynamic> _$$ActorModelImplToJson(_$ActorModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'storageRecordId': instance.storageRecordId,
      'storageRecordTypeId': instance.storageRecordTypeId,
      'title': instance.title,
      'description': instance.description,
      'birthYear': instance.birthYear,
    };

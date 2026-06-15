// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserSubscriptionModelImpl _$$UserSubscriptionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UserSubscriptionModelImpl(
      id: (json['id'] as num).toInt(),
      status_id: (json['status_id'] as num?)?.toInt(),
      user_id: (json['user_id'] as num?)?.toInt(),
      expires_at: json['expires_at'] as String?,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$UserSubscriptionModelImplToJson(
        _$UserSubscriptionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status_id': instance.status_id,
      'user_id': instance.user_id,
      'expires_at': instance.expires_at,
      'created_at': instance.created_at?.toIso8601String(),
    };

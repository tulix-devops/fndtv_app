// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OnboardingModelImpl _$$OnboardingModelImplFromJson(
        Map<String, dynamic> json) =>
    _$OnboardingModelImpl(
      id: (json['id'] as num).toInt(),
      orderId: (json['orderId'] as num?)?.toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$$OnboardingModelImplToJson(
        _$OnboardingModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'orderId': instance.orderId,
      'name': instance.name,
      'description': instance.description,
    };

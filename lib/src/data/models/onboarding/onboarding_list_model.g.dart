// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OnboardingListModelImpl _$$OnboardingListModelImplFromJson(
        Map<String, dynamic> json) =>
    _$OnboardingListModelImpl(
      tabs: (json['data'] as List<dynamic>)
          .map((e) => OnboardingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$OnboardingListModelImplToJson(
        _$OnboardingListModelImpl instance) =>
    <String, dynamic>{
      'data': instance.tabs,
    };

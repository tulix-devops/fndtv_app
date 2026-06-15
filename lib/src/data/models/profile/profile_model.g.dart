// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileModelImpl _$$ProfileModelImplFromJson(Map<String, dynamic> json) =>
    _$ProfileModelImpl(
      email: json['email'] as String,
      subscribed: json['subscribed'] as bool,
      name: json['name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      imgName: json['imgName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      subscription: json['subscription'] == null
          ? UserSubscriptionModel.empty
          : UserSubscriptionModel.fromJson(
              json['subscription'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProfileModelImplToJson(_$ProfileModelImpl instance) =>
    <String, dynamic>{
      'email': instance.email,
      'subscribed': instance.subscribed,
      'name': instance.name,
      'lastName': instance.lastName,
      'imgName': instance.imgName,
      'phoneNumber': instance.phoneNumber,
      'subscription': instance.subscription,
    };

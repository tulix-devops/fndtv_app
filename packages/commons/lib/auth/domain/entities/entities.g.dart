// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerModelImpl _$$CustomerModelImplFromJson(Map<String, dynamic> json) =>
    _$CustomerModelImpl(
      id: (json['id'] as num).toInt(),
      statusId: (json['statusId'] as num?)?.toInt(),
      email: json['email'] as String,
      name: json['name'] as String?,
      lastName: json['lastName'] as String?,
      hasPaymentMethod: json['hasPaymentMethod'] as bool,
    );

_$LoginEntityImpl _$$LoginEntityImplFromJson(Map<String, dynamic> json) =>
    _$LoginEntityImpl(
      accessToken: json['accessToken'] as String,
      customer:
          CustomerModel.fromJson(json['customer'] as Map<String, dynamic>),
    );

_$SignUpEntityImpl _$$SignUpEntityImplFromJson(Map<String, dynamic> json) =>
    _$SignUpEntityImpl(
      accessToken: json['accessToken'] as String,
      customer:
          CustomerModel.fromJson(json['customer'] as Map<String, dynamic>),
    );

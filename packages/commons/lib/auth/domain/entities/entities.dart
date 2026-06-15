import 'package:freezed_annotation/freezed_annotation.dart';

// ignore: unused_import
import 'package:flutter/foundation.dart';

part 'entities.freezed.dart';
part 'entities.g.dart';

@Freezed(equal: false, copyWith: false, toJson: false)
class CustomerModel with _$CustomerModel {
  const factory CustomerModel({
    required int id,
    required int? statusId,
    required String email,
    required String? name,
    required String? lastName,
    required bool hasPaymentMethod,
  }) = _CustomerModel;

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);
}

@Freezed(equal: false, copyWith: false, toJson: false)
class LoginEntity with _$LoginEntity {
  const factory LoginEntity({
    required String accessToken,
    @JsonKey(includeToJson: false) required CustomerModel customer,
  }) = _LoginEntity;

  factory LoginEntity.fromJson(Map<String, dynamic> json) =>
      _$LoginEntityFromJson(json);
}

@Freezed(equal: false, copyWith: false, toJson: false)
class SignUpEntity with _$SignUpEntity {
  const factory SignUpEntity({
    required String accessToken,
    @JsonKey(includeToJson: false) required CustomerModel customer,
  }) = _SignUpEntity;

  factory SignUpEntity.fromJson(Map<String, dynamic> json) =>
      _$SignUpEntityFromJson(json);
}

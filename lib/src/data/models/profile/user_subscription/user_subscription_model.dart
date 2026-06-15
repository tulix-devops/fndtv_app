// ignore_for_file: non_constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_subscription_model.freezed.dart';
part 'user_subscription_model.g.dart';

@freezed
class UserSubscriptionModel with _$UserSubscriptionModel {
  const factory UserSubscriptionModel({
    required int id,
    int? status_id,
    int? user_id,
    String? expires_at,
    DateTime? created_at,
  }) = _UserSubscriptionModel;

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$UserSubscriptionModelFromJson(json);

  static const empty =
      UserSubscriptionModel(expires_at: '', id: 0, status_id: 0, user_id: 0);
}

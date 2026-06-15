import 'package:freezed_annotation/freezed_annotation.dart';

part 'cancel_subscription_model.freezed.dart';
part 'cancel_subscription_model.g.dart';

@freezed
class CancelSubscriptionModel with _$CancelSubscriptionModel {
  const factory CancelSubscriptionModel({
    @Default('') String payment,
  }) = _CancelSubscriptionModel;

  factory CancelSubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$CancelSubscriptionModelFromJson(json);
}

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/data.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String email,
    required bool subscribed,
    @Default('') String name,
    @Default('') String lastName,
    @Default('') String imgName,
    @Default('') String phoneNumber,
    @Default(UserSubscriptionModel.empty) UserSubscriptionModel subscription,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}

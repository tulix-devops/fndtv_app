import 'package:freezed_annotation/freezed_annotation.dart';

import 'onboarding_model.dart';

part 'onboarding_list_model.freezed.dart';
part 'onboarding_list_model.g.dart';

@freezed
class OnboardingListModel with _$OnboardingListModel {
  const factory OnboardingListModel({
    // ignore: invalid_annotation_target
    @JsonKey(name: 'data') required List<OnboardingModel> tabs,
  }) = _OnboardingListModel;

  factory OnboardingListModel.fromJson(Map<String, dynamic> json) =>
      _$OnboardingListModelFromJson(json);

  static const empty = OnboardingListModel(tabs: []);
}

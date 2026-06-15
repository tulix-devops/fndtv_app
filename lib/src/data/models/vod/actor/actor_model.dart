import 'package:freezed_annotation/freezed_annotation.dart';

part 'actor_model.freezed.dart';
part 'actor_model.g.dart';

@freezed
class ActorModel with _$ActorModel {
  const factory ActorModel({
    required int id,
    required int storageRecordId,
    required int storageRecordTypeId,
    required String title,
    required String description,
    required int birthYear,
  }) = _ActorModel;

  factory ActorModel.fromJson(Map<String, dynamic> json) =>
      _$ActorModelFromJson(json);
}

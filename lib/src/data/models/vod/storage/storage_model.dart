import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/models/vod/record/record_model.dart';

part 'storage_model.freezed.dart';
part 'storage_model.g.dart';

@freezed
class StorageModel with _$StorageModel {
  const factory StorageModel({
    required int id,
    required int statusId,
    required int typeId,
    required RecordModel record,
  }) = _StorageModel;

  factory StorageModel.fromJson(Map<String, dynamic> json) =>
      _$StorageModelFromJson(json);

  static const empty = StorageModel(
    id: 0,
    statusId: 0,
    typeId: 0,
    record: RecordModel.empty,
  );
}

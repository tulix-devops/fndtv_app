import 'package:freezed_annotation/freezed_annotation.dart';

part 'storage_record_model.freezed.dart';
part 'storage_record_model.g.dart';

@freezed
class StorageRecordModel with _$StorageRecordModel {
  const factory StorageRecordModel({
    required String? thumb,
    required String? banner,
    required String? poster,
    required String? trailer,
    required String? source,
  }) = _StorageRecordModel;

  factory StorageRecordModel.fromJson(Map<String, dynamic> json) =>
      _$StorageRecordModelFromJson(json);

  static const empty = StorageRecordModel(
    thumb: '',
    banner: '',
    poster: '',
    trailer: '',
    source: '',
  );
}

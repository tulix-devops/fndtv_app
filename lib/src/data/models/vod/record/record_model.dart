import 'package:freezed_annotation/freezed_annotation.dart';

part 'record_model.freezed.dart';
part 'record_model.g.dart';

@freezed
class RecordModel with _$RecordModel {
  const factory RecordModel({
    required String? thumb,
    required String? banner,
    required String? poster,
    required String? trailer,
    required String? source,
  }) = _RecordModel;

  factory RecordModel.fromJson(Map<String, dynamic> json) =>
      _$RecordModelFromJson(json);

  static const empty = RecordModel(
    thumb: '',
    banner: '',
    poster: '',
    trailer: '',
    source: '',
  );
}

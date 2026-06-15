// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/models/vod/vod_model.dart';

part 'vod_list_model.freezed.dart';
part 'vod_list_model.g.dart';

@freezed
class VodListModel with _$VodListModel {
  const factory VodListModel({
    @JsonKey(name: 'data') required List<VodModel> videos,
  }) = _VodListModel;

  factory VodListModel.fromJson(Map<String, dynamic> json) =>
      _$VodListModelFromJson(json);

  static const empty = VodListModel(videos: []);
}

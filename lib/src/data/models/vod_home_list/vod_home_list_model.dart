// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/models/vod/vod_model.dart';

part 'vod_home_list_model.freezed.dart';
part 'vod_home_list_model.g.dart';

@freezed
class VodHomeListModel with _$VodHomeListModel {
  const factory VodHomeListModel({
    @JsonKey(name: 'data') required Map<String, List<VodModel>> videos,
  }) = _VodHomeListModel;

  factory VodHomeListModel.fromJson(Map<String, dynamic> json) =>
      _$VodHomeListModelFromJson(json);
}

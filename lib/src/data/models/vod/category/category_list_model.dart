// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/models/vod/category/category_model.dart';

part 'category_list_model.freezed.dart';
part 'category_list_model.g.dart';

@freezed
class CategoryListModel with _$CategoryListModel {
  const factory CategoryListModel({
    @JsonKey(name: 'data') required List<CategoryModel> categories,
  }) = _CategoryListModel;

  factory CategoryListModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryListModelFromJson(json);

  static const empty = CategoryListModel(categories: []);
}

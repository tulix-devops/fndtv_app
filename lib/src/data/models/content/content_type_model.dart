import 'package:json_annotation/json_annotation.dart';

part 'content_type_model.g.dart';

@JsonSerializable()
class ContentTypeModel {
  final int id;
  final String title;
  final ContentTypeImagesModel? images;

  ContentTypeModel({
    required this.id,
    required this.title,
    this.images,
  });

  factory ContentTypeModel.fromJson(Map<String, dynamic> json) => _$ContentTypeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContentTypeModelToJson(this);
}

@JsonSerializable()
class ContentTypeImagesModel {
  final int id;
  @JsonKey(name: 'full_hd_images')
  final List<String>? fullHdImages;
  @JsonKey(name: 'hd_images')
  final List<String>? hdImages;

  ContentTypeImagesModel({
    required this.id,
    this.fullHdImages,
    this.hdImages,
  });

  factory ContentTypeImagesModel.fromJson(Map<String, dynamic> json) => _$ContentTypeImagesModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContentTypeImagesModelToJson(this);
}

@JsonSerializable()
class ContentTypeListModel {
  final List<ContentTypeModel> data;

  ContentTypeListModel({required this.data});

  factory ContentTypeListModel.fromJson(Map<String, dynamic> json) => _$ContentTypeListModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContentTypeListModelToJson(this);
}

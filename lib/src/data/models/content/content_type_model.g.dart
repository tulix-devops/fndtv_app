// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_type_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentTypeModel _$ContentTypeModelFromJson(Map<String, dynamic> json) =>
    ContentTypeModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      images: json['images'] == null
          ? null
          : ContentTypeImagesModel.fromJson(
              json['images'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ContentTypeModelToJson(ContentTypeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'images': instance.images,
    };

ContentTypeImagesModel _$ContentTypeImagesModelFromJson(
        Map<String, dynamic> json) =>
    ContentTypeImagesModel(
      id: (json['id'] as num).toInt(),
      fullHdImages: (json['full_hd_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      hdImages: (json['hd_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ContentTypeImagesModelToJson(
        ContentTypeImagesModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'full_hd_images': instance.fullHdImages,
      'hd_images': instance.hdImages,
    };

ContentTypeListModel _$ContentTypeListModelFromJson(
        Map<String, dynamic> json) =>
    ContentTypeListModel(
      data: (json['data'] as List<dynamic>)
          .map((e) => ContentTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ContentTypeListModelToJson(
        ContentTypeListModel instance) =>
    <String, dynamic>{
      'data': instance.data,
    };

import 'package:equatable/equatable.dart';

class DetailsModel extends Equatable {
  const DetailsModel({
    this.id,
    this.tagline,
    this.copyright,
    this.studio,
    this.sku,
    this.imdbId,
    this.productionYear,
    this.language,
  });
  final int? id;
  final String? tagline;
  final String? copyright;
  final String? studio;
  final String? sku;
  final String? imdbId;
  final String? productionYear;
  final String? language;

  factory DetailsModel.fromJson(Map<String, dynamic> json) => DetailsModel(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
        tagline: json['tagline'] as String?,
        copyright: json['copyright'] as String?,
        studio: json['studio'] as String?,
        sku: json['sku'] as String?,
        imdbId: json['imdbId'] as String?,
        productionYear: json['productionYear'] as String?,
        language: json['language'] as String?,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tagline': tagline,
      'copyright': copyright,
      'studio': studio,
      'sku': sku,
      'imdbId': imdbId,
      'productionYear': productionYear,
      'language': language,
    };
  }

  @override
  List<Object?> get props =>
      [id, tagline, copyright, studio, sku, imdbId, productionYear, language];

  static const empty = DetailsModel(
    id: null,
    tagline: null,
    copyright: null,
    studio: null,
    sku: null,
    imdbId: null,
    productionYear: null,
    language: null,
  );
}

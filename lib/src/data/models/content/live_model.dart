import 'package:equatable/equatable.dart';
import 'package:fndtv/src/data/models/content/images_model.dart';
import 'package:fndtv/src/data/models/content/source_model.dart';
import 'package:fndtv/src/data/models/content/details_model.dart';
import 'package:fndtv/src/data/models/content/seo_model.dart';

class ContentModelList extends Equatable {
  final int statusCode;
  final String message;
  final List<LiveModel> data;
  final PaginationLinks? links;
  final PaginationMeta? meta;

  const ContentModelList({
    required this.statusCode,
    required this.message,
    required this.data,
    this.links,
    this.meta,
  });

  factory ContentModelList.fromJson(Map<String, dynamic> json) {
    return ContentModelList(
      statusCode: json['statusCode'] as int? ?? 200,
      message: json['message'] as String? ?? '',
      data: List<LiveModel>.from(
        (json['data'] as List<dynamic>? ?? []).map((x) => LiveModel.fromJson(x)),
      ),
      links: json['links'] != null ? PaginationLinks.fromJson(json['links']) : null,
      meta: json['meta'] != null ? PaginationMeta.fromJson(json['meta']) : null,
    );
  }

  @override
  List<Object?> get props => [statusCode, message, data, links, meta];
}

class PaginationLinks extends Equatable {
  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  const PaginationLinks({this.first, this.last, this.prev, this.next});

  factory PaginationLinks.fromJson(Map<String, dynamic> json) {
    return PaginationLinks(
      first: json['first'] as String?,
      last: json['last'] as String?,
      prev: json['prev'] as String?,
      next: json['next'] as String?,
    );
  }

  @override
  List<Object?> get props => [first, last, prev, next];
}

class PaginationMeta extends Equatable {
  final int currentPage;
  final int from;
  final int lastPage;
  final int perPage;
  final int to;
  final int total;

  const PaginationMeta({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['currentPage'] as int? ?? 1,
      from: json['from'] as int? ?? 1,
      lastPage: json['lastPage'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? 50,
      to: json['to'] as int? ?? 1,
      total: json['total'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [currentPage, from, lastPage, perPage, to, total];
}

class LiveModel extends Equatable {
  final int id;
  final int? statusId;
  final int? productId;
  final int? parentId;
  final int typeId;
  final String type;
  final int? countryId;
  final int? season;
  final int? episode;
  final String title;
  final String? description;
  final DetailsModel? details;
  final SeoModel? seo;
  final ImagesModel images;
  final SourceModel sources;
  final List<dynamic> audiences;
  final dynamic product;
  final dynamic seasons;
  final dynamic attributes;
  final String? startsAt;
  final String? endsAt;
  final bool? isPermanent;
  final String? createdAt;
  final String? updatedAt;
  final bool live;
  final String? dvrUrl;

  const LiveModel({
    required this.id,
    this.statusId,
    this.productId,
    this.parentId,
    required this.typeId,
    required this.type,
    this.countryId,
    this.season,
    this.episode,
    required this.title,
    this.description,
    this.details,
    this.seo,
    required this.images,
    required this.sources,
    this.audiences = const [],
    this.product,
    this.seasons,
    this.attributes,
    this.startsAt,
    this.endsAt,
    this.isPermanent,
    this.createdAt,
    this.updatedAt,
    required this.live,
    this.dvrUrl,
  });

  factory LiveModel.fromJson(Map<String, dynamic> json) {
    return LiveModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      statusId: json['statusId'] != null ? int.tryParse(json['statusId'].toString()) : null,
      productId: json['productId'] != null ? int.tryParse(json['productId'].toString()) : null,
      parentId: json['parentId'] != null ? int.tryParse(json['parentId'].toString()) : null,
      typeId: int.tryParse(json['typeId'].toString()) ?? 0,
      type: json['type'] as String? ?? '',
      countryId: json['countryId'] != null ? int.tryParse(json['countryId'].toString()) : null,
      season: json['season'] != null ? int.tryParse(json['season'].toString()) : null,
      episode: json['episode'] != null ? int.tryParse(json['episode'].toString()) : null,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      details: json['details'] != null ? DetailsModel.fromJson(json['details']) : null,
      seo: json['seo'] != null ? SeoModel.fromJson(json['seo']) : null,
      images: json['images'] != null 
          ? ImagesModel.fromJson(json['images']) 
          : ImagesModel.empty,
      sources: json['sources'] != null 
          ? SourceModel.fromJson(json['sources']) 
          : SourceModel.empty,
      audiences: json['audiences'] as List<dynamic>? ?? [],
      product: json['product'],
      seasons: json['seasons'],
      attributes: json['attributes'],
      startsAt: json['startsAt'] as String?,
      endsAt: json['endsAt'] as String?,
      isPermanent: json['isPermanent'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      live: json['live'] as bool? ?? false,
      dvrUrl: json['dvr_url'] as String?,
    );
  }

  // Helper method to check if DVR is available
  bool get hasDvr => dvrUrl != null && dvrUrl!.isNotEmpty;

  // Helper method to get tagline from details
  String? get tagline => details?.tagline;

  // Helper to check if this is the "FNDTV - Live/DVR" main channel
  bool get isMainChannel => title.contains('FNDTV') && title.contains('Live');

  /// True for the Chicago/US time-shift variant (detected from stream URL/title).
  bool get isTimeShift =>
      (sources.primary ?? sources.hls ?? '').contains('tshift') ||
      title.contains('(US');

  /// Programs parsed from the `seasons` map — the EPG / DVR schedule.
  List<LiveModel> get scheduleItems {
    final dynamic s = seasons;
    final result = <LiveModel>[];
    if (s is Map) {
      for (final value in s.values) {
        if (value is List) {
          for (final item in value) {
            if (item is Map<String, dynamic>) {
              result.add(LiveModel.fromJson(item));
            }
          }
        }
      }
    }
    return result;
  }

  @override
  String toString() {
    return 'LiveModel(id: $id, title: $title, type: $type, live: $live)';
  }

  @override
  List<Object?> get props => [
        id,
        statusId,
        productId,
        parentId,
        typeId,
        type,
        countryId,
        season,
        episode,
        title,
        description,
        details,
        seo,
        images,
        sources,
        audiences,
        product,
        seasons,
        attributes,
        startsAt,
        endsAt,
        isPermanent,
        createdAt,
        updatedAt,
        live,
        dvrUrl,
      ];
}

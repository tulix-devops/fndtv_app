import 'package:commons/http/data/models/meta_links_model.dart';
import 'package:equatable/equatable.dart';

class PaginationMetaModel extends Equatable {
  const PaginationMetaModel({
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.links,
    required this.perPage,
    required this.to,
    required this.total,
  });

  final int currentPage;
  final int? from;
  final int lastPage;
  final MetaLinksModel links;
  final int perPage;
  final int? to;
  final int total;

  factory PaginationMetaModel.fromJson(Map<String, dynamic> json) {
    return PaginationMetaModel(
      currentPage: (json['currentPage'] as int).toInt(),
      from: (json['from'] as int?)?.toInt(),
      lastPage: (json['lastPage'] as int).toInt(),
      links: MetaLinksModel.fromJson(json['links'] as Map<String, dynamic>),
      perPage: (json['perPage'] as int).toInt(),
      to: (json['to'] as int?)?.toInt(),
      total: (json['total'] as int).toInt(),
    );
  }

  static const empty = PaginationMetaModel(
      currentPage: 0,
      from: 0,
      lastPage: 0,
      links: MetaLinksModel.empty,
      perPage: 0,
      to: 0,
      total: 0);

  @override
  List<Object?> get props =>
      [currentPage, from, lastPage, links, perPage, to, total];
}

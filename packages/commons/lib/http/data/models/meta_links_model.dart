import 'package:equatable/equatable.dart';

class MetaLinksModel extends Equatable {
  const MetaLinksModel({required this.links});

  final Map<String, String?> links;

  factory MetaLinksModel.fromJson(Map<String, dynamic> json) {
    final linksMap = json.map((key, value) => MapEntry(key, value as String?));
    return MetaLinksModel(links: linksMap);
  }

  @override
  List<Object?> get props => [links];

  static const empty = MetaLinksModel(links: {});
}

import 'package:equatable/equatable.dart';

class PodcastModel extends Equatable {
  final int id;
  final String title;
  final String logo;
  final String streamUrl;

  const PodcastModel({
    required this.id,
    required this.title,
    required this.logo,
    required this.streamUrl,
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    return PodcastModel(
      id: json['id'],
      title: json['title'],
      logo: json['logo'],
      streamUrl: json['streamUrl'],
    );
  }

  @override
  // TODO: implement props
  List<Object?> get props => [id, title, logo, streamUrl];
}

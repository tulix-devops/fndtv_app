import 'package:equatable/equatable.dart';
import 'package:fndtv/src/data/models/channel/podcast_model.dart';

class PodcastListModel extends Equatable {
  final List<PodcastModel> podcasts;

  const PodcastListModel({required this.podcasts});

  factory PodcastListModel.fromJson(Map<String, dynamic> json) {
    return PodcastListModel(
      podcasts: (json['data'] as List<dynamic>)
          .map((x) => PodcastModel.fromJson(x))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [podcasts];
}

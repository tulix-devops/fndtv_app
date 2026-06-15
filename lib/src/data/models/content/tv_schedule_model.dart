import 'package:equatable/equatable.dart';

class DvrMapModel extends Equatable {
  final Map<String, List<TvScheduleModel>> schedulesByDate;

  const DvrMapModel({
    required this.schedulesByDate,
  });

  factory DvrMapModel.fromJson(Map<String, dynamic> json) {
    final Map<String, List<TvScheduleModel>> schedulesByDate = {};

    final data = json['data'] as Map<String, dynamic>;

    data.forEach((date, schedulesList) {
      final List<dynamic> schedulesData = schedulesList as List<dynamic>;
      schedulesByDate[date] = schedulesData
          .map((schedule) =>
              TvScheduleModel.fromJson(schedule as Map<String, dynamic>))
          .toList();
    });

    return DvrMapModel(schedulesByDate: schedulesByDate);
  }

  @override
  List<Object?> get props => [schedulesByDate];
}

class TvScheduleModel extends Equatable {
  final int id;
  final int ogStart;
  final String start;
  final String epgId;
  final String end;
  final String name;
  final String link;
  final String thumbnail;
  final String description;
  final bool isFuture;

  const TvScheduleModel({
    required this.id,
    required this.description,
    required this.start,
    required this.ogStart,
    required this.epgId,
    required this.end,
    required this.name,
    required this.link,
    required this.thumbnail,
    required this.isFuture,
  });

  factory TvScheduleModel.fromJson(Map<String, dynamic> json) {
    return TvScheduleModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      start: json['start'] as String? ?? '',
      description: json['description'] as String? ?? '',
      end: json['end'] as String? ?? '',
      ogStart: json['ogStart'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      epgId: json['epgId'] as String? ?? '',
      link: json['link'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      isFuture: json['isFuture'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, start, end, name, link, thumbnail];
}

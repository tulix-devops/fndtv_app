import 'package:equatable/equatable.dart';
import 'package:fndtv/src/data/models/content/tv_schedule_model.dart';

class ScheduleModel extends Equatable {
  final Map<String, List<TvScheduleModel>> data;

  const ScheduleModel({required this.data});

  @override
  List<Object?> get props => [data];

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((e) => TvScheduleModel.fromJson(e))
            .toList(),
      ),
    );

    return ScheduleModel(data: data);
  }
}

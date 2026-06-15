import 'package:equatable/equatable.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/tv_schedule_model.dart';

class ChannelModel extends Equatable {
  const ChannelModel({required this.channel, required this.dvr});

  final LiveModel? channel;
  final List<TvScheduleModel> dvr;

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      channel:
          json["channel"] == null ? null : LiveModel.fromJson(json["channel"]),
      dvr: json["dvr"] == null
          ? []
          : List<TvScheduleModel>.from(
              json["dvr"]!.map((x) => TvScheduleModel.fromJson(x)),
            ),
    );
  }

  @override
  List<Object?> get props => [channel, dvr];
}

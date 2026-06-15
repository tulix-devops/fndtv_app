import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:fndtv/src/data/data.dart';

part 'vod_model.freezed.dart';
part 'vod_model.g.dart';

@freezed
class VodModel with _$VodModel {
  const factory VodModel({
    required int id,
    required int? statusId,
    required int? typeId,
    required int? seasons,
    required int? episodesCount,
    required String type,
    required int? accessTypeId,
    required int? countryId,
    required int? storageRecordId,
    required int? storageRecordTypeId,
    required StorageRecordModel? storageRecord,
    required StorageModel? storage,
    required String title,
    required String description,
    required int? productionYear,
    required List<ActorModel> actors,
    required List<EpisodeModel> episodes,
    required Map<String, List<EpisodeModel>>? groupedSeasons,
    required List<TagModel> tags,
    required List<CategoryModel> categories,
    required CountryModel? country,
  }) = _VodModel;

  factory VodModel.fromJson(Map<String, dynamic> json) =>
      _$VodModelFromJson(json);

  static const empty = VodModel(
    id: 0,
    statusId: 0,
    episodesCount: null,
    typeId: 0,
    seasons: null,
    type: '',
    accessTypeId: 0,
    storageRecord: StorageRecordModel.empty,
    storageRecordId: 0,
    storageRecordTypeId: 0,
    storage: StorageModel.empty,
    actors: [],
    episodes: [],
    groupedSeasons: null,
    categories: [],
    country: CountryModel.empty,
    countryId: 0,
    description: '',
    tags: [],
    productionYear: 0,
    title: '',
  );
}

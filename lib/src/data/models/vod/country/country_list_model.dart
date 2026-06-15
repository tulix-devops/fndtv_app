// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fndtv/src/data/models/vod/country/country_model.dart';

part 'country_list_model.freezed.dart';
part 'country_list_model.g.dart';

@freezed
class CountryListModel with _$CountryListModel {
  const factory CountryListModel({
    @JsonKey(name: 'data') required List<CountryModel> countries,
  }) = _CountryListModel;

  factory CountryListModel.fromJson(Map<String, dynamic> json) =>
      _$CountryListModelFromJson(json);

  static const empty = CountryListModel(countries: []);
}

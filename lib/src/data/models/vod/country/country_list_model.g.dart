// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'country_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CountryListModelImpl _$$CountryListModelImplFromJson(
        Map<String, dynamic> json) =>
    _$CountryListModelImpl(
      countries: (json['data'] as List<dynamic>)
          .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$CountryListModelImplToJson(
        _$CountryListModelImpl instance) =>
    <String, dynamic>{
      'data': instance.countries,
    };

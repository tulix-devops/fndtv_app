import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_error_model.freezed.dart';

@Freezed(
  copyWith: false,
  equal: false,
)
class ValidationErrorModel with _$ValidationErrorModel {
  const ValidationErrorModel._();

  const factory ValidationErrorModel({
    required String field,
    required List<String> errors,
  }) = _ValidationErrorModel;

  static List<ValidationErrorModel> mapper(Map<String, dynamic> list) {
    return list.entries.map((MapEntry<String, dynamic> e) {
      return ValidationErrorModel(
        field: e.key,
        errors: List<String>.from(e.value as List<dynamic>),
      );
    }).toList();
  }
}

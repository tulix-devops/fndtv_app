// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'validation_error_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ValidationErrorModel {
  String get field => throw _privateConstructorUsedError;
  List<String> get errors => throw _privateConstructorUsedError;
}

/// @nodoc

class _$ValidationErrorModelImpl extends _ValidationErrorModel {
  const _$ValidationErrorModelImpl(
      {required this.field, required final List<String> errors})
      : _errors = errors,
        super._();

  @override
  final String field;
  final List<String> _errors;
  @override
  List<String> get errors {
    if (_errors is EqualUnmodifiableListView) return _errors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_errors);
  }

  @override
  String toString() {
    return 'ValidationErrorModel(field: $field, errors: $errors)';
  }
}

abstract class _ValidationErrorModel extends ValidationErrorModel {
  const factory _ValidationErrorModel(
      {required final String field,
      required final List<String> errors}) = _$ValidationErrorModelImpl;
  const _ValidationErrorModel._() : super._();

  @override
  String get field;
  @override
  List<String> get errors;
}

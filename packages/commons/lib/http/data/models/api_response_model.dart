import 'package:commons/http/data/models/pagination_links_model.dart';
import 'package:commons/http/data/models/pagination_meta_model.dart';
import 'package:commons/http/data/models/validation_error_model.dart';

sealed class ResponseModel<T> {
  const ResponseModel();
}

class SuccessModel<T> extends ResponseModel<T> {
  SuccessModel({
    required this.data,
    required this.statusCode,
    required this.message,
  });
  final T data;
  final int statusCode;
  final String message;
}

class FailureModel<T> extends ResponseModel<T> {
  const FailureModel({
    required this.errorStackTrace,
    required this.statusCode,
    required this.message,
  });

  final String errorStackTrace;
  final int statusCode;
  final String message;
}

class ValidationFailureModel<T> extends ResponseModel<T> {
  final List<ValidationErrorModel> validationErrors;
  final String errorStackTrace;
  final int statusCode;
  final String message;

  const ValidationFailureModel({
    required this.validationErrors,
    required this.errorStackTrace,
    required this.statusCode,
    required this.message,
  });
}

class ModelNotFoundFailureModel<T> extends ResponseModel<T> {
  const ModelNotFoundFailureModel({
    required this.errorStackTrace,
    required this.statusCode,
    required this.message,
  });

  final String errorStackTrace;
  final int statusCode;
  final String message;
}

class AuthenticationFailureModel<T> extends ResponseModel<T> {
  const AuthenticationFailureModel({
    required this.errorStackTrace,
    required this.statusCode,
    required this.message,
  });

  final String errorStackTrace;
  final int statusCode;
  final String message;
}

class PaginatedModel<T> extends ResponseModel<T> {
  PaginatedModel({
    required this.data,
    required this.statusCode,
    required this.meta,
    required this.links,
    required this.message,
  });

  final T data;
  final PaginationMetaModel meta;
  final PaginationLinksModel links;
  final int statusCode;
  final String message;
}

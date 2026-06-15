import 'dart:convert';
import 'dart:io';

// ignore: unused_import
import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:commons/http/data/models/pagination_links_model.dart';
import 'package:commons/http/data/models/meta_links_model.dart';
import 'package:commons/http/data/models/pagination_meta_model.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

typedef DataMapper<T> = T Function(Map<String, dynamic>)?;

/// ApiCallHandler
/// Headers are used for content-type headers and etc...
/// Body is params that we pass to functions for request body
/// DataMapper is for mapping response data to Entity
/// Url is for endpoint
/// HttpMethod is for request method
/// CustomHTTPClient is for custom http client which is used for auth token injection
mixin ApiCallHandler {
  /// Response format from backend
  /// statusCode: int
  /// message: String
  /// data: dynamic
  /// errorStackTrace: String // if it unsuccessful
  /// validationErrors: Map<String, dynamic> // if validation fails
  Future<ResponseModel<T>> handleApiCall<T>({
    Map<String, String> headers = const {
      'Accept-Encoding': 'gzip, deflate, br'
    },
    Object? body,
    DataMapper<T> dataMapper,
    required String url,
    required HttpMethod httpMethod,
    required CustomHTTPClient client,
  }) async {
    try {
      final http.Response response = await httpMethod.toRequest(
        url,
        body,
        client: client,
        headers: headers,
      );
      final Map<String, dynamic> json = jsonDecode(response.body);

      final statusCode = json['statusCode'] as int?;
      final message = json['message'] as String;

      return _handleResponseModel<T>(
        json: json,
        dataMapper: dataMapper,
        statusCode: statusCode ?? 401,
        message: message,
      );
    } on SocketException catch (e) {
      logger.e(e);
      print('URL $url');

      return FailureModel(
        errorStackTrace: e.toString(),
        statusCode: 0,
        message: 'Internet connection failed',
      );
    } catch (e) {
      logger.e(e);
      print('URL $url');

      return FailureModel(
        errorStackTrace: e.toString(),
        statusCode: 0,
        message: 'Unknown Failure',
      );
    }
  }

  ResponseModel<T> _handleResponseModel<T>({
    required Map<String, dynamic> json,
    required DataMapper<T> dataMapper,
    required int statusCode,
    required String message,
  }) {
    // logger.i(json);

    final String stackTrace = (json['errorStackTrace'] ?? '') as String;

    return switch (statusCode) {
      HttpStatus.partialContent => _handlePaginationModel(
          json: json,
          dataMapper: dataMapper,
          statusCode: statusCode,
          message: message,
        ),
      HttpStatus.ok => _handleSuccessModel(
          json: json,
          dataMapper: dataMapper,
          statusCode: statusCode,
          message: message,
        ),
      HttpStatus.unprocessableEntity => ValidationFailureModel(
          validationErrors: ValidationErrorModel.mapper(
            json['validationErrors'] as Map<String, dynamic>,
          ),
          errorStackTrace: stackTrace,
          statusCode: statusCode,
          message: message,
        ),
      HttpStatus.notFound => ModelNotFoundFailureModel(
          errorStackTrace: stackTrace,
          statusCode: statusCode,
          message: message,
        ),
      HttpStatus.unauthorized => AuthenticationFailureModel(
          errorStackTrace: stackTrace,
          statusCode: statusCode,
          message: message,
        ),
      HttpStatus.internalServerError || _ => FailureModel(
          errorStackTrace: stackTrace,
          statusCode: statusCode,
          message: message,
        )
    };
  }

  SuccessModel<T> _handleSuccessModel<T>({
    required Map<String, dynamic> json,
    required DataMapper<T> dataMapper,
    required int statusCode,
    required String message,
  }) {
    dynamic data = json['data'];

    //TODO not a best Solution Rewrite it into more dynamic way
    if (data is bool && data == true) {
      return SuccessModel<T>(
        data: data as T,
        statusCode: statusCode,
        message: message,
      );
    }

    try {
      bool isMapList =
          (data is Map<String, dynamic> && data.values.first is List<dynamic>);

      if (data is List<dynamic> || isMapList) {
        data = json;
      }

      return SuccessModel<T>(
        data: dataMapper == null ? data as T : dataMapper(data),
        statusCode: statusCode,
        message: message,
      );
    } catch (e) {
      logger.e(e);
    }
    return SuccessModel<T>(
      data: dataMapper == null ? data as T : dataMapper(data),
      statusCode: statusCode,
      message: message,
    );
  }

  PaginatedModel<T> _handlePaginationModel<T>({
    required Map<String, dynamic> json,
    required DataMapper<T> dataMapper,
    required int statusCode,
    required String message,
  }) {
    var data = json['data'];

    bool isMapList =
        (data is Map<String, dynamic> && data.values.first is List<dynamic>);

    if (data is List<dynamic> || isMapList) {
      data = json;
    }

    final PaginationMetaModel meta = PaginationMetaModel.fromJson(
      json['meta'],
    );

    final PaginationLinksModel links = PaginationLinksModel.fromJson(
      json['links'],
    );

    return PaginatedModel<T>(
      data: dataMapper == null ? data as T : dataMapper(data),
      statusCode: statusCode,
      message: message,
      links: links,
      meta: meta,
    );
  }
}

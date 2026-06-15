import 'dart:convert';
import 'dart:io';

import 'package:commons/commons.dart';
import 'package:fndtv/src/data/models/content/content_type_model.dart';
import 'package:fndtv/src/data/models/content/live_model.dart';
import 'package:fndtv/src/data/models/content/dvr_item_model.dart';

final class ContentDataSource with ApiCallHandler {
  const ContentDataSource(this._client);

  final CustomHTTPClient _client;

  Future<ResponseModel<ContentTypeListModel>> getContentTypeList() {
    return handleApiCall<ContentTypeListModel>(
      url: APIList.getContentTypeList(),
      httpMethod: HttpMethod.get,
      dataMapper: ContentTypeListModel.fromJson,
      client: _client,
    );
  }

  Future<ResponseModel<ContentModelList>> getContents({required int contentType, int? page}) {
    return handleApiCall<ContentModelList>(
      url: APIList.getContent(contentType: contentType, page: page),
      httpMethod: HttpMethod.get,
      dataMapper: ContentModelList.fromJson,
      client: _client,
    );
  }

  Future<ResponseModel<DvrDataModel>> getDvrData({required String url}) async {
    try {
      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == HttpStatus.ok) {
        final dynamic decoded = jsonDecode(response.body);

        late final DvrDataModel dvr;

        if (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>) {
          final List<dynamic> dataList = decoded['data'] as List<dynamic>;
          
          // Filter out live items and parse the rest
          final items = dataList
              .where((item) => item is Map<String, dynamic> && item['islive'] != 1)
              .map((item) => DvrItemModel.fromJson(item as Map<String, dynamic>))
              .toList();
          
          dvr = DvrDataModel(items: items);
        } else if (decoded is List<dynamic>) {
          // Handle direct list response
          final items = decoded
              .where((item) => item is Map<String, dynamic> && item['islive'] != 1)
              .map((item) => DvrItemModel.fromJson(item as Map<String, dynamic>))
              .toList();
          
          dvr = DvrDataModel(items: items);
        } else {
          return FailureModel(
            statusCode: response.statusCode,
            message: 'Unexpected response format',
            errorStackTrace: response.body,
          );
        }

        final message = (decoded is Map && decoded['status'] != null) ? decoded['status'].toString() : 'OK';

        return SuccessModel<DvrDataModel>(
          data: dvr,
          statusCode: response.statusCode,
          message: message,
        );
      }

      String message = 'Request failed';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['message'] != null) {
          message = body['message'].toString();
        }
      } catch (_) {}

      return FailureModel(
        statusCode: response.statusCode,
        message: message,
        errorStackTrace: response.body,
      );
    } on SocketException catch (e) {
      return FailureModel(
        errorStackTrace: e.toString(),
        statusCode: 0,
        message: 'Internet connection failed',
      );
    } catch (e, stackTrace) {
      return FailureModel(
        errorStackTrace: stackTrace.toString(),
        statusCode: 0,
        message: 'Unknown Failure: ${e.toString()}',
      );
    }
  }
}

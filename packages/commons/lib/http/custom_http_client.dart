import 'dart:io';

import 'package:app_logger/app_logger.dart';
import 'package:commons/commons.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Custom Http Client
/// Params :[GetAuthTokenUseCase]
/// Resets at 100 requests and gets new internal client
/// Adds Auth and Json headers
class CustomHTTPClient extends http.BaseClient {
  http.Client _client = http.Client();

  /// number of requests send will reset http client on 100.
  int _count = 0;

  CustomHTTPClient(this._dataSource);

  final LocalAuthDataSource _dataSource;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.headers['Authorization'] case null || '') {
      final String token = await _dataSource.getToken() ?? '';

      if (kDebugMode) {
        logger.d('Token: $token');
      }

      request.headers['Authorization'] = 'Bearer $token';
    }

    /// Set Json Content-type if formdata hea Gder is not presentF
    if (request.headers['Content-type']
        case null || (!= 'multipart/form-data')) {
      request.headers['Content-type'] = 'application/json';
    }

    request.headers['Accept'] = 'application/json';

    _count++;

    return _getClient().send(request);
  }

  http.Client _getClient() {
    if (_count < 100) return _client;

    return _client = http.Client();
  }

  http.MultipartRequest formDataRequest(Uri url, dynamic params) {
    http.MultipartRequest request = http.MultipartRequest('POST', url);

    if (params['file'] != null) {
      File file = File(params['file']);

      request.files.add(
        http.MultipartFile(
            'file', file.readAsBytes().asStream(), file.lengthSync(),
            filename: file.path.split('/').last),
      );
    }

    Map<String, String> fields = {};

    params.forEach((key, value) {
      if (key != 'file' && value != null) {
        fields[key] = value;
      }
    });

    request.fields.addAll(fields);

    return request;
  }
}

class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

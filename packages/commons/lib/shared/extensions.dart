// ignore: depend_on_referenced_packages
import 'package:flutter/cupertino.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:commons/commons.dart';

typedef InputModel = ({String? value, String? error});

extension TypeToRequest on HttpMethod {
  /// IsFormData for multipart/form-data header
  Future<http.Response> toRequest(String url, Object? body,
      {Map<String, String>? headers, required CustomHTTPClient client}) async {
    final Uri uri = Uri.parse(url);

    switch (this) {
      case HttpMethod.get:
        return client.get(uri);
      case HttpMethod.post:
        return client.post(uri, body: body, headers: headers);
      case HttpMethod.postFormData:
        final response = await client.send(client.formDataRequest(uri, body));

        return http.Response.fromStream(response);
      case HttpMethod.put:
        return client.put(uri, headers: headers);
      case HttpMethod.delete:
        return client.delete(uri);
    }
  }
}

extension StatusExtension on Status {
  bool get isLoading => this == Status.loading;
  bool get isInitial => this == Status.initial;
  bool get isSuccess => this == Status.success;
  bool get isFailure => this == Status.failure;
  bool get isServerFailure => this == Status.serverFailure;
  bool get isFinished => this == Status.finished;
  bool get isNavigatingWithClick => this == Status.navigatingWithClick;
  bool get isAuthenticationFailure => this == Status.authenticationFailure;
}

extension NavigationExtensions on BuildContext {
  void push(
    Widget page,
  ) {
    Navigator.of(this).push(
      CupertinoPageRoute(
        builder: (context) => page,
      ),
    );
  }

  void pushNamed(String routePath, {Map<String, dynamic>? extra}) {
    Navigator.of(this).pushNamed(
      routePath,
      arguments: extra,
    );
  }

  void pushReplacementNamed(String routePath, {Map<String, dynamic>? extra}) {
    Navigator.of(this).pushReplacementNamed(routePath, arguments: extra);
  }

  bool canPop() {
    return Navigator.of(this).canPop();
  }

  void popUntil({required bool Function(Route<dynamic>) predicate}) {
    Navigator.popUntil(this, predicate);
  }

  void pop() {
    Navigator.pop(this);
  }
}

extension DurationExtension on Duration? {
  String formatDuration() {
    if (this != null) {
      String minutes = this!.inMinutes.toString().padLeft(2, '0');
      String seconds = (this!.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }

    return '00:00';
  }

  String formatCountdown(Duration maxDuration) {
    if (this != null) {
      Duration remainingTime = (maxDuration - this!);
      String minutes = remainingTime.inMinutes.toString().padLeft(2, '0');
      String seconds =
          (remainingTime.inSeconds % 60).toString().padLeft(2, '0');
      return '$minutes:$seconds';
    }
    return '00:00';
  }
}

extension MediaQueryExtensions on BuildContext {
  bool get isTv {
    final size = MediaQuery.of(this).size;

    final width = size.width;
    final height = size.height;
    final diagonal = sqrt((width * width + height * height));

    final isLargeScreen = width >= 720;
    final isDiagonalLarge = diagonal >= 1000;

    return isLargeScreen && isDiagonalLarge;
  }
}

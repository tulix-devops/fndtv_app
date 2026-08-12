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

/// Latched once at startup (see `main.dart`) when the PLATFORM says this is a
/// TV — Android TV declares the leanback feature, Fire TV declares
/// `amazon.hardware.fire_tv`, and the stb flavor is always a TV.
///
/// Needed because the size heuristic below lies on real TV hardware: a Fire TV
/// stick rendering 1280×720 at xhdpi density has a LOGICAL width of only
/// 640 px, which reads as "phone" and served the mobile layout on a
/// television. The platform check cannot be done here synchronously, hence the
/// latch.
bool _platformIsTv = false;

void markPlatformAsTv() => _platformIsTv = true;

extension MediaQueryExtensions on BuildContext {
  bool get isTv {
    if (_platformIsTv) return true;

    // Size fallback: keeps the TV layout on big windows (desktop preview,
    // landscape tablets) and on AOSP boxes that declare no TV feature at all.
    final size = MediaQuery.of(this).size;

    final width = size.width;
    final height = size.height;
    final diagonal = sqrt((width * width + height * height));

    final isLargeScreen = width >= 720;
    final isDiagonalLarge = diagonal >= 1000;

    return isLargeScreen && isDiagonalLarge;
  }
}

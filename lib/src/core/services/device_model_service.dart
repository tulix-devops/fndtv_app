import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/bloc/bloc.dart';

class DeviceModelService {
  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  String _deviceModel = '';

  /// Hardware model reported at provisioning and check-in — e.g. `X88 Pro 14`.
  ///
  /// This used to return `androidInfo.id`, which is `Build.ID`: the BUILD
  /// fingerprint id (`BT2A.260319.001`), identical across every box of a batch
  /// and the very same value the serial already falls back to. So the fleet
  /// records carried a build id in the model column and the console could not
  /// answer "which hardware is failing" at all — which is exactly the question
  /// when only a few boxes misbehave.
  ///
  /// `Build.MODEL` is the marketing name and needs no permission. The build id
  /// is still useful for spotting a bad firmware revision, so it is kept
  /// alongside rather than dropped.
  Future<String> get deviceModel async {
    if (_deviceModel.isNotEmpty) return _deviceModel;

    if (Platform.isIOS) {
      _deviceModel = (await _plugin.iosInfo).identifierForVendor.toString();
      return _deviceModel;
    }

    final info = await _plugin.androidInfo;
    final model = info.model.trim();
    final buildId = info.id.trim();
    _deviceModel = switch ((model.isNotEmpty, buildId.isNotEmpty)) {
      (true, true) => '$model ($buildId)',
      (true, false) => model,
      _ => buildId,
    };
    return _deviceModel;
  }

  bool isOrientationPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  WidgetStateProperty<Color?> stuff(BuildContext context) {
    return WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
      if (states.contains(WidgetState.focused)) {
        return Theme.of(context).focusColor;
      }
      return null;
    });
  }
}

import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fndtv/src/index.dart';
import 'package:fndtv/src/bloc/bloc.dart';

class DeviceModelService {
  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  String _deviceModel = '';

  Future<String> get deviceModel async {
    if (_deviceModel.isNotEmpty) return _deviceModel;

    _deviceModel = Platform.isIOS
        ? (await _plugin.iosInfo).identifierForVendor.toString()
        : (await _plugin.androidInfo).id;

    String cleanDeviceModel = _deviceModel.replaceAll('.', '');
    _deviceModel = cleanDeviceModel;
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

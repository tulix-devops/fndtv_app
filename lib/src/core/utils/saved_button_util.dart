import 'package:ui_kit/ui_kit.dart';

class SavedButtonModel {
  SavedButtonModel({
    required bool isVideoSaved,
  })  : label = isVideoSaved ? 'Saved' : 'Save',
        icon = isVideoSaved ? Assets.checkMark : Assets.plus,
        isOutlined = !isVideoSaved;

  final String label;

  final String icon;

  final bool isOutlined;
}

class SavedButtonUtil {
  SavedButtonUtil._();

  static SavedButtonModel getModel(bool isVideoSaved) {
    return SavedButtonModel(
      isVideoSaved: isVideoSaved,
    );
  }
}

import 'package:commons/shared/enums.dart';

class VideoModel {
  const VideoModel({
    required this.link,
    required this.isLive,
    required this.contentType,
  });
  final String link;
  final bool isLive;
  final ContentType contentType;
}

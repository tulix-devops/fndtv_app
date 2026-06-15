import 'package:equatable/equatable.dart';

const String defaultPosterImage =
    'https://wchupload.tulix.net/storage/etc/no-poster-found.png';

class ImagesModel extends Equatable {
  const ImagesModel({
    required this.poster,
    required this.banner,
    required this.thumbnail,
  });
  final String? poster;
  final String? banner;
  final String? thumbnail;

  factory ImagesModel.fromJson(Map<String, dynamic> json) {
    return ImagesModel(
      poster: json['poster'] as String?,
      banner: json['banner'] as String?,
      thumbnail: json['thumbnail'] as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {'poster': poster, 'banner': banner, 'thumbnail': thumbnail};
  }

  String getPoster() {
    final List<String?> images = [poster, thumbnail, banner];

    return _getByPriority(images);
  }

  String getBanner() {
    final List<String?> images = [banner, poster, thumbnail];

    return _getByPriority(images);
  }

  String getThumbnail() {
    final List<String?> images = [thumbnail, poster, banner];

    return _getByPriority(images);
  }

  String _getByPriority(List<String?> images) {
    for (final image in images) {
      if (_isValidImage(image)) return image!;
    }

    return defaultPosterImage;
  }

  bool _isValidImage(String? url) {
    return url != null && url.isNotEmpty && url.contains('https');
  }

  @override
  List<Object?> get props => [poster, banner, thumbnail];

  static const empty = ImagesModel(
    poster: defaultPosterImage,
    banner: defaultPosterImage,
    thumbnail: defaultPosterImage,
  );
}

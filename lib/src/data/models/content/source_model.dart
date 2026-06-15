import 'package:equatable/equatable.dart';

class SourceModel extends Equatable {
  const SourceModel({
    this.id,
    this.primary,
    this.secondary,
    this.trailer,
    this.hls,
    this.dash,
    this.file,
  });
  final int? id;
  final String? primary;
  final String? secondary;
  final String? trailer;
  final String? hls;
  final String? dash;
  final String? file;

  factory SourceModel.fromJson(Map<String, dynamic> json) => SourceModel(
        id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
        primary: json['primary'] as String?,
        secondary: json['secondary'] as String?,
        trailer: json['trailer'] as String?,
        hls: json['hls'] as String?,
        dash: json['dash'] as String?,
        file: json['file'] as String?,
      );

  Map<String, dynamic> toJson() {
    final data = {
      'primary': primary,
      'secondary': secondary,
      'trailer': trailer,
      'hls': hls,
      'dash': dash,
      'file': file,
    };

    return data;
  }

  String? getPreferredVideoSource() {
    final sources = [primary, secondary, file, hls, dash];
    for (final source in sources) {
      if (isValidUrl(source)) {
        return source;
      }
    }
    return null;
  }

  bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http');
  }

  @override
  List<Object?> get props => [id, primary, secondary, trailer, hls, dash, file];

  static const empty = SourceModel(
    id: null,
    primary: null,
    secondary: null,
    trailer: null,
    hls: null,
    dash: null,
    file: null,
  );
}

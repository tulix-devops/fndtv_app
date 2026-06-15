import 'package:equatable/equatable.dart';

class AdDetails extends Equatable {
  final int id;
  final int statusId;
  final String? title;
  final String? description;
  final String? vast;
  final String? file;
  final String? poster;

  const AdDetails({
    required this.id,
    required this.statusId,
    this.title,
    this.description,
    this.vast,
    this.file,
    this.poster,
  });

  factory AdDetails.fromJson(Map<String, dynamic> json) {
    return AdDetails(
      id: json['id'] as int,
      statusId: json['statusId'] as int,
      title: json['title'] as String?,
      description: json['description'] as String?,
      vast: json['vast'] as String?,
      file: json['file'] as String?,
      poster: json['poster'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [id, statusId, title, description, vast, file, poster];
}

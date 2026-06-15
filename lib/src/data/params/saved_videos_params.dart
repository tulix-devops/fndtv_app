class SavedVideosParams {
  SavedVideosParams({
    required this.videoIds,
  });

  final List<int> videoIds;

  Map<String, dynamic> toJson() {
    return {
      'videoIds': videoIds,
    };
  }
}

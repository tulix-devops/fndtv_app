class AdLogEventParams {
  AdLogEventParams(
      {required this.adId,
      required this.eventTypeId,
      required this.contentId,
      required this.token});

  final int adId;
  final int eventTypeId;
  final int contentId;
  final String token;

  Map<String, dynamic> toJson() {
    return {
      'adId': adId.toString(),
      'eventTypeId': eventTypeId.toString(),
      'contentId': contentId.toString(),
    };
  }
}

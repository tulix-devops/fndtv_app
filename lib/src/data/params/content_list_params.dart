class ContentListParams {
  ContentListParams( {
    required this.typeId,
    required this.page,
  });

  final int typeId;
  final int page;

  Map<String, dynamic> toJson() {
    return {
      'typeId': typeId,
    };
  }
}

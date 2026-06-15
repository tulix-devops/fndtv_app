class ContentListCategoryParams {
  ContentListCategoryParams({required this.typeId, required this.categoryId});

  final int typeId;
  final int categoryId;

  Map<String, dynamic> toJson() {
    return {'typeId': typeId, 'categoryId': categoryId};
  }
}

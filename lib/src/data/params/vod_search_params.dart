class VodSearchParams {
  VodSearchParams({
    required this.search,
    required this.categoryIds,
    required this.countryIds,
    required this.releaseYears,
    required this.page,
  });

  final String? search;
  final List<int> categoryIds;
  final List<int> countryIds;
  final List<int> releaseYears;
  final int page;

  Map<String, dynamic> toJson() {
    return {
      'search': search,
      'categoryIds': categoryIds,
      'countryIds': countryIds,
      'releaseYears': releaseYears,
      'page': page
    };
  }
}

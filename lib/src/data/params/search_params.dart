class SearchParams {
  SearchParams({
    this.page,
    this.search,
    this.categoryIds,
    this.countryIds,
    this.releaseYears,
    this.limit,
    required this.typeId
  });

  final String? search;
  final List<int>? categoryIds;
  final List<int>? countryIds;
  final List<int>? releaseYears;
  final int? page;
  final int? limit;
  final int typeId;
}

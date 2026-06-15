import 'package:equatable/equatable.dart';

class PaginationLinksModel extends Equatable {
  const PaginationLinksModel({
    required this.first,
    required this.last,
    required this.prev,
    required this.next,
  });

  final String? first;
  final String? last;
  final String? prev;
  final String? next;

  factory PaginationLinksModel.fromJson(Map<String, dynamic> json) {
    return PaginationLinksModel(
      first: (json['first'] as String?)?.toString(),
      last: (json['last'] as String?)?.toString(),
      prev: (json['prev'] as String?)?.toString(),
      next: (json['next'] as String?)?.toString(),
    );
  }

  static const empty = PaginationLinksModel(
    first: '',
    last: '',
    prev: '',
    next: '',
  );

  @override
  // TODO: implement props
  List<Object?> get props => [first, last, prev, next];
}

class Paged<T> {
  Paged({required this.items, required this.page, required this.pageSize, required this.total});

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  factory Paged.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) item) {
    return Paged(
      items: (json['items'] as List).map((e) => item(e as Map<String, dynamic>)).toList(),
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      total: json['total'] as int,
    );
  }
}

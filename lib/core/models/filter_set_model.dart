/// Represents a user-saved set of search and filter configurations.
class FilterSet {
  // Add other filter properties as needed
  // final double? minPrizeValue;
  // final List<String>? categories;

  FilterSet({
    required this.id,
    required this.name,
    this.searchQuery,
    this.sortBy,
    this.descending,
  });

  factory FilterSet.fromFirestore(Map<String, dynamic> data, String id) =>
      FilterSet(
        id: id,
        name: data['name'] as String,
        searchQuery: data['searchQuery'] as String?,
        sortBy: data['sortBy'] as String?,
        descending: data['descending'] as bool?,
      );
  final String id;
  final String name;
  final String? searchQuery;
  final String? sortBy; // e.g., 'postedDate', 'endDate', 'prizeValue'
  final bool? descending;

  Map<String, dynamic> toJson() => {
        'name': name,
        'searchQuery': searchQuery,
        'sortBy': sortBy,
        'descending': descending,
      };
}

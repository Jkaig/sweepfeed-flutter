class Charity {
  // URL to the charity's logo/emblem

  const Charity({
    required this.id,
    required this.name,
    required this.description,
    required this.emblemUrl,
  });
  final String id;
  final String name;
  final String description;
  final String emblemUrl;
}

class PlaceResult {
  final String placeId;
  final String name;
  final String vicinity;
  final double rating;
  final int userRatingsTotal;
  final int priceLevel;
  final double latitude;
  final double longitude;
  final List<String> types;
  final bool isOpen;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.vicinity,
    required this.rating,
    required this.userRatingsTotal,
    required this.priceLevel,
    required this.latitude,
    required this.longitude,
    required this.types,
    required this.isOpen,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    final openingHours = json['opening_hours'];
    
    return PlaceResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      vicinity: json['vicinity'] ?? 'Address not available',
      rating: (json['rating'] ?? 0.0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      priceLevel: json['price_level'] ?? 0,
      latitude: location['lat'].toDouble(),
      longitude: location['lng'].toDouble(),
      types: List<String>.from(json['types'] ?? []),
      isOpen: openingHours?['open_now'] ?? true,
    );
  }
}
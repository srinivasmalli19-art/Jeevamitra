class FarmEntity {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final double lat;
  final double lng;
  final String geohash;
  final String village;
  final String district;
  final String state;
  final double areaSqMeters;
  final String areaUnit;
  final List<String> fodderTypes; // 'grass','sorghum','maize','cotton','groundnut','paddy'
  final double pricePerDayPerAnimal;
  final int maxAnimals;
  final bool hasWater;
  final bool hasShade;
  final bool hasFencing;
  final bool hasVetNearby;
  final List<String> imageUrls;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final DateTime? availableFrom;
  final DateTime? availableTo;

  const FarmEntity({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
    required this.geohash,
    required this.village,
    required this.district,
    required this.state,
    required this.areaSqMeters,
    required this.areaUnit,
    required this.fodderTypes,
    required this.pricePerDayPerAnimal,
    required this.maxAnimals,
    this.hasWater = false,
    this.hasShade = false,
    this.hasFencing = false,
    this.hasVetNearby = false,
    this.imageUrls = const [],
    this.isAvailable = true,
    this.rating = 0,
    this.reviewCount = 0,
    required this.createdAt,
    this.availableFrom,
    this.availableTo,
  });

  double get areaInAcres => areaSqMeters / 4046.856;
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';
}

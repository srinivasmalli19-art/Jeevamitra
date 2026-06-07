import 'user_model.dart';

enum AnimalCategory { cow, buffalo, goat, sheep, bull, poultry, pig, other }

extension AnimalCategoryExt on AnimalCategory {
  String get displayName {
    switch (this) {
      case AnimalCategory.cow: return 'Cow';
      case AnimalCategory.buffalo: return 'Buffalo';
      case AnimalCategory.goat: return 'Goat';
      case AnimalCategory.sheep: return 'Sheep';
      case AnimalCategory.bull: return 'Bull';
      case AnimalCategory.poultry: return 'Poultry';
      case AnimalCategory.pig: return 'Pig';
      case AnimalCategory.other: return 'Other';
    }
  }

  String get teluguName {
    switch (this) {
      case AnimalCategory.cow: return 'గోవు';
      case AnimalCategory.buffalo: return 'గేదె';
      case AnimalCategory.goat: return 'మేక';
      case AnimalCategory.sheep: return 'గొర్రె';
      case AnimalCategory.bull: return 'ఎద్దు';
      case AnimalCategory.poultry: return 'కోడి';
      case AnimalCategory.pig: return 'పంది';
      case AnimalCategory.other: return 'ఇతర';
    }
  }

  String get emoji {
    switch (this) {
      case AnimalCategory.cow: return '🐄';
      case AnimalCategory.buffalo: return '🐃';
      case AnimalCategory.goat: return '🐐';
      case AnimalCategory.sheep: return '🐑';
      case AnimalCategory.bull: return '🐂';
      case AnimalCategory.poultry: return '🐓';
      case AnimalCategory.pig: return '🐷';
      case AnimalCategory.other: return '🐾';
    }
  }
}

class AnimalListing {
  final String id;
  final AnimalCategory category;
  final String breed;
  final int ageMonths;
  final double price;
  final String location;
  final String district;
  final String state;
  final String description;
  final List<String> photos;
  final UserModel seller;
  final bool isVaccinated;
  final String? weight;
  final String gender;
  final DateTime postedAt;
  final bool isAvailable;
  final int? milkPerDay;
  final String? additionalInfo;

  const AnimalListing({
    required this.id,
    required this.category,
    required this.breed,
    required this.ageMonths,
    required this.price,
    required this.location,
    required this.district,
    required this.state,
    required this.description,
    required this.photos,
    required this.seller,
    required this.gender,
    required this.postedAt,
    this.isVaccinated = false,
    this.weight,
    this.isAvailable = true,
    this.milkPerDay,
    this.additionalInfo,
  });

  String get ageDisplay {
    if (ageMonths < 12) return '$ageMonths months';
    final years = ageMonths ~/ 12;
    final months = ageMonths % 12;
    if (months == 0) return '$years ${years == 1 ? "year" : "years"}';
    return '$years yr $months mo';
  }

  String get priceDisplay {
    if (price >= 100000) {
      final lakh = price / 100000;
      return '₹${lakh.toStringAsFixed(lakh % 1 == 0 ? 0 : 1)}L';
    } else if (price >= 1000) {
      final k = price / 1000;
      return '₹${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}K';
    }
    return '₹${price.toStringAsFixed(0)}';
  }

  String get fullPriceDisplay {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '₹$formatted';
  }
}

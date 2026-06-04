class Product {
  const Product({
    required this.id,
    required this.title,
    required this.totalRating,
    required this.description,
    required this.categoryName,
    required this.manufacturer,
    required this.price,
    required this.thumbnail,
    required this.criteriaRatings,
    required this.worth,
    required this.info,
    required this.recommendations,
    required this.nutrients,
    required this.composition,
    required this.hasQualityMark,
    required this.hasBadQualityMark,
  });

  final int id;
  final String title;
  final double totalRating;
  final String description;
  final String categoryName;
  final String manufacturer;
  final String price;
  final String? thumbnail;
  final List<CriteriaRating> criteriaRatings;
  final List<String> worth;
  final List<ProductInfo> info;
  final List<Recommendation> recommendations;
  final Nutrients? nutrients;
  final String? composition;
  final bool hasQualityMark;
  final bool hasBadQualityMark;

  int get score => (totalRating * 20).round().clamp(0, 100).toInt();

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? 'Unknown',
        totalRating: (json['totalRating'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        manufacturer: json['manufacturer'] as String? ?? '',
        price: json['price'] as String? ?? '',
        thumbnail: json['thumbnail'] as String?,
        criteriaRatings: (json['criteriaRatings'] as List? ?? [])
            .map((item) => CriteriaRating.fromJson(item as Map<String, dynamic>))
            .toList(),
        worth: (json['worth'] as List? ?? []).cast<String>(),
        info: (json['info'] as List? ?? [])
            .map((item) => ProductInfo.fromJson(item as Map<String, dynamic>))
            .toList(),
        recommendations: (json['recommendations'] as List? ?? [])
            .map((item) => Recommendation.fromJson(item as Map<String, dynamic>))
            .toList(),
        nutrients: json['nutrients'] == null
            ? null
            : Nutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
        composition: json['composition'] as String?,
        hasQualityMark: json['hasQualityMark'] as bool? ?? false,
        hasBadQualityMark: json['hasBadQualityMark'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'totalRating': totalRating,
        'description': description,
        'categoryName': categoryName,
        'manufacturer': manufacturer,
        'price': price,
        'thumbnail': thumbnail,
        'criteriaRatings': criteriaRatings.map((item) => item.toJson()).toList(),
        'worth': worth,
        'info': info.map((item) => item.toJson()).toList(),
        'recommendations': recommendations.map((item) => item.toJson()).toList(),
        'nutrients': nutrients?.toJson(),
        'composition': composition,
        'hasQualityMark': hasQualityMark,
        'hasBadQualityMark': hasBadQualityMark,
      };
}

class Nutrients {
  const Nutrients({
    this.proteins,
    this.fats,
    this.carbohydrates,
    this.calories,
    this.fiber,
  });

  final String? proteins;
  final String? fats;
  final String? carbohydrates;
  final String? calories;
  final String? fiber;

  factory Nutrients.fromJson(Map<String, dynamic> json) => Nutrients(
        proteins: json['proteins'] as String?,
        fats: json['fats'] as String?,
        carbohydrates: json['carbohydrates'] as String?,
        calories: json['calories'] as String?,
        fiber: json['fiber'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'proteins': proteins,
        'fats': fats,
        'carbohydrates': carbohydrates,
        'calories': calories,
        'fiber': fiber,
      };
}

class CriteriaRating {
  const CriteriaRating(this.title, this.value);

  final String title;
  final double value;

  factory CriteriaRating.fromJson(Map<String, dynamic> json) =>
      CriteriaRating(json['title'] as String? ?? '', (json['value'] as num?)?.toDouble() ?? 0);

  Map<String, dynamic> toJson() => {'title': title, 'value': value};
}

class ProductInfo {
  const ProductInfo(this.name, this.info);

  final String name;
  final String info;

  factory ProductInfo.fromJson(Map<String, dynamic> json) =>
      ProductInfo(json['name'] as String? ?? '', json['info'] as String? ?? '');

  Map<String, dynamic> toJson() => {'name': name, 'info': info};
}

class Recommendation {
  const Recommendation({
    required this.id,
    required this.title,
    required this.totalRating,
    required this.manufacturer,
    required this.price,
    required this.thumbnail,
    this.hasQualityMark = false,
    this.hasBadQualityMark = false,
  });

  final int id;
  final String title;
  final double totalRating;
  final String manufacturer;
  final String price;
  final String? thumbnail;
  final bool hasQualityMark;
  final bool hasBadQualityMark;

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        totalRating: (json['totalRating'] as num?)?.toDouble() ?? 0,
        manufacturer: json['manufacturer'] as String? ?? '',
        price: json['price'] as String? ?? '',
        thumbnail: json['thumbnail'] as String?,
        hasQualityMark: json['hasQualityMark'] as bool? ?? false,
        hasBadQualityMark: json['hasBadQualityMark'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'totalRating': totalRating,
        'manufacturer': manufacturer,
        'price': price,
        'thumbnail': thumbnail,
        'hasQualityMark': hasQualityMark,
        'hasBadQualityMark': hasBadQualityMark,
      };
}

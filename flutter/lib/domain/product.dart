class NormalizedIngredient {
  const NormalizedIngredient({
    required this.ingredientId,
    required this.originalName,
    required this.name,
    this.nameRu,
    this.eNumber,
    this.category,
    required this.isAllergen,
    required this.isAdditive,
    required this.riskLevel,
  });

  final int ingredientId;
  final String originalName;
  final String name;
  final String? nameRu;
  final String? eNumber;
  final String? category;
  final bool isAllergen;
  final bool isAdditive;
  final int riskLevel;

  String get displayName => nameRu ?? name;

  factory NormalizedIngredient.fromJson(Map<String, dynamic> json) =>
      NormalizedIngredient(
        ingredientId: (json['ingredient_id'] as num?)?.toInt() ?? 0,
        originalName: json['original_name'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nameRu: json['name_ru'] as String?,
        eNumber: json['e_number'] as String?,
        category: json['category'] as String?,
        isAllergen: json['is_allergen'] as bool? ?? false,
        isAdditive: json['is_additive'] as bool? ?? false,
        riskLevel: (json['risk_level'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'ingredient_id': ingredientId,
        'original_name': originalName,
        'name': name,
        'name_ru': nameRu,
        'e_number': eNumber,
        'category': category,
        'is_allergen': isAllergen,
        'is_additive': isAdditive,
        'risk_level': riskLevel,
      };
}

class Product {
  const Product({
    required this.id,
    this.barcode,
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
    this.normalizedIngredients = const [],
  });

  final int id;
  final String? barcode;
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
  final List<NormalizedIngredient> normalizedIngredients;

  int get score {
    return _calculateScore();
  }

  int _calculateScore() {
    double parse(String? v) =>
        double.tryParse(v?.replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ?? 0.0;

    double cal = parse(nutrients?.calories);
    double sugar = parse(nutrients?.sugar);
    double satFat = parse(nutrients?.saturatedFat);
    double salt = parse(nutrients?.salt);
    double protein = parse(nutrients?.proteins);
    double fiber = parse(nutrients?.fiber);

    // Calories points
    int pCal = 0;
    if (cal > 500)
      pCal = 10;
    else if (cal > 450)
      pCal = 9;
    else if (cal > 400)
      pCal = 8;
    else if (cal > 350)
      pCal = 7;
    else if (cal > 300)
      pCal = 6;
    else if (cal > 250)
      pCal = 5;
    else if (cal > 200)
      pCal = 4;
    else if (cal > 150)
      pCal = 3;
    else if (cal > 100)
      pCal = 2;
    else if (cal > 50) pCal = 1;

    // Sugar points
    int pSug = 0;
    if (sugar > 24)
      pSug = 10;
    else if (sugar > 22)
      pSug = 9;
    else if (sugar > 20)
      pSug = 8;
    else if (sugar > 18)
      pSug = 7;
    else if (sugar > 16)
      pSug = 6;
    else if (sugar > 14)
      pSug = 5;
    else if (sugar > 12)
      pSug = 4;
    else if (sugar > 10)
      pSug = 3;
    else if (sugar > 6.8)
      pSug = 2;
    else if (sugar > 3.4) pSug = 1;

    // Saturated fat points
    int pSat = 0;
    if (satFat > 10)
      pSat = 10;
    else if (satFat > 9)
      pSat = 9;
    else if (satFat > 8)
      pSat = 8;
    else if (satFat > 7)
      pSat = 7;
    else if (satFat > 6)
      pSat = 6;
    else if (satFat > 5)
      pSat = 5;
    else if (satFat > 4)
      pSat = 4;
    else if (satFat > 3)
      pSat = 3;
    else if (satFat > 2)
      pSat = 2;
    else if (satFat > 1) pSat = 1;

    // Salt points
    int pSal = 0;
    if (salt > 2.0)
      pSal = 10;
    else if (salt > 1.8)
      pSal = 9;
    else if (salt > 1.6)
      pSal = 8;
    else if (salt > 1.4)
      pSal = 7;
    else if (salt > 1.2)
      pSal = 6;
    else if (salt > 1.0)
      pSal = 5;
    else if (salt > 0.8)
      pSal = 4;
    else if (salt > 0.6)
      pSal = 3;
    else if (salt > 0.4)
      pSal = 2;
    else if (salt > 0.2) pSal = 1;

    // Protein points
    int pPro = 0;
    if (protein > 12)
      pPro = 5;
    else if (protein > 9.6)
      pPro = 4;
    else if (protein > 7.2)
      pPro = 3;
    else if (protein > 4.8)
      pPro = 2;
    else if (protein > 2.4) pPro = 1;

    // Fiber points
    int pFib = 0;
    if (fiber > 7.4)
      pFib = 5;
    else if (fiber > 6.3)
      pFib = 4;
    else if (fiber > 5.2)
      pFib = 3;
    else if (fiber > 4.1)
      pFib = 2;
    else if (fiber > 3) pFib = 1;

    // FVL Category heuristic
    String cat = categoryName.toLowerCase();
    int fvlPercent = 0;
    if (cat.contains('juice') ||
        cat.contains('nectar') ||
        cat.contains('puree') ||
        cat.contains('jam') ||
        cat.contains('marmalade') ||
        cat.contains('preserve') ||
        cat.contains('сок') ||
        cat.contains('пюре') ||
        cat.contains('джем') ||
        cat.contains('варенье')) {
      fvlPercent = 60;
    } else if (cat.contains('vegetable') ||
        cat.contains('fruit') ||
        cat.contains('legume') ||
        cat.contains('mushroom') ||
        cat.contains('nut') ||
        cat.contains('grain') ||
        cat.contains('cereal') ||
        cat.contains('bean') ||
        cat.contains('lentil') ||
        cat.contains('pea') ||
        cat.contains('овощ') ||
        cat.contains('фрукт') ||
        cat.contains('бобов') ||
        cat.contains('гриб') ||
        cat.contains('орех') ||
        cat.contains('круп') ||
        cat.contains('злак')) {
      fvlPercent = 100;
    }

    int pFvl = 0;
    if (fvlPercent > 80)
      pFvl = 5;
    else if (fvlPercent > 60)
      pFvl = 2;
    else if (fvlPercent > 40) pFvl = 1;

    int negativePoints = pCal + pSug + pSat + pSal;
    int positivePoints = pPro + pFib + pFvl;
    int nutriPoints = negativePoints - positivePoints;

    int nutritionScore = 0;
    if (nutriPoints <= -2)
      nutritionScore = 100;
    else if (nutriPoints == -1)
      nutritionScore = 90;
    else if (nutriPoints == 0)
      nutritionScore = 80;
    else if (nutriPoints == 1)
      nutritionScore = 75;
    else if (nutriPoints == 2)
      nutritionScore = 70;
    else if (nutriPoints == 3)
      nutritionScore = 65;
    else if (nutriPoints == 4)
      nutritionScore = 60;
    else if (nutriPoints == 5)
      nutritionScore = 55;
    else if (nutriPoints == 6)
      nutritionScore = 50;
    else if (nutriPoints == 7)
      nutritionScore = 45;
    else if (nutriPoints == 8)
      nutritionScore = 40;
    else if (nutriPoints == 9)
      nutritionScore = 35;
    else if (nutriPoints == 10)
      nutritionScore = 30;
    else if (nutriPoints == 11)
      nutritionScore = 15;
    else if (nutriPoints == 12)
      nutritionScore = 13;
    else if (nutriPoints == 13)
      nutritionScore = 11;
    else if (nutriPoints == 14)
      nutritionScore = 9;
    else if (nutriPoints == 15)
      nutritionScore = 7;
    else if (nutriPoints == 16)
      nutritionScore = 5;
    else if (nutriPoints == 17)
      nutritionScore = 3;
    else if (nutriPoints == 18)
      nutritionScore = 1;
    else
      nutritionScore = 0;

    int additivesPenalty = 0;
    bool hasHighRisk = false;
    for (var add in additives) {
      if (add.riskLevel == 0)
        additivesPenalty += 1;
      else if (add.riskLevel == 1)
        additivesPenalty += 3;
      else if (add.riskLevel == 2)
        additivesPenalty += 7;
      else if (add.riskLevel >= 3) {
        additivesPenalty += 15;
        hasHighRisk = true;
      }
    }

    int additivesScore = 100 - additivesPenalty;
    if (additivesScore < 0) additivesScore = 0;

    int finalScore = (nutritionScore * 0.7 + additivesScore * 0.3).round();
    if (hasHighRisk && finalScore > 49) {
      finalScore = 49;
    }

    return finalScore;
  }

  List<NormalizedIngredient> get additives =>
      normalizedIngredients.where((i) => i.isAdditive).toList()
        ..sort((a, b) => b.riskLevel.compareTo(a.riskLevel));

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] as num?)?.toInt() ?? 0,
        barcode: json['barcode'] as String?,
        title: json['title'] as String? ?? 'Unknown',
        totalRating: (json['totalRating'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String? ?? '',
        categoryName: json['categoryName'] as String? ?? '',
        manufacturer: json['manufacturer'] as String? ?? '',
        price: json['price'] as String? ?? '',
        thumbnail: json['thumbnail'] as String?,
        criteriaRatings: (json['criteriaRatings'] as List? ?? [])
            .map(
                (item) => CriteriaRating.fromJson(item as Map<String, dynamic>))
            .toList(),
        worth: (json['worth'] as List? ?? []).cast<String>(),
        info: (json['info'] as List? ?? [])
            .map((item) => ProductInfo.fromJson(item as Map<String, dynamic>))
            .toList(),
        recommendations: (json['recommendations'] as List? ?? [])
            .map(
                (item) => Recommendation.fromJson(item as Map<String, dynamic>))
            .toList(),
        nutrients: json['nutrients'] == null
            ? null
            : Nutrients.fromJson(json['nutrients'] as Map<String, dynamic>),
        composition: json['composition'] as String?,
        hasQualityMark: json['hasQualityMark'] as bool? ?? false,
        hasBadQualityMark: json['hasBadQualityMark'] as bool? ?? false,
        normalizedIngredients: (json['normalizedIngredients'] as List? ?? [])
            .map((item) =>
                NormalizedIngredient.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'title': title,
        'totalRating': totalRating,
        'description': description,
        'categoryName': categoryName,
        'manufacturer': manufacturer,
        'price': price,
        'thumbnail': thumbnail,
        'criteriaRatings':
            criteriaRatings.map((item) => item.toJson()).toList(),
        'worth': worth,
        'info': info.map((item) => item.toJson()).toList(),
        'recommendations':
            recommendations.map((item) => item.toJson()).toList(),
        'nutrients': nutrients?.toJson(),
        'composition': composition,
        'hasQualityMark': hasQualityMark,
        'hasBadQualityMark': hasBadQualityMark,
        'normalizedIngredients':
            normalizedIngredients.map((i) => i.toJson()).toList(),
      };
}

class Nutrients {
  const Nutrients({
    this.proteins,
    this.fats,
    this.carbohydrates,
    this.calories,
    this.fiber,
    this.sugar,
    this.salt,
    this.saturatedFat,
  });

  final String? proteins;
  final String? fats;
  final String? carbohydrates;
  final String? calories;
  final String? fiber;
  final String? sugar;
  final String? salt;
  final String? saturatedFat;

  factory Nutrients.fromJson(Map<String, dynamic> json) => Nutrients(
        proteins: json['proteins'] as String?,
        fats: json['fats'] as String?,
        carbohydrates: json['carbohydrates'] as String?,
        calories: json['calories'] as String?,
        fiber: json['fiber'] as String?,
        sugar: json['sugar'] as String?,
        salt: json['salt'] as String?,
        saturatedFat: json['saturated_fat'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'proteins': proteins,
        'fats': fats,
        'carbohydrates': carbohydrates,
        'calories': calories,
        'fiber': fiber,
        'sugar': sugar,
        'salt': salt,
        'saturated_fat': saturatedFat,
      };
}

class CriteriaRating {
  const CriteriaRating(this.title, this.value);

  final String title;
  final double value;

  factory CriteriaRating.fromJson(Map<String, dynamic> json) => CriteriaRating(
      json['title'] as String? ?? '', (json['value'] as num?)?.toDouble() ?? 0);

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

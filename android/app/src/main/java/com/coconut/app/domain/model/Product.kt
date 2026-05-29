package com.coconut.app.domain.model

data class Product(
    val id: Int,
    val title: String,
    val totalRating: Double,
    val description: String,
    val categoryName: String,
    val manufacturer: String,
    val price: String,
    val thumbnail: String?,
    val criteriaRatings: List<CriteriaRating>,
    val worth: List<String>,
    val info: List<ProductInfo>,
    val recommendations: List<Recommendation>,
    val nutrients: Nutrients?,
    val composition: String?,
    val hasQualityMark: Boolean,
    val hasBadQualityMark: Boolean
)

data class Nutrients(
    val proteins: String?,
    val fats: String?,
    val carbohydrates: String?,
    val calories: String?,
    val fiber: String?
)

data class CriteriaRating(
    val title: String,
    val value: Double
)

data class ProductInfo(
    val name: String,
    val info: String
)

data class Recommendation(
    val id: Int,
    val title: String,
    val totalRating: Double,
    val manufacturer: String,
    val price: String,
    val thumbnail: String?,
    val hasQualityMark: Boolean = false,
    val hasBadQualityMark: Boolean = false
)

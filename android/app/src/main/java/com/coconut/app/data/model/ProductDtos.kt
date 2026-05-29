package com.coconut.app.data.model

import com.google.gson.annotations.SerializedName

data class ApiResponse<T>(
    @SerializedName("message") val message: List<ApiMessage>?,
    @SerializedName("response") val response: T?
)

data class ApiMessage(
    @SerializedName("type") val type: String,
    @SerializedName("message") val message: String,
    @SerializedName("message_id") val messageId: String?
)

data class ProductDetailDto(
    @SerializedName("id") val id: Int,
    @SerializedName("title") val title: String?,
    @SerializedName("total_rating") val totalRating: Double?,
    @SerializedName("description") val description: String?,
    @SerializedName("category_name") val categoryName: String?,
    @SerializedName("manufacturer") val manufacturer: String?,
    @SerializedName("price") val price: String?,
    @SerializedName("thumbnail") val thumbnail: String?,
    @SerializedName("research") val research: ResearchDto?,
    @SerializedName("product_link") val productLink: String?,
    @SerializedName("criteria_ratings") val criteriaRatings: List<CriteriaRatingDto>?,
    @SerializedName("worth") val worth: List<String>?,
    @SerializedName("product_info") val productInfo: List<ProductInfoDto>?,
    @SerializedName("recommendations") val recommendations: List<RecommendationDto>?,
    @SerializedName("has_quality_mark") val hasQualityMark: Boolean? = false,
    @SerializedName("has_bad_quality_mark") val hasBadQualityMark: Boolean? = false
)

data class ResearchDto(
    @SerializedName("image") val image: String?
)

data class CriteriaRatingDto(
    @SerializedName("title") val title: String,
    @SerializedName("value") val value: Double
)

data class ProductInfoDto(
    @SerializedName("name") val name: String,
    @SerializedName("info") val info: String
)

data class RecommendationDto(
    @SerializedName("id") val id: Int,
    @SerializedName("title") val title: String?,
    @SerializedName("total_rating") val totalRating: Double?,
    @SerializedName("manufacturer") val manufacturer: String?,
    @SerializedName("price") val price: String?,
    @SerializedName("thumbnail") val thumbnail: String?,
    @SerializedName("has_quality_mark") val hasQualityMark: Boolean? = false,
    @SerializedName("has_bad_quality_mark") val hasBadQualityMark: Boolean? = false
)

data class SearchResponseDto(
    @SerializedName("response") val response: SearchDataDto?,
    @SerializedName("message") val message: List<String>? = emptyList()
)

data class SearchDataDto(
    @SerializedName("items") val items: List<RecommendationDto>?
)

package com.coconut.app.data.api

import com.coconut.app.domain.model.Product
import retrofit2.http.*

data class HistoryRequest(
    val barcode: String,
    val title: String,
    val score: Int
)

data class HistoryResponse(
    val id: String,
    val user_id: String,
    val barcode: String,
    val title: String,
    val score: Int,
    val scanned_at: String
)

data class BackendCategory(
    val id: Long,
    val title: String,
    val image_link: String?
)

data class BackendNutritionFacts(
    val serving_size_g: Double,
    val calories_kcal: Double,
    val protein_g: Double,
    val fat_g: Double,
    val carbs_g: Double,
    val fiber_g: Double,
    val sugar_g: Double,
    val salt_g: Double,
    val sodium_mg: Double
)

data class BackendHealthRisk(
    val id: Long,
    val fact: String
)

data class BackendProduct(
    val id: Long,
    val barcode: String,
    val name: String,
    val brand: String?,
    val image_link: String?,
    val total_rating: Double,
    val ingredients: String?,
    val category: BackendCategory?,
    val nutrition_facts: BackendNutritionFacts?,
    val health_risks: List<BackendHealthRisk>?
)

interface CoconutBackendApi {
    @GET("api/history/")
    suspend fun getHistory(@Header("Authorization") token: String): List<HistoryResponse>

    @POST("api/history/")
    suspend fun saveHistory(
        @Header("Authorization") token: String,
        @Body request: HistoryRequest
    ): HistoryResponse

    @DELETE("api/history/")
    suspend fun clearHistory(@Header("Authorization") token: String)

    @GET("api/products/{barcode}")
    suspend fun getProduct(
        @Header("Authorization") token: String,
        @Path("barcode") barcode: String
    ): BackendProduct
}

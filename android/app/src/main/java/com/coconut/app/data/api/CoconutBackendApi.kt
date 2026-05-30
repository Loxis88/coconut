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
}

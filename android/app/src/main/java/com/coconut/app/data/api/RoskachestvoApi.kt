package com.coconut.app.data.api

import com.coconut.app.data.model.ApiResponse
import com.coconut.app.data.model.ProductDetailDto
import com.coconut.app.data.model.SearchResponseDto
import retrofit2.http.GET
import retrofit2.http.Path
import retrofit2.http.Query

interface RoskachestvoApi {

    @GET("catalog/categories/")
    suspend fun getCategories(): ApiResponse<List<Any>>

    @GET("catalog/categories/{categoryID}/")
    suspend fun getSubcategories(@Path("categoryID") categoryID: String): ApiResponse<List<Any>>

    @GET("product/{productId}/")
    suspend fun getProduct(@Path("productId") productId: String): ApiResponse<ProductDetailDto>

    @GET("search/barcode/")
    suspend fun searchBarcode(@Query("barcode") barcode: String): ApiResponse<ProductDetailDto>

    @GET("search/product/")
    suspend fun searchProduct(
        @Query("query") query: String,
        @Query("page") page: Int
    ): SearchResponseDto

    @GET("products/quality/")
    suspend fun getQualityProducts(): SearchResponseDto

    @GET("products/violations/")
    suspend fun getViolations(): SearchResponseDto

    @GET("products/rating/high/")
    suspend fun getHighRatingProducts(): SearchResponseDto
}

package com.coconut.app.domain.repository

import com.coconut.app.domain.model.Product
import kotlinx.coroutines.flow.Flow

interface ProductRepository {
    suspend fun searchByBarcode(barcode: String, token: String? = null): Result<Product>
    fun getScanHistory(): Flow<List<Product>>
    fun getStreak(): Flow<Int>
    suspend fun clearHistory(token: String? = null)
    fun deleteFromHistory(product: Product)
    suspend fun syncHistory(token: String)
}

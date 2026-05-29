package com.coconut.app.domain.repository

import com.coconut.app.domain.model.Product
import kotlinx.coroutines.flow.Flow

interface ProductRepository {
    suspend fun searchByBarcode(barcode: String): Result<Product>
    fun getScanHistory(): Flow<List<Product>>
    fun getStreak(): Flow<Int>
    suspend fun clearHistory()
    fun deleteFromHistory(product: Product)
}

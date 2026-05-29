package com.coconut.app.domain.usecase

import com.coconut.app.domain.model.Product
import com.coconut.app.domain.repository.ProductRepository

class SearchBarcodeUseCase(
    private val repository: ProductRepository
) {
    suspend operator fun invoke(barcode: String): Result<Product> {
        if (barcode.isBlank()) return Result.failure(Exception("Barcode is empty"))
        return repository.searchByBarcode(barcode.trim())
    }
}

package com.coconut.app.domain.usecase

import com.coconut.app.domain.model.Product
import com.coconut.app.domain.repository.ProductRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SearchBarcodeUseCaseTest {

    private class FakeProductRepository : ProductRepository {
        var searchBarcodeCalledWith: String? = null
        var resultToReturn: Result<Product> = Result.failure(Exception("Not initialized"))

        override suspend fun searchByBarcode(barcode: String, token: String?): Result<Product> {
            searchBarcodeCalledWith = barcode
            return resultToReturn
        }

        override fun getScanHistory(): Flow<List<Product>> = emptyFlow()
        override fun getStreak(): Flow<Int> = emptyFlow()
        override suspend fun clearHistory(token: String?) {}
        override fun deleteFromHistory(product: Product) {}
        override suspend fun syncHistory(token: String) {}
    }

    @Test
    fun `invoke with empty barcode returns failure`() = runTest {
        val fakeRepository = FakeProductRepository()
        val useCase = SearchBarcodeUseCase(fakeRepository)

        val result = useCase.invoke("")

        assertTrue(result.isFailure)
        assertEquals("Barcode is empty", result.exceptionOrNull()?.message)
    }

    @Test
    fun `invoke with blank barcode returns failure`() = runTest {
        val fakeRepository = FakeProductRepository()
        val useCase = SearchBarcodeUseCase(fakeRepository)

        val result = useCase.invoke("   ")

        assertTrue(result.isFailure)
        assertEquals("Barcode is empty", result.exceptionOrNull()?.message)
    }

    @Test
    fun `invoke with valid barcode trims whitespace and calls repository`() = runTest {
        val fakeRepository = FakeProductRepository()
        val expectedProduct = Product(
            id = 1,
            title = "Test Product",
            totalRating = 5.0,
            description = "A product",
            categoryName = "Food",
            manufacturer = "Test Co",
            price = "1.00",
            thumbnail = null,
            criteriaRatings = emptyList(),
            worth = emptyList(),
            info = emptyList(),
            recommendations = emptyList(),
            nutrients = null,
            composition = null,
            hasQualityMark = false,
            hasBadQualityMark = false
        )
        fakeRepository.resultToReturn = Result.success(expectedProduct)
        val useCase = SearchBarcodeUseCase(fakeRepository)

        val result = useCase.invoke("  123456789  ")

        assertTrue(result.isSuccess)
        assertEquals(expectedProduct, result.getOrNull())
        assertEquals("123456789", fakeRepository.searchBarcodeCalledWith)
    }
}

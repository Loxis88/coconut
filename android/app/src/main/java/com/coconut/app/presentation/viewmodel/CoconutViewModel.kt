package com.coconut.app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.coconut.app.domain.model.Product
import com.coconut.app.domain.repository.ProductRepository
import com.coconut.app.domain.usecase.SearchBarcodeUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed class ProductState {
    object Idle : ProductState()
    object Loading : ProductState()
    data class Success(val product: Product) : ProductState()
    data class Error(val message: String) : ProductState()
}

class CoconutViewModel(
    private val searchBarcodeUseCase: SearchBarcodeUseCase,
    private val repository: ProductRepository,
    private val authRepository: com.coconut.app.domain.repository.AuthRepository
) : ViewModel() {

    private val _productState = MutableStateFlow<ProductState>(ProductState.Idle)
    val productState: StateFlow<ProductState> = _productState.asStateFlow()

    init {
        syncHistory()
    }

    private fun syncHistory() {
        val token = authRepository.getAccessToken()
        if (token != null) {
            viewModelScope.launch {
                repository.syncHistory(token)
            }
        }
    }

    val scanHistory: StateFlow<List<Product>> = repository.getScanHistory()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    val streak: StateFlow<Int> = repository.getStreak()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), 0)

    val dailyAverage: StateFlow<Int> = scanHistory.map { history ->
        if (history.isEmpty()) 0
        else {
            val totalScore = history.sumOf { (it.totalRating * 20).toInt() }
            totalScore / history.size
        }
    }.stateIn(viewModelScope, SharingStarted.Lazily, 0)

    fun searchBarcode(barcode: String) {
        if (barcode.isBlank()) return
        _productState.value = ProductState.Loading

        val token = authRepository.getAccessToken()
        viewModelScope.launch {
            val result = searchBarcodeUseCase(barcode, token)
            result.onSuccess { product ->
                _productState.value = ProductState.Success(product)
            }.onFailure { exception ->
                _productState.value = ProductState.Error(exception.message ?: "Unknown error")
            }
        }
    }

    fun showProductDetails(product: Product) {
        _productState.value = ProductState.Success(product)
    }

    fun resetState() {
        _productState.value = ProductState.Idle
    }

    fun clearHistory() {
        val token = authRepository.getAccessToken()
        viewModelScope.launch {
            repository.clearHistory(token)
        }
    }

    fun deleteFromHistory(product: Product) {
        viewModelScope.launch {
            repository.deleteFromHistory(product)
        }
    }

    class Factory(
        private val searchBarcodeUseCase: SearchBarcodeUseCase,
        private val repository: ProductRepository,
        private val authRepository: com.coconut.app.domain.repository.AuthRepository
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            return CoconutViewModel(searchBarcodeUseCase, repository, authRepository) as T
        }
    }
}

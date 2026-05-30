package com.coconut.app.data.repository

import android.content.SharedPreferences
import com.coconut.app.data.api.RoskachestvoApi
import com.coconut.app.data.model.ProductDetailDto
import com.coconut.app.domain.model.*
import com.coconut.app.domain.repository.ProductRepository
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.asStateFlow
import java.time.LocalDate
import java.time.format.DateTimeFormatter

class ProductRepositoryImpl(
    private val api: RoskachestvoApi,
    private val backendApi: com.coconut.app.data.api.CoconutBackendApi,
    private val prefs: SharedPreferences,
    private val gson: Gson
) : ProductRepository {

    private val historyKey = "scan_history"
    private val _scanHistoryFlow = MutableStateFlow<List<Product>>(emptyList())

    init {
        loadHistoryFromPrefs()
    }

    private fun loadHistoryFromPrefs() {
        val json = prefs.getString(historyKey, "[]")
        val type = object : TypeToken<List<Product>>() {}.type
        val history: List<Product> = gson.fromJson(json, type) ?: emptyList()
        _scanHistoryFlow.value = history
    }

    private fun saveHistoryToPrefs(history: List<Product>) {
        val json = gson.toJson(history)
        prefs.edit().putString(historyKey, json).apply()
        _scanHistoryFlow.value = history
    }

    override suspend fun searchByBarcode(barcode: String, token: String?): Result<Product> {
        return try {
            val bearerToken = if (token != null) "Bearer $token" else {
                // If token is missing, we might still want to try fetching if backend allows guest access, 
                // but usually our API is protected. Let's assume we need a token.
                return Result.failure(Exception("Authentication required"))
            }

            val dto = backendApi.getProduct(bearerToken, barcode)
            
            val product = mapBackendToDomain(dto)
            val currentHistory = _scanHistoryFlow.value.toMutableList()
            // Remove if already exists to move it to top
            currentHistory.removeAll { it.id == product.id }
            currentHistory.add(0, product)
            saveHistoryToPrefs(currentHistory)
            
            // Track date for streak
            trackScanDate()

            // Save to history table on backend (already saved by being in the catalog? 
            // No, catalog is just a list of all products. History is personal.)
            // The GetProduct endpoint might or might not save to history automatically.
            // Based on our implementation of SaveHistory, we should call it.
            try {
                backendApi.saveHistory(
                    token = bearerToken,
                    request = com.coconut.app.data.api.HistoryRequest(
                        barcode = barcode,
                        title = product.title,
                        score = (product.totalRating * 20).toInt()
                    )
                )
            } catch (e: Exception) {
                android.util.Log.e("ProductRepo", "Failed to save history to backend", e)
            }
            
            Result.success(product)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    private fun mapBackendToDomain(dto: com.coconut.app.data.api.BackendProduct): Product {
        val nutrients = dto.nutrition_facts?.let {
            Nutrients(
                proteins = it.protein_g.toString(),
                fats = it.fat_g.toString(),
                carbohydrates = it.carbs_g.toString(),
                calories = it.calories_kcal.toString(),
                fiber = it.fiber_g.toString()
            )
        }

        return Product(
            id = dto.id.toInt(),
            title = dto.name,
            totalRating = dto.total_rating,
            description = "",
            categoryName = dto.category?.title ?: "Unknown",
            manufacturer = dto.brand ?: "Unknown",
            price = "",
            thumbnail = dto.image_link,
            criteriaRatings = emptyList(), // Not currently in our backend schema
            worth = dto.health_risks?.map { it.fact } ?: emptyList(),
            info = emptyList(),
            recommendations = emptyList(),
            nutrients = nutrients,
            composition = dto.ingredients,
            hasQualityMark = false,
            hasBadQualityMark = (dto.health_risks?.size ?: 0) > 0
        )
    }

    override suspend fun syncHistory(token: String) {
        try {
            val serverHistory = backendApi.getHistory("Bearer $token")
            // This is a simplified sync: we'll just merge titles/barcodes if we can.
            // Since Roskachestvo data is rich, we might still want to fetch full details if missing.
            // For now, let's at least populate the history list with basic info from server.
            
            val mappedHistory = serverHistory.map { h ->
                Product(
                    id = h.id.hashCode(), // Simplified ID mapping
                    title = h.title,
                    totalRating = h.score / 20.0,
                    description = "",
                    categoryName = "",
                    manufacturer = "",
                    price = "",
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
            }
            
            // Merge with local history if needed, or just replace for now
            if (mappedHistory.isNotEmpty()) {
                saveHistoryToPrefs(mappedHistory)
            }
        } catch (e: Exception) {
            android.util.Log.e("ProductRepo", "Failed to sync history from backend", e)
        }
    }

    override fun deleteFromHistory(product: Product) {
        val currentHistory = _scanHistoryFlow.value.toMutableList()
        currentHistory.removeAll { it.id == product.id }
        saveHistoryToPrefs(currentHistory)
    }

    override fun getScanHistory(): Flow<List<Product>> {
        return _scanHistoryFlow.asStateFlow()
    }

    private val _streakFlow = MutableStateFlow(calculateStreakFromPrefs())

    override fun getStreak(): Flow<Int> {
        return _streakFlow.asStateFlow()
    }

    override suspend fun clearHistory(token: String?) {
        prefs.edit().remove(historyKey).apply()
        _scanHistoryFlow.value = emptyList()
        if (token != null) {
            try {
                backendApi.clearHistory("Bearer $token")
            } catch (e: Exception) {
                android.util.Log.e("ProductRepo", "Failed to clear history on backend", e)
            }
        }
    }

    private val datesKey = "scan_dates"

    private fun trackScanDate() {
        val today = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"))
        val json = prefs.getString(datesKey, "[]")
        val type = object : TypeToken<List<String>>() {}.type
        val dates: MutableList<String> = gson.fromJson(json, type) ?: mutableListOf()
        
        if (!dates.contains(today)) {
            dates.add(today)
            prefs.edit().putString(datesKey, gson.toJson(dates)).apply()
            _streakFlow.value = calculateStreakFromPrefs()
        }
    }

    private fun calculateStreakFromPrefs(): Int {
        val json = prefs.getString(datesKey, "[]")
        val type = object : TypeToken<List<String>>() {}.type
        val dates: List<String> = gson.fromJson(json, type) ?: emptyList()
        
        if (dates.isEmpty()) return 0
        
        val today = LocalDate.now()
        val yesterday = today.minusDays(1)
        
        val formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        val sortedDates = dates.map { LocalDate.parse(it, formatter) }.sortedDescending()
        
        if (sortedDates[0] != today && sortedDates[0] != yesterday) return 0
        
        var streak = 1
        for (i in 0 until sortedDates.size - 1) {
            if (sortedDates[i].minusDays(1) == sortedDates[i+1]) {
                streak++
            } else {
                break
            }
        }
        return streak
    }

    private fun mapToDomain(dto: ProductDetailDto): Product {
        val nutrients = extractNutrients(dto)
        val composition = dto.productInfo?.find { it.name.lowercase() == "состав" }?.info
        
        var imgUrl = dto.thumbnail ?: dto.research?.image
        if (imgUrl != null && imgUrl.startsWith("/")) {
            imgUrl = "https://rskrf.ru$imgUrl"
        }

        return Product(
            id = dto.id,
            title = dto.title ?: "Unknown",
            totalRating = dto.totalRating ?: 0.0,
            description = dto.description ?: "",
            categoryName = dto.categoryName ?: "Unknown",
            manufacturer = dto.manufacturer ?: "Unknown",
            price = dto.price ?: "",
            thumbnail = imgUrl,
            criteriaRatings = dto.criteriaRatings?.map {
                CriteriaRating(it.title, it.value)
            } ?: emptyList(),
            worth = dto.worth ?: emptyList(),
            info = dto.productInfo?.map {
                ProductInfo(it.name, it.info)
            } ?: emptyList(),
            recommendations = emptyList(), // Avoid huge payload in history
            nutrients = nutrients,
            composition = composition,
            hasQualityMark = dto.hasQualityMark ?: false,
            hasBadQualityMark = dto.hasBadQualityMark ?: false
        )
    }

    private fun extractNutrients(dto: ProductDetailDto): Nutrients? {
        val infoList = dto.productInfo ?: return null
        val bjuString = infoList.find { 
            it.name.lowercase().contains("пищевая ценность") || 
            it.name.lowercase().contains("дополнительная информация") 
        }?.info ?: ""

        if (bjuString.isEmpty()) {
            val p = infoList.find { it.name.lowercase().contains("белки") }?.info
            val f = infoList.find { it.name.lowercase().contains("жиры") }?.info
            val c = infoList.find { it.name.lowercase().contains("углеводы") }?.info
            val cal = infoList.find { it.name.lowercase().contains("калорийность") || it.name.lowercase().contains("энергетическая ценность") }?.info
            if (p != null || f != null || c != null) return Nutrients(p, f, c, cal, null)
            return null
        }

        return Nutrients(
            proteins = findValue(bjuString, listOf("белки", "белок")),
            fats = findValue(bjuString, listOf("жиры", "жир")),
            carbohydrates = findValue(bjuString, listOf("углеводы")),
            calories = findValue(bjuString, listOf("энергетическая ценность", "калорийность", "ккал")),
            fiber = findValue(bjuString, listOf("пищевые волокна", "клетчатка"))
        )
    }

    private fun findValue(text: String, keys: List<String>): String? {
        val lowerText = text.lowercase()
        for (key in keys) {
            val index = lowerText.indexOf(key)
            if (index != -1) {
                val remainder = text.substring(index + key.length).trim()
                val result = remainder.takeWhile { it != ';' && it != ',' }.trim()
                    .removePrefix("-").removePrefix(":").trim()
                if (result.isNotEmpty()) return result
            }
        }
        return null
    }
}

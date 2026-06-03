package com.coconut.app.domain.repository

import com.coconut.app.data.api.AuthResponse

interface AuthRepository {
    suspend fun loginWithGoogle(idToken: String): Result<AuthResponse>
    fun getAccessToken(): String?
    fun saveTokens(accessToken: String, refreshToken: String)
    fun clearTokens()
    suspend fun fetchCurrentUser(): Result<com.coconut.app.data.api.AuthUser>
    fun getCachedUser(): com.coconut.app.data.api.AuthUser?
    suspend fun updateNickname(nickname: String): Result<Unit>
    suspend fun deleteAccount(): Result<Unit>
}

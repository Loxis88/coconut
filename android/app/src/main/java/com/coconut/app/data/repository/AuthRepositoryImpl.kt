package com.coconut.app.data.repository

import android.content.Context
import android.content.SharedPreferences
import com.coconut.app.data.api.AuthApi
import com.coconut.app.data.api.AuthResponse
import com.coconut.app.data.api.GoogleLoginRequest
import com.coconut.app.domain.repository.AuthRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class AuthRepositoryImpl(
    private val authApi: AuthApi,
    private val context: Context
) : AuthRepository {

    private val prefs: SharedPreferences = context.getSharedPreferences("auth_prefs", Context.MODE_PRIVATE)

    override suspend fun loginWithGoogle(idToken: String): Result<AuthResponse> = withContext(Dispatchers.IO) {
        try {
            val response = authApi.googleLogin(GoogleLoginRequest(idToken))
            saveTokens(response.accessToken, response.refreshToken)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun getAccessToken(): String? {
        return prefs.getString("access_token", null)
    }

    override fun saveTokens(accessToken: String, refreshToken: String) {
        prefs.edit()
            .putString("access_token", accessToken)
            .putString("refresh_token", refreshToken)
            .apply()
    }

    override fun clearTokens() {
        prefs.edit().clear().apply()
    }
}

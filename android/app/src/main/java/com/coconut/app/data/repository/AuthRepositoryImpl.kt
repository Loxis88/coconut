package com.coconut.app.data.repository

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import com.coconut.app.data.api.AuthApi
import com.coconut.app.data.api.AuthResponse
import com.coconut.app.data.api.AuthUser
import com.coconut.app.data.api.GoogleLoginRequest
import com.coconut.app.domain.repository.AuthRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class AuthRepositoryImpl(
    private val authApi: AuthApi,
    private val context: Context
) : AuthRepository {

    private val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
    private val prefs: SharedPreferences = EncryptedSharedPreferences.create(
        "auth_prefs",
        masterKeyAlias,
        context,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    override suspend fun loginWithGoogle(idToken: String): Result<AuthResponse> = withContext(Dispatchers.IO) {
        try {
            val response = authApi.googleLogin(GoogleLoginRequest(idToken))
            saveTokens(response.accessToken, response.refreshToken)
            saveUser(response.user)
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

    private fun saveUser(user: AuthUser) {
        prefs.edit()
            .putString("user_email", user.email)
            .putString("user_nickname", user.nickname)
            .putString("user_id", user.id)
            .apply()
    }

    override fun getCachedUser(): AuthUser? {
        val id = prefs.getString("user_id", null) ?: return null
        val email = prefs.getString("user_email", "") ?: ""
        val nickname = prefs.getString("user_nickname", null)
        return AuthUser(id, email, nickname, null)
    }

    override suspend fun fetchCurrentUser(): Result<AuthUser> = withContext(Dispatchers.IO) {
        try {
            val token = getAccessToken() ?: return@withContext Result.failure(Exception("Not logged in"))
            val user = authApi.getMe("Bearer $token")
            saveUser(user)
            Result.success(user)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun updateNickname(nickname: String): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val token = getAccessToken() ?: return@withContext Result.failure(Exception("Not logged in"))
            authApi.updateNickname("Bearer $token", com.coconut.app.data.api.NicknameRequest(nickname))
            // Update cache
            val user = getCachedUser()
            if (user != null) {
                saveUser(user.copy(nickname = nickname))
            }
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun deleteAccount(): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val token = getAccessToken() ?: return@withContext Result.failure(Exception("Not logged in"))
            authApi.deleteAccount("Bearer $token")
            clearTokens()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override fun clearTokens() {
        prefs.edit().clear().apply()
    }
}

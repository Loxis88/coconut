package com.coconut.app.data.api

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

class AuthAuthenticator(
    private val context: Context,
    private val baseUrl: String
) : Authenticator {

    private val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
    private val prefs = EncryptedSharedPreferences.create(
        "auth_prefs",
        masterKeyAlias,
        context,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    // A lightweight Retrofit instance that doesn't use the Authenticator
    // to prevent infinite loops when the refresh token is also expired/invalid.
    private val authApi: AuthApi by lazy {
        Retrofit.Builder()
            .baseUrl(baseUrl)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(AuthApi::class.java)
    }

    override fun authenticate(route: Route?, response: Response): Request? {
        val currentToken = prefs.getString("access_token", null)

        // Prevent infinite retry loops if the failing request is itself a refresh request
        if (response.request.url.encodedPath.contains("/auth/refresh")) {
            return null
        }

        // We only attempt to refresh if we actually have a refresh token
        val refreshToken = prefs.getString("refresh_token", null)
        if (refreshToken.isNullOrEmpty()) {
            return null
        }

        synchronized(this) {
            // Double check if token was already refreshed by another thread
            val newAccessToken = prefs.getString("access_token", null)
            if (newAccessToken != null && newAccessToken != currentToken) {
                return response.request.newBuilder()
                    .header("Authorization", "Bearer $newAccessToken")
                    .build()
            }

            // Synchronously call the refresh API
            return try {
                val refreshResponse = runBlocking {
                    authApi.refreshToken(RefreshRequest(refreshToken))
                }

                // Success, save new tokens
                prefs.edit()
                    .putString("access_token", refreshResponse.accessToken)
                    .putString("refresh_token", refreshResponse.refreshToken)
                    .apply()

                // Retry the original request with the new access token
                response.request.newBuilder()
                    .header("Authorization", "Bearer ${refreshResponse.accessToken}")
                    .build()

            } catch (e: Exception) {
                // If it's an HTTP exception (e.g. Retrofit HttpException) with 401, clear tokens.
                // Otherwise (network error, timeout), we just return null and let the call fail
                // without wiping user session unnecessarily.
                if (e is retrofit2.HttpException && e.code() == 401) {
                    prefs.edit().clear().apply()
                }
                null
            }
        }
    }
}

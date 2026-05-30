package com.coconut.app.data.api

import com.google.gson.annotations.SerializedName
import retrofit2.http.Body
import retrofit2.http.POST

import retrofit2.http.*

data class GoogleLoginRequest(
    @SerializedName("id_token") val idToken: String
)

data class AuthUser(
    val id: String,
    val email: String,
    val nickname: String?,
    @SerializedName("google_id") val googleId: String?
)

data class AuthResponse(
    @SerializedName("access_token") val accessToken: String,
    @SerializedName("refresh_token") val refreshToken: String,
    val user: AuthUser
)

data class NicknameRequest(val nickname: String)

interface AuthApi {
    @POST("/auth/google")
    suspend fun googleLogin(@Body request: GoogleLoginRequest): AuthResponse

    @GET("/api/me")
    suspend fun getMe(@Header("Authorization") token: String): AuthUser

    @PATCH("/api/me/nickname")
    suspend fun updateNickname(
        @Header("Authorization") token: String,
        @Body request: NicknameRequest
    )
}

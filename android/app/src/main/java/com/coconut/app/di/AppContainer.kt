package com.coconut.app.di

import android.content.Context
import com.coconut.app.data.api.AuthApi
import com.coconut.app.data.api.CoconutBackendApi
import com.coconut.app.data.api.RoskachestvoApi
import com.coconut.app.data.repository.AuthRepositoryImpl
import com.coconut.app.data.repository.ProductRepositoryImpl
import com.coconut.app.domain.repository.AuthRepository
import com.coconut.app.domain.repository.ProductRepository
import com.coconut.app.domain.usecase.SearchBarcodeUseCase
import com.google.gson.Gson
import okhttp3.Cookie
import okhttp3.CookieJar
import okhttp3.HttpUrl
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

class AppContainer(private val context: Context) {

    private val gson = Gson()

    private val prefs = context.getSharedPreferences("coconut_prefs", Context.MODE_PRIVATE)

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val cookieJar = object : CookieJar {
        private val cookieStore = mutableMapOf<String, List<Cookie>>()

        override fun saveFromResponse(url: HttpUrl, cookies: List<Cookie>) {
            cookieStore[url.host] = cookies
        }

        override fun loadForRequest(url: HttpUrl): List<Cookie> {
            return cookieStore[url.host] ?: emptyList()
        }
    }

    val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .addInterceptor { chain ->
            val request = chain.request().newBuilder()
                .header("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36")
                .header("Accept", "application/json, text/plain, */*")
                .header("Accept-Language", "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7")
                .header("Connection", "keep-alive")
                .build()
            chain.proceed(request)
        }
        .cookieJar(cookieJar)
        .followRedirects(true)
        .followSslRedirects(true)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl("https://rskrf.ru/rest/1/")
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    private val coconutRetrofit = Retrofit.Builder()
        .baseUrl("http://62.233.43.33:8080/") // IP address of the Coconut backend server
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    private val api: RoskachestvoApi = retrofit.create(RoskachestvoApi::class.java)
    private val authApi: AuthApi = coconutRetrofit.create(AuthApi::class.java)
    private val backendApi: CoconutBackendApi = coconutRetrofit.create(CoconutBackendApi::class.java)

    val productRepository: ProductRepository = ProductRepositoryImpl(api, backendApi, prefs, gson)
    val searchBarcodeUseCase: SearchBarcodeUseCase = SearchBarcodeUseCase(productRepository)
    val authRepository: AuthRepository = AuthRepositoryImpl(authApi, context)
}

package com.coconut.app.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.coconut.app.data.api.AuthUser
import com.coconut.app.domain.repository.AuthRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

sealed class AuthState {
    object Idle : AuthState()
    object Loading : AuthState()
    data class Success(val user: AuthUser) : AuthState()
    data class Error(val message: String) : AuthState()
}

class AuthViewModel(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _authState = MutableStateFlow<AuthState>(AuthState.Idle)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    fun handleGoogleSignIn(idToken: String?) {
        if (idToken == null) {
            _authState.value = AuthState.Error("Google Sign-In failed or was cancelled.")
            return
        }

        _authState.value = AuthState.Loading
        viewModelScope.launch {
            val result = authRepository.loginWithGoogle(idToken)
            if (result.isSuccess) {
                val response = result.getOrNull()
                if (response != null) {
                    _authState.value = AuthState.Success(response.user)
                } else {
                    _authState.value = AuthState.Error("Empty response from server")
                }
            } else {
                val error = result.exceptionOrNull()
                _authState.value = AuthState.Error(error?.message ?: "Unknown login error")
            }
        }
    }

    fun logout() {
        authRepository.clearTokens()
        _authState.value = AuthState.Idle
    }
}

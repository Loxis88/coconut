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

    private val _currentUser = MutableStateFlow<AuthUser?>(authRepository.getCachedUser())
    val currentUser: StateFlow<AuthUser?> = _currentUser.asStateFlow()

    init {
        refreshUserInfo()
    }

    fun refreshUserInfo() {
        viewModelScope.launch {
            val result = authRepository.fetchCurrentUser()
            result.onSuccess { user ->
                _currentUser.value = user
                if (_authState.value is AuthState.Idle) {
                    _authState.value = AuthState.Success(user)
                }
            }.onFailure { error ->
                if (error.message?.contains("401", ignoreCase = true) == true || error.message?.contains("Unauthorized", ignoreCase = true) == true) {
                    logout()
                }
            }
        }
    }

    fun handleGoogleSignIn(idToken: String?) {
        if (idToken == null) {
            _authState.value = AuthState.Error("Google Sign-In failed or was cancelled.")
            return
        }

        _authState.value = AuthState.Loading
        viewModelScope.launch {
            val result = authRepository.loginWithGoogle(idToken)
            result.onSuccess { response ->
                _currentUser.value = response.user
                _authState.value = AuthState.Success(response.user)
            }.onFailure { error ->
                _authState.value = AuthState.Error(error.message ?: "Unknown login error")
            }
        }
    }

    fun updateNickname(newNickname: String) {
        viewModelScope.launch {
            val result = authRepository.updateNickname(newNickname)
            result.onSuccess {
                refreshUserInfo()
            }
        }
    }

    fun deleteAccount(onSuccess: () -> Unit) {
        viewModelScope.launch {
            val result = authRepository.deleteAccount()
            result.onSuccess {
                onSuccess()
            }
        }
    }

    fun logout() {
        authRepository.clearTokens()
        _currentUser.value = null
        _authState.value = AuthState.Idle
    }
}

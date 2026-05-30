package com.coconut.app.presentation.ui

import android.app.Activity
import android.content.Context
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import com.coconut.app.presentation.viewmodel.AuthState
import com.coconut.app.presentation.viewmodel.AuthViewModel
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.tasks.Task

@Composable
fun AuthScreen(viewModel: AuthViewModel, onLoginSuccess: () -> Unit) {
    val authState by viewModel.authState.collectAsState()
    val context = LocalContext.current

    val googleSignInLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val task: Task<GoogleSignInAccount> = GoogleSignIn.getSignedInAccountFromIntent(result.data)
            try {
                val account = task.getResult(ApiException::class.java)
                val idToken = account?.idToken
                viewModel.handleGoogleSignIn(idToken)
            } catch (e: ApiException) {
                viewModel.handleGoogleSignIn(null)
            }
        } else {
            viewModel.handleGoogleSignIn(null)
        }
    }

    LaunchedEffect(authState) {
        if (authState is AuthState.Success) {
            onLoginSuccess()
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text("Coconut App", style = MaterialTheme.typography.headlineLarge)
        Spacer(modifier = Modifier.height(32.dp))

        when (val state = authState) {
            is AuthState.Loading -> {
                CircularProgressIndicator()
            }
            is AuthState.Error -> {
                Text(text = "Error: ${state.message}", color = MaterialTheme.colorScheme.error)
                Spacer(modifier = Modifier.height(16.dp))
                GoogleSignInButton(context) { intent ->
                    googleSignInLauncher.launch(intent)
                }
            }
            else -> {
                GoogleSignInButton(context) { intent ->
                    googleSignInLauncher.launch(intent)
                }
            }
        }
    }
}

@Composable
fun GoogleSignInButton(context: Context, launchSignIn: (android.content.Intent) -> Unit) {
    Button(
        onClick = {
            val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestIdToken("810958888238-c1fmanoapbjbgha6nkbte55o99cqj446.apps.googleusercontent.com") // Web Client ID
                .requestEmail()
                .build()
            val mGoogleSignInClient = GoogleSignIn.getClient(context, gso)
            launchSignIn(mGoogleSignInClient.signInIntent)
        },
        modifier = Modifier.fillMaxWidth(0.8f)
    ) {
        Text("Sign in with Google")
    }
}

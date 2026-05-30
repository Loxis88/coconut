package com.coconut.app.presentation.ui

import android.app.Activity
import android.content.Context
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material.icons.rounded.Email
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.geometry.Size
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

    AdaptiveScreen {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                Canvas(Modifier.fillMaxSize()) {
                    drawCircle(
                        brush = Brush.radialGradient(listOf(Coco.Lime.copy(alpha = 0.35f), Color.Transparent)),
                        radius = size.minDimension * 0.62f,
                        center = Offset(size.width * 0.5f, size.height * 0.42f),
                    )
                }
                CoconutMark(180.dp)
                FloatingScore(92, Modifier.align(Alignment.TopStart).padding(start = 28.dp, top = 70.dp))
                FloatingScore(48, Modifier.align(Alignment.TopEnd).padding(end = 36.dp, top = 120.dp))
                FloatingScore(71, Modifier.align(Alignment.BottomStart).padding(start = 36.dp, bottom = 140.dp))
                FloatingScore(88, Modifier.align(Alignment.BottomEnd).padding(end = 40.dp, bottom = 90.dp))
            }

            Column(Modifier.padding(start = 28.dp, end = 28.dp, bottom = 36.dp)) {
                Text("Coconut.", color = Coco.Ink, fontSize = 56.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 54.sp)
                Text(
                    "Раскуси каждый кусочек. Получи честную оценку любого продукта — в один скан.",
                    color = Coco.Ink2,
                    fontSize = 19.sp,
                    lineHeight = 25.sp,
                    modifier = Modifier.padding(top = 10.dp, bottom = 24.dp),
                )

                if (authState is AuthState.Loading) {
                    Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = Coco.Emerald)
                    }
                } else {
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        AuthPill(
                            label = "Войти через Google",
                            kind = AuthPillKind.Brand,
                            onClick = {
                                val clientId = context.getString(com.coconut.app.R.string.google_client_id)
                                val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                                    .requestIdToken(clientId)
                                    .requestEmail()
                                    .build()
                                val mGoogleSignInClient = GoogleSignIn.getClient(context, gso)
                                googleSignInLauncher.launch(mGoogleSignInClient.signInIntent)
                            }
                        )
                        AuthPill(
                            label = "Войти через Apple ID",
                            kind = AuthPillKind.Ink,
                            onClick = { /* TODO */ }
                        )
                        AuthPill(
                            label = "Войти по почте",
                            kind = AuthPillKind.Ghost,
                            icon = Icons.Rounded.Email,
                            onClick = { /* TODO */ }
                        )
                    }
                }

                if (authState is AuthState.Error) {
                    Text(
                        text = (authState as AuthState.Error).message,
                        color = Coco.Red,
                        fontSize = 14.sp,
                        modifier = Modifier.padding(top = 12.dp).fillMaxWidth(),
                        textAlign = TextAlign.Center
                    )
                }
            }
        }
    }
}

@Composable
private fun AuthPill(
    label: String,
    icon: ImageVector? = null,
    kind: AuthPillKind = AuthPillKind.Ink,
    onClick: () -> Unit,
) {
    val brush = if (kind == AuthPillKind.Brand) Coco.BrandBrush else Brush.linearGradient(listOf(if (kind == AuthPillKind.Ink) Coco.Ink else Coco.Hairline, if (kind == AuthPillKind.Ink) Coco.Ink else Coco.Hairline))
    val contentColor = when (kind) {
        AuthPillKind.Brand -> Coco.BrownDeep
        AuthPillKind.Ink -> Color.White
        AuthPillKind.Ghost -> Coco.Ink
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(999.dp))
            .background(brush)
            .clickable(onClick = onClick)
            .padding(horizontal = 24.dp, vertical = 16.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, color = contentColor, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold)
        if (icon != null) {
            Spacer(Modifier.width(8.dp))
            Icon(icon, null, tint = contentColor, modifier = Modifier.size(20.dp))
        }
    }
}

private enum class AuthPillKind { Ink, Brand, Ghost }

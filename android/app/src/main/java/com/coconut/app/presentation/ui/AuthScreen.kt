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
                                val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                                    .requestIdToken("810958888238-c1fmanoapbjbgha6nkbte55o99cqj446.apps.googleusercontent.com")
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

@Composable
private fun AdaptiveScreen(
    background: Color = Coco.Cream,
    content: @Composable () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(background)
            .windowInsetsPadding(WindowInsets.safeDrawing),
        contentAlignment = Alignment.TopCenter
    ) {
        Box(modifier = Modifier.fillMaxSize().widthIn(max = 600.dp)) {
            content()
        }
    }
}

@Composable
private fun CoconutMark(size: Dp, modifier: Modifier = Modifier) {
    Canvas(modifier.size(size)) {
        drawCircle(brush = Coco.BrandBrush)
        val eye = Color(0xFF1A1410)
        fun oval(center: Offset) {
            drawOval(
                color = eye,
                topLeft = Offset(center.x - this.size.width * 0.05f, center.y - this.size.height * 0.07f),
                size = Size(this.size.width * 0.10f, this.size.height * 0.14f),
            )
        }
        oval(Offset(this.size.width * 0.35f, this.size.height * 0.42f))
        oval(Offset(this.size.width * 0.64f, this.size.height * 0.42f))
        oval(Offset(this.size.width * 0.49f, this.size.height * 0.66f))
    }
}

@Composable
private fun ScoreChip(score: Int, big: Boolean = false) {
    val t = tier(score)
    Row(
        modifier = Modifier
            .clip(RoundedCornerShape(999.dp))
            .background(t.color)
            .padding(horizontal = if (big) 14.dp else 10.dp, vertical = if (big) 8.dp else 4.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        Text(score.toString(), color = Color.White, fontSize = if (big) 18.sp else 13.sp, fontWeight = FontWeight.ExtraBold)
        Text("/100", color = Color.White.copy(alpha = 0.8f), fontSize = if (big) 12.sp else 10.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun FloatingScore(score: Int, modifier: Modifier) {
    Box(modifier) { ScoreChip(score, big = true) }
}

private data class Tier(val label: String, val color: Color, val bg: Color, val inkOn: Color)

private fun tier(score: Int): Tier = when {
    score >= 80 -> Tier("Супер", Coco.Emerald, Color(0xFFD7F5E6), Color(0xFF04432A))
    score >= 60 -> Tier("Норма", Color(0xFFA3B91D), Color(0xFFF0F6CF), Color(0xFF3A4407))
    score >= 40 -> Tier("Спорно", Coco.Coral, Color(0xFFFFE2CC), Color(0xFF5A1F00))
    else -> Tier("Мусор", Coco.Red, Color(0xFFFFD9DF), Color(0xFF5C0716))
}

private object Coco {
    val Cream = Color(0xFFFFF6E8)
    val Ink = Color(0xFF1A1410)
    val Ink2 = Color(0xFF3D332B)
    val Hairline = Color(0x151A1410)
    val Lime = Color(0xFFBEF264)
    val Emerald = Color(0xFF10B981)
    val EmeraldDeep = Color(0xFF047857)
    val Coral = Color(0xFFF97316)
    val Red = Color(0xFFE11D48)
    val BrownDeep = Color(0xFF3F2412)
    val BrandBrush = Brush.linearGradient(listOf(Lime, Emerald, EmeraldDeep))
}

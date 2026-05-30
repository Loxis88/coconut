package com.coconut.app.presentation.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.Logout
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.coconut.app.presentation.viewmodel.AuthViewModel

@Composable
fun ProfileScreen(viewModel: AuthViewModel, onBack: () -> Unit, onLogout: () -> Unit) {
    val authState by viewModel.authState.collectAsState()
    
    // In a real app, we'd get the user info from the state or repository
    // For now, let's assume we can get it from the Success state or just show placeholder if loading
    
    AdaptiveScreen {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                RoundIcon(Icons.AutoMirrored.Rounded.ArrowBack, onClick = onBack)
                Text("Профиль", color = Coco.Ink, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.weight(1f))
            }

            Column(
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 20.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(24.dp)
            ) {
                Spacer(modifier = Modifier.height(20.dp))
                
                // Avatar Placeholder
                Box(
                    modifier = Modifier
                        .size(120.dp)
                        .clip(CircleShape)
                        .background(Coco.BrandBrush),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Rounded.Person, null, tint = Coco.BrownDeep, modifier = Modifier.size(60.dp))
                }

                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = "Теофиль", // Placeholder or get from user name
                        color = Coco.Ink,
                        fontSize = 28.sp,
                        fontWeight = FontWeight.ExtraBold
                    )
                    Text(
                        text = "Premium Member", // Placeholder
                        color = Coco.Muted,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                CocoCard(padding = 20.dp) {
                    ProfileInfoRow("Email", "theo@coconut.app") // TODO: Get from auth state
                    DividerLine()
                    ProfileInfoRow("ID", "user_7721_abc") // TODO: Get from auth state
                    DividerLine()
                    ProfileInfoRow("Статус", "Активен")
                }

                Spacer(modifier = Modifier.weight(1f))

                Pill(
                    label = "Выйти из аккаунта",
                    icon = Icons.Rounded.Logout,
                    kind = PillKind.Ghost,
                    large = true,
                    onClick = {
                        viewModel.logout()
                        onLogout()
                    }
                )
                
                Spacer(modifier = Modifier.height(20.dp))
            }
        }
    }
}

@Composable
private fun ProfileInfoRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, color = Coco.Muted, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
        Text(value, color = Coco.Ink, fontSize = 15.sp, fontWeight = FontWeight.Bold)
    }
}

// Reuse the common components (simplified versions for now, or we should move them to a common file)

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
private fun CocoCard(
    modifier: Modifier = Modifier,
    background: Color = Color.White,
    padding: Dp = 18.dp,
    content: @Composable () -> Unit,
) {
    Surface(modifier = modifier.fillMaxWidth(), color = background, shape = RoundedCornerShape(24.dp)) {
        Column(Modifier.padding(padding)) { content() }
    }
}

@Composable
private fun RoundIcon(icon: androidx.compose.ui.graphics.vector.ImageVector, onClick: () -> Unit) {
    IconButton(
        onClick = onClick,
        modifier = Modifier.size(40.dp).clip(CircleShape).background(Coco.Hairline),
    ) {
        Icon(icon, null, tint = Coco.Ink, modifier = Modifier.size(22.dp))
    }
}

@Composable
private fun DividerLine() {
    Box(Modifier.fillMaxWidth().height(1.dp).background(Coco.Hairline))
}

private enum class PillKind { Ink, Brand, Ghost }

@Composable
private fun Pill(
    label: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector? = null,
    kind: PillKind = PillKind.Ink,
    large: Boolean = false,
    onClick: () -> Unit,
) {
    val brush = if (kind == PillKind.Brand) Coco.BrandBrush else Brush.linearGradient(listOf(if (kind == PillKind.Ink) Coco.Ink else Coco.Hairline, if (kind == PillKind.Ink) Coco.Ink else Coco.Hairline))
    val contentColor = when (kind) {
        PillKind.Brand -> Coco.BrownDeep
        PillKind.Ink -> Color.White
        PillKind.Ghost -> Coco.Red // Specific for logout usually
    }
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(999.dp))
            .background(brush)
            .clickable(onClick = onClick)
            .padding(horizontal = 24.dp, vertical = if (large) 16.dp else 12.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, color = contentColor, fontSize = if (large) 17.sp else 15.sp, fontWeight = FontWeight.ExtraBold)
        if (icon != null) {
            Spacer(Modifier.width(8.dp))
            Icon(icon, null, tint = contentColor, modifier = Modifier.size(20.dp))
        }
    }
}

private object Coco {
    val Cream = Color(0xFFFFF6E8)
    val Ink = Color(0xFF1A1410)
    val Muted = Color(0xFF7A6B5C)
    val Hairline = Color(0x151A1410)
    val Lime = Color(0xFFBEF264)
    val Emerald = Color(0xFF10B981)
    val EmeraldDeep = Color(0xFF047857)
    val Red = Color(0xFFE11D48)
    val BrownDeep = Color(0xFF3F2412)
    val BrandBrush = Brush.linearGradient(listOf(Lime, Emerald, EmeraldDeep))
}

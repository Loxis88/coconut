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
import androidx.compose.foundation.clickable
import com.coconut.app.presentation.viewmodel.AuthViewModel
import com.coconut.app.presentation.viewmodel.AuthState

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

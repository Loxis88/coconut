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

import androidx.compose.material.icons.automirrored.rounded.Logout
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.Save
import androidx.compose.material.icons.rounded.Cancel

import androidx.compose.ui.platform.LocalContext
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import androidx.compose.material.icons.rounded.Delete

@Composable
fun ProfileScreen(viewModel: AuthViewModel, onBack: () -> Unit, onLogout: () -> Unit) {
    val context = LocalContext.current
    val user by viewModel.currentUser.collectAsState()
    var isEditingNickname by remember { mutableStateOf(false) }
    var editedNickname by remember { mutableStateOf(user?.nickname ?: "") }
    var showDeleteConfirmation by remember { mutableStateOf(false) }

    LaunchedEffect(user) {
        if (user != null && !isEditingNickname) {
            editedNickname = user?.nickname ?: ""
        }
    }

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
                    if (isEditingNickname) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            androidx.compose.material3.OutlinedTextField(
                                value = editedNickname,
                                onValueChange = { editedNickname = it },
                                modifier = Modifier.widthIn(max = 200.dp),
                                singleLine = true,
                                textStyle = androidx.compose.ui.text.TextStyle(fontSize = 18.sp, fontWeight = FontWeight.Bold)
                            )
                            Spacer(Modifier.width(8.dp))
                            RoundIcon(Icons.Rounded.Save) {
                                viewModel.updateNickname(editedNickname)
                                isEditingNickname = false
                            }
                            Spacer(Modifier.width(4.dp))
                            RoundIcon(Icons.Rounded.Cancel) {
                                editedNickname = user?.nickname ?: ""
                                isEditingNickname = false
                            }
                        }
                    } else {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(
                                text = user?.nickname ?: "User",
                                color = Coco.Ink,
                                fontSize = 28.sp,
                                fontWeight = FontWeight.ExtraBold
                            )
                            Spacer(Modifier.width(8.dp))
                            IconButton(onClick = { isEditingNickname = true }, modifier = Modifier.size(24.dp)) {
                                Icon(Icons.Rounded.Edit, null, tint = Coco.Muted, modifier = Modifier.size(18.dp))
                            }
                        }
                    }
                    Text(
                        text = "Premium Member", // Placeholder
                        color = Coco.Muted,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                CocoCard(padding = 20.dp) {
                    ProfileInfoRow("Email", user?.email ?: "-")
                    DividerLine()
                    val displayId = if (user != null) "COCO-${user?.id?.take(8)?.uppercase()}" else "-"
                    ProfileInfoRow("ID", displayId)
                    DividerLine()
                    ProfileInfoRow("Статус", "Активен")
                }

                Spacer(modifier = Modifier.weight(1f))

                Pill(
                    label = "Выйти из аккаунта",
                    icon = Icons.AutoMirrored.Rounded.Logout,
                    kind = PillKind.Ghost,
                    large = true,
                    onClick = {
                        val clientId = context.resources.getString(com.coconut.app.R.string.google_client_id)
                        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                            .requestIdToken(clientId)
                            .requestEmail()
                            .build()
                        val mGoogleSignInClient = GoogleSignIn.getClient(context, gso)
                        mGoogleSignInClient.signOut().addOnCompleteListener {
                            viewModel.logout()
                            onLogout()
                        }
                    }
                )
                
                Spacer(modifier = Modifier.height(8.dp))

                Pill(
                    label = "Удалить аккаунт",
                    icon = Icons.Rounded.Delete,
                    kind = PillKind.Ghost,
                    large = true,
                    onClick = {
                        showDeleteConfirmation = true
                    }
                )

                Spacer(modifier = Modifier.height(20.dp))
            }
        }
    }

    if (showDeleteConfirmation) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirmation = false },
            title = {
                Text(text = "Удалить аккаунт?", fontWeight = FontWeight.Bold)
            },
            text = {
                Text(text = "Вы уверены, что хотите безвозвратно удалить свой аккаунт и все данные?")
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteConfirmation = false
                        viewModel.deleteAccount(onSuccess = onLogout)
                    }
                ) {
                    Text("Удалить", color = Coco.Red, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(
                    onClick = { showDeleteConfirmation = false }
                ) {
                    Text("Отмена", color = Coco.Ink)
                }
            },
            containerColor = Coco.Cream,
            titleContentColor = Coco.Ink,
            textContentColor = Coco.Ink2
        )
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

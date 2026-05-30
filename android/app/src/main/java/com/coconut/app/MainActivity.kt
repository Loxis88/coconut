package com.coconut.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.enableEdgeToEdge
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.systemBars
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material.icons.rounded.CenterFocusStrong
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.DocumentScanner
import androidx.compose.material.icons.rounded.EditNote
import androidx.compose.material.icons.rounded.FavoriteBorder
import androidx.compose.material.icons.rounded.FlashOff
import androidx.compose.material.icons.rounded.FlashOn
import androidx.compose.material.icons.rounded.Groups
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.LocalFireDepartment
import androidx.compose.material.icons.rounded.NotificationsNone
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.SwapHoriz
import androidx.compose.material.icons.rounded.WarningAmber
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material.icons.rounded.NewReleases
import androidx.compose.material.icons.rounded.Verified
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material.icons.rounded.PriorityHigh
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.Immutable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.navigation.NavController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import kotlinx.coroutines.delay
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.key
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.OutlinedTextField
import coil.compose.AsyncImage
import androidx.compose.ui.layout.ContentScale
import androidx.compose.material3.OutlinedTextFieldDefaults
import com.coconut.app.presentation.viewmodel.CoconutViewModel
import com.coconut.app.presentation.ui.AuthScreen
import com.coconut.app.presentation.ui.SmartScannerFrame
import com.coconut.app.presentation.viewmodel.AuthViewModel
import com.coconut.app.presentation.viewmodel.AuthViewModelFactory
import com.coconut.app.presentation.viewmodel.ProductState
import com.coconut.app.domain.model.Product
import com.coconut.app.domain.model.Nutrients
import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.coconut.app.presentation.ui.CameraView
import com.coconut.app.presentation.ui.ProfileScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent { CoconutApp() }
    }
}

private object Routes {
    const val Home = "home"
    const val Scan = "scan"
    const val Analyzing = "analyzing"
    const val Detail = "detail"
    const val Swap = "swap"
    const val Profile = "profile"
}

@Composable
private fun CoconutApp() {
    val context = LocalContext.current
    val app = context.applicationContext as CoconutApplication
    val viewModel: CoconutViewModel = viewModel(
        factory = CoconutViewModel.Factory(app.container.searchBarcodeUseCase, app.container.productRepository, app.container.authRepository)
    )
    val authViewModel: AuthViewModel = viewModel(
        factory = AuthViewModelFactory(app.container)
    )
    
    var isAuthenticated by remember { mutableStateOf(app.container.authRepository.getAccessToken() != null) }

    if (!isAuthenticated) {
        MaterialTheme {
            AuthScreen(authViewModel) {
                isAuthenticated = true
            }
        }
        return
    }

    MaterialTheme {
        val nav = rememberNavController()
        val state by viewModel.productState.collectAsState()
        
        NavHost(navController = nav, startDestination = Routes.Home) {
            composable(Routes.Home) { 
                val history by viewModel.scanHistory.collectAsState()
                val avg by viewModel.dailyAverage.collectAsState()
                val streak by viewModel.streak.collectAsState()
                val user by authViewModel.currentUser.collectAsState()
                HomeScreen(
                    history = history,
                    dailyAverage = avg,
                    streak = streak,
                    nickname = user?.nickname ?: "Тео",
                    onScan = { nav.navigate(Routes.Scan) },
                    onClearHistory = { viewModel.clearHistory() },
                    onProductClick = { product ->
                        viewModel.showProductDetails(product)
                        nav.navigate(Routes.Detail)
                    },
                    onDeleteProduct = { product ->
                        viewModel.deleteFromHistory(product)
                    },
                    onProfile = { nav.navigate(Routes.Profile) }
                )
            }
            composable(Routes.Scan) {
                ScanScreen(
                    onClose = { nav.popBackStack(Routes.Home, inclusive = false) },
                    onAnalyze = { barcode ->
                        viewModel.searchBarcode(barcode)
                        nav.navigate(Routes.Analyzing)
                    },
                )
            }
            composable(Routes.Analyzing) {
                AnalyzingScreen(
                    state = state,
                    onClose = { 
                        viewModel.resetState()
                        nav.popBackStack(Routes.Home, inclusive = false) 
                    },
                    onDone = {
                        nav.navigate(Routes.Detail) {
                            popUpTo(Routes.Scan) { inclusive = true }
                        }
                    },
                )
            }
            composable(Routes.Detail) {
                FoodDetailScreen(
                    state = state,
                    onBack = { 
                        nav.popBackStack(Routes.Home, inclusive = false) 
                    },
                    onSwap = { nav.navigate(Routes.Swap) },
                )
            }
            composable(Routes.Swap) {
                SwapScreen(
                    onBack = { nav.popBackStack() },
                    onClose = { nav.popBackStack(Routes.Home, inclusive = false) },
                )
            }
            composable(Routes.Profile) {
                ProfileScreen(
                    viewModel = authViewModel,
                    onBack = { nav.popBackStack() },
                    onLogout = { isAuthenticated = false }
                )
            }
        }
    }
}

private object Coco {
    val Cream = Color(0xFFFFF6E8)
    val Cream2 = Color(0xFFFBEFD9)
    val Ink = Color(0xFF1A1410)
    val Ink2 = Color(0xFF3D332B)
    val Muted = Color(0xFF7A6B5C)
    val Hairline = Color(0x151A1410)
    val Lime = Color(0xFFBEF264)
    val Emerald = Color(0xFF10B981)
    val EmeraldDeep = Color(0xFF047857)
    val Amber = Color(0xFFF59E0B)
    val Coral = Color(0xFFF97316)
    val Red = Color(0xFFE11D48)
    val BrownDeep = Color(0xFF3F2412)
    val BrandBrush = Brush.linearGradient(listOf(Lime, Emerald, EmeraldDeep))
    val WarmBrush = Brush.linearGradient(listOf(Color(0xFFFDE68A), Coral))
}

@Immutable
private data class Tier(val label: String, val color: Color, val bg: Color, val inkOn: Color)

private fun tier(score: Int): Tier = when {
    score >= 80 -> Tier("Супер", Coco.Emerald, Color(0xFFD7F5E6), Color(0xFF04432A))
    score >= 60 -> Tier("Норма", Color(0xFFA3B91D), Color(0xFFF0F6CF), Color(0xFF3A4407))
    score >= 40 -> Tier("Спорно", Coco.Coral, Color(0xFFFFE2CC), Color(0xFF5A1F00))
    else -> Tier("Мусор", Coco.Red, Color(0xFFFFD9DF), Color(0xFF5C0716))
}

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

private data class AxisScore(val label: String, val value: Int, val note: String, val bad: Boolean = false)


@Composable
private fun HomeScreen(
    history: List<Product>, 
    dailyAverage: Int, 
    streak: Int, 
    nickname: String,
    onScan: () -> Unit,
    onClearHistory: () -> Unit,
    onProductClick: (Product) -> Unit,
    onDeleteProduct: (Product) -> Unit,
    onProfile: () -> Unit
) {
    val context = LocalContext.current
    AdaptiveScreen {
        Column(
            modifier = Modifier.fillMaxSize()
        ) {
            Row(
            modifier = Modifier.padding(start = 20.dp, top = 16.dp, end = 20.dp, bottom = 18.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            CoconutMark(36.dp)
            Text("Coconut", color = Coco.Ink, fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.weight(1f))
            Row(
                modifier = Modifier
                    .clip(RoundedCornerShape(999.dp))
                    .background(Color.White)
                    .clickable { android.widget.Toast.makeText(context, "Стрик: $streak дней", android.widget.Toast.LENGTH_SHORT).show() }
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Icon(Icons.Rounded.LocalFireDepartment, null, tint = if (streak > 0) Coco.Coral else Coco.Muted, modifier = Modifier.size(16.dp))
                Text(streak.toString(), color = Coco.Ink, fontSize = 14.sp, fontWeight = FontWeight.Bold)
            }
            RoundIcon(Icons.Rounded.NotificationsNone) { android.widget.Toast.makeText(context, "Нет новых уведомлений", android.widget.Toast.LENGTH_SHORT).show() }
        }

        LazyColumn(
            modifier = Modifier.weight(1f),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(start = 20.dp, end = 20.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            item {
                Text("Сегодня", color = Coco.Muted, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                Text("Привет, $nickname —\nвсё идет по плану.", color = Coco.Ink, fontSize = 34.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 36.sp)
            }
            item {
                CocoCard(background = Coco.BrandBrush, padding = 22.dp) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(18.dp)) {
                        ScoreRing(if (history.isEmpty()) 0 else dailyAverage, size = 120.dp, showLabel = false)
                        Column {
                            Text("СРЕДНИЙ БАЛЛ", color = Coco.BrownDeep, fontSize = 12.sp, fontWeight = FontWeight.ExtraBold)
                            Text(if (history.isEmpty()) "Сканируй" else "Пока\nнеплохо.", color = Coco.BrownDeep, fontSize = 26.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 28.sp)
                            Text("${history.size} total scans", color = Coco.BrownDeep.copy(alpha = 0.78f), fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                        }
                    }
                }
            }
            item {
                CocoCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("Эта неделя", color = Coco.Ink, fontSize = 16.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                        Text("ср. балл ${if (history.isEmpty()) 0 else dailyAverage}", color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    }
                    Spacer(Modifier.height(12.dp))
                    WeekBars(listOf(0, 0, 0, 0, 0, 0, if (history.isEmpty()) 0 else dailyAverage))
                }
            }
            item {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text("История", color = Coco.Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.weight(1f))
                    Text("Очистить", color = Coco.Red, fontSize = 13.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.clip(RoundedCornerShape(6.dp)).clickable { onClearHistory() }.padding(6.dp))
                }
                Spacer(Modifier.height(8.dp))
                CocoCard(padding = 6.dp) {
                    if (history.isEmpty()) {
                        Text("Пока ничего нет. Нажми кнопку сканирования, чтобы начать!", color = Coco.Muted, fontSize = 14.sp, modifier = Modifier.padding(16.dp))
                    } else {
                        history.forEachIndexed { index, product ->
                            key(product.id) {
                                val dismissState = rememberSwipeToDismissBoxState(
                                    confirmValueChange = { dismissValue ->
                                        if (dismissValue == SwipeToDismissBoxValue.EndToStart) {
                                            onDeleteProduct(product)
                                            true
                                        } else false
                                    }
                                )
                                SwipeToDismissBox(
                                    state = dismissState,
                                    enableDismissFromStartToEnd = false,
                                    backgroundContent = {
                                        Box(
                                            modifier = Modifier
                                                .fillMaxSize()
                                                .padding(horizontal = 16.dp, vertical = 14.dp)
                                                .clip(RoundedCornerShape(16.dp))
                                                .background(Coco.Red)
                                                .padding(end = 20.dp),
                                            contentAlignment = Alignment.CenterEnd
                                        ) {
                                            Icon(Icons.Rounded.Delete, contentDescription = "Delete", tint = Color.White)
                                        }
                                    }
                                ) {
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .clip(RoundedCornerShape(16.dp))
                                            .background(Color.White)
                                            .clickable { onProductClick(product) }
                                            .padding(horizontal = 16.dp, vertical = 14.dp),
                                        verticalAlignment = Alignment.CenterVertically,
                                        horizontalArrangement = Arrangement.spacedBy(14.dp)
                                    ) {
                                        if (product.thumbnail != null) {
                                            AsyncImage(
                                                model = product.thumbnail,
                                                contentDescription = null,
                                                contentScale = ContentScale.Crop,
                                                modifier = Modifier.size(52.dp).clip(RoundedCornerShape(16.dp))
                                            )
                                        } else {
                                            FoodThumb(product.title.take(1), size = 52.dp, radius = 16.dp)
                                        }
                                        Column(Modifier.weight(1f)) {
                                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                                Text(product.title, color = Coco.Ink, fontSize = 16.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, false))
                                                if (product.hasQualityMark) Icon(Icons.Rounded.Verified, null, tint = Coco.Emerald, modifier = Modifier.size(16.dp))
                                                if (product.hasBadQualityMark) Icon(Icons.Rounded.NewReleases, null, tint = Coco.Red, modifier = Modifier.size(16.dp))
                                            }
                                            Text(product.manufacturer.ifEmpty { product.categoryName }.ifEmpty { "НЕИЗВЕСТНО" }, color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                                        }
                                        ScoreChip((product.totalRating * 20).toInt())
                                    }
                                }
                                if (index != history.lastIndex) DividerLine()
                            }
                        }
                    }
                }
            }
        }
        BottomNav(active = "home", onScan = onScan, onProfile = onProfile)
        }
    }
}

@Composable
private fun ScanScreen(onClose: () -> Unit, onAnalyze: (String) -> Unit) {
    var barcode by remember { mutableStateOf("") }
    var isManualMode by remember { mutableStateOf(false) }
    var isFlashlightOn by remember { mutableStateOf(false) }
    var detectedRect by remember { mutableStateOf<android.graphics.Rect?>(null) }
    var previewSize by remember { mutableStateOf(androidx.compose.ui.unit.IntSize.Zero) }
    
    val context = LocalContext.current
    var hasCameraPermission by remember {
        mutableStateOf(ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED)
    }

    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
        hasCameraPermission = isGranted
    }

    LaunchedEffect(Unit) {
        if (!hasCameraPermission) {
            permissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0C0A08))
            .windowInsetsPadding(WindowInsets.safeDrawing),
    ) {
        if (!isManualMode && hasCameraPermission) {
            CameraView(
                modifier = Modifier.fillMaxSize(),
                isFlashlightOn = isFlashlightOn,
                onBarcodeDetected = { rect, size ->
                    detectedRect = rect
                    previewSize = size
                },
                onBarcodeScanned = { scannedBarcode ->
                    onAnalyze(scannedBarcode)
                }
            )
            // Smart frame tracking the barcode
            SmartScannerFrame(
                detectedRect = detectedRect,
                previewSize = previewSize
            )
        } else {
            Canvas(Modifier.fillMaxSize()) {
                drawCircle(Color(0xFF5A4A3E), radius = size.maxDimension * 0.6f, center = Offset(size.width * 0.3f, size.height * 0.36f))
                drawRect(Color(0x990A0805))
            }
            ProductSilhouette(Modifier.align(Alignment.Center).offset(y = (-24).dp))
        }
        
        Row(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            RoundIcon(Icons.Rounded.Close, dark = true, onClick = onClose)
            Spacer(Modifier.weight(1f))
            RoundIcon(
                icon = if (isFlashlightOn) Icons.Rounded.FlashOff else Icons.Rounded.FlashOn,
                dark = true,
                onClick = { isFlashlightOn = !isFlashlightOn }
            )
        }
        
        if (!isManualMode && hasCameraPermission && detectedRect == null) {
            Text(
                "Наведите на штрих-код",
                color = Color.White,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(bottom = 260.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(Color.Black.copy(alpha = 0.55f))
                    .padding(horizontal = 16.dp, vertical = 8.dp),
            )
        }
        
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .widthIn(max = 600.dp)
                .clip(RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp))
                .background(Color.White)
                .padding(20.dp),
        ) {
            AnimatedTabToggle(
                isManualMode = isManualMode,
                onModeChange = { isManualMode = it }
            )
            Spacer(Modifier.height(24.dp))
            
            AnimatedContent(
                targetState = isManualMode || !hasCameraPermission,
                transitionSpec = {
                    (fadeIn(animationSpec = tween(400, easing = FastOutSlowInEasing)) + 
                     slideInVertically(animationSpec = tween(400, easing = FastOutSlowInEasing)) { it / 8 } +
                     scaleIn(initialScale = 0.95f, animationSpec = tween(400, easing = FastOutSlowInEasing)))
                    .togetherWith(
                     fadeOut(animationSpec = tween(250)) + 
                     slideOutVertically(animationSpec = tween(250)) { -it / 8 } +
                     scaleOut(targetScale = 0.95f, animationSpec = tween(250)))
                },
                label = "ScanModeTransition"
            ) { showManual ->
                if (showManual) {
                    Column {
                        OutlinedTextField(
                            value = barcode,
                            onValueChange = { barcode = it },
                            label = { Text("Введите штрих-код") },
                            placeholder = { Text("напр. 4603955002165") },
                            modifier = Modifier.fillMaxWidth().padding(bottom = 16.dp),
                            singleLine = true,
                            shape = RoundedCornerShape(16.dp),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = Coco.Emerald,
                                unfocusedBorderColor = Coco.Hairline
                            )
                        )
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                            Column(Modifier.weight(1f)) {
                                Text(if (!hasCameraPermission) "Камера заблокирована" else "Ручной ввод", color = Coco.Ink, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold)
                                Text(if (!hasCameraPermission) "Разрешите камеру или введите код." else "Введите штрих-код для поиска.", color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                            }
                            Box(
                                modifier = Modifier
                                    .size(70.dp)
                                    .clip(CircleShape)
                                    .background(if (barcode.isNotBlank()) Coco.BrandBrush else Brush.linearGradient(listOf(Coco.Hairline, Coco.Hairline)))
                                    .clickable(enabled = barcode.isNotBlank(), onClick = { onAnalyze(barcode) }),
                                contentAlignment = Alignment.Center,
                            ) {
                                Icon(Icons.Rounded.CenterFocusStrong, null, tint = Coco.BrownDeep, modifier = Modifier.size(30.dp))
                            }
                        }
                    }
                } else {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                        Column(Modifier.weight(1f)) {
                            Text("Автоскан активен", color = Coco.Ink, fontSize = 20.sp, fontWeight = FontWeight.ExtraBold)
                            Text("Наведите камеру на штрих-код.", color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                        }
                        Box(
                            modifier = Modifier
                                .size(70.dp)
                                .clip(CircleShape)
                                .background(Coco.BrandBrush),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Rounded.CameraAlt, null, tint = Coco.BrownDeep, modifier = Modifier.size(30.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun AnalyzingScreen(state: ProductState, onClose: () -> Unit, onDone: () -> Unit) {
    LaunchedEffect(state) {
        if (state is ProductState.Success || state is ProductState.Error) {
            delay(600)
            onDone()
        }
    }
    AdaptiveScreen {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .clickable(onClick = onDone),
        ) {
            Row(
                modifier = Modifier.padding(start = 20.dp, top = 16.dp, end = 20.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                RoundIcon(Icons.Rounded.Close, onClick = onClose)
                Spacer(Modifier.weight(1f))
                BrandTag("Анализ")
            }
            CocoCard(modifier = Modifier.padding(20.dp), padding = 20.dp) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    Box(Modifier.size(72.dp).clip(RoundedCornerShape(20.dp)).background(Coco.Hairline), contentAlignment = Alignment.Center) {
                        Icon(Icons.Rounded.Search, null, tint = Coco.Muted)
                    }
                    Column {
                        Text("ПОИСК", color = Coco.Muted, fontSize = 12.sp, fontWeight = FontWeight.ExtraBold)
                        Text("Проверка базы данных...", color = Coco.Ink, fontSize = 19.sp, fontWeight = FontWeight.ExtraBold)
                        Text("API Роскачества", color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                    }
                }
            }
            Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                Canvas(Modifier.size(280.dp)) {
                    drawCircle(brush = Brush.radialGradient(listOf(Coco.Lime.copy(alpha = 0.40f), Color.Transparent)))
                }
                CoconutMark(140.dp)
            }
            Column(Modifier.padding(horizontal = 20.dp)) {
                Text("ИЗУЧАЕМ СОСТАВ", color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.ExtraBold)
                Spacer(Modifier.height(12.dp))
                ProgressStep("Отправка запроса на rskrf.ru", done = true)
                ProgressStep("Ожидание ответа", active = state is ProductState.Loading)
                ProgressStep("Готово", active = state is ProductState.Success)
            }
            Column(Modifier.padding(20.dp)) {
                ProgressBar(if (state is ProductState.Loading) 0.5f else 1f, height = 8.dp, color = Coco.Emerald)
                Text(
                    "Пожалуйста, подождите...",
                    color = Coco.Muted,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.fillMaxWidth().padding(top = 10.dp),
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
}

@Composable
private fun FoodDetailScreen(state: ProductState, onBack: () -> Unit, onSwap: () -> Unit) {
    if (state is ProductState.Error) {
        AdaptiveScreen {
            Column(Modifier.fillMaxSize().padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                Text("Ошибка", color = Coco.Red, fontSize = 24.sp, fontWeight = FontWeight.Bold)
                Text(state.message, color = Coco.Ink)
                Spacer(Modifier.height(16.dp))
                Pill("Назад", icon = Icons.AutoMirrored.Rounded.ArrowBack) { onBack() }
            }
        }
        return
    }
    
    val product = (state as? ProductState.Success)?.product
    val score = ((product?.totalRating ?: 0.0) * 20).toInt()
    val t = tier(score)
    
    AdaptiveScreen {
        Column(
            modifier = Modifier
                .fillMaxSize()
        ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            RoundIcon(Icons.AutoMirrored.Rounded.ArrowBack, onClick = onBack)
            Spacer(Modifier.weight(1f))
            RoundIcon(Icons.Rounded.FavoriteBorder) {}
            RoundIcon(Icons.Rounded.SwapHoriz, onClick = onSwap)
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(start = 20.dp, end = 20.dp, bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp), verticalAlignment = Alignment.Top) {
                if (product?.thumbnail != null) {
                    android.util.Log.d("COCO_IMG", "Detail Image URL: ${product.thumbnail}")
                    AsyncImage(
                        model = product.thumbnail,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.size(88.dp).clip(RoundedCornerShape(22.dp))
                    )
                } else {
                    FoodThumb(product?.title?.take(1) ?: "P", size = 88.dp, radius = 22.dp)
                }
                Column(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text((product?.manufacturer ?: product?.categoryName ?: "НЕИЗВЕСТНО").uppercase(), color = Coco.Muted, fontSize = 12.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.weight(1f, false))
                        if (product?.hasQualityMark == true) Icon(Icons.Rounded.Verified, null, tint = Coco.Emerald, modifier = Modifier.size(18.dp))
                        if (product?.hasBadQualityMark == true) Icon(Icons.Rounded.NewReleases, null, tint = Coco.Red, modifier = Modifier.size(18.dp))
                    }
                    Text(product?.title ?: "Unknown Product", color = Coco.Ink, fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 27.sp)
                    Text(product?.price ?: "", color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                }
            }
            CocoCard(background = t.bg, padding = 20.dp) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    ScoreRing(score, size = 104.dp, showLabel = false)
                    Column(Modifier.weight(1f)) {
                        Text("${t.label}.", color = t.inkOn, fontSize = 26.sp, fontWeight = FontWeight.ExtraBold)
                        Text(
                            product?.worth?.firstOrNull() ?: "Рейтинг по стандартам Роскачества.",
                            color = t.inkOn.copy(alpha = 0.75f),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            lineHeight = 18.sp,
                        )
                    }
                }
            }
            
            if (product?.nutrients != null) {
                SectionTitle("Пищевая ценность")
                NutritionalGrid(product.nutrients)
            }

            if (!product?.composition.isNullOrEmpty()) {
                SectionTitle("Состав")
                CocoCard(padding = 16.dp) {
                    Text(product.composition!!, color = Coco.Ink, fontSize = 14.sp, lineHeight = 20.sp)
                }
            }

            SectionTitle("Критерии качества")
            CocoCard(padding = 16.dp) {
                val ratings = product?.criteriaRatings ?: emptyList()
                if (ratings.isEmpty()) {
                    Text("Детальные критерии отсутствуют.", color = Coco.Muted, fontSize = 14.sp)
                } else {
                    ratings.forEachIndexed { index, axis ->
                        AxisRow(AxisScore(axis.title, (axis.value * 20).toInt(), "${axis.value} / 5", bad = axis.value < 3.0))
                        if (index != ratings.lastIndex) DividerLine()
                    }
                }
            }
            if (!product?.worth.isNullOrEmpty()) {
                SectionTitle("Стоит отметить")
                product?.worth?.forEach { worth ->
                    Flag(Coco.Emerald, Icons.Rounded.Check, "Плюсы", worth)
                }
            }
        }
        }
    }
}

@Composable
private fun NutritionalGrid(nutrients: Nutrients) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        NutrientCell("Белки", nutrients.proteins ?: "-", Modifier.weight(1f))
        NutrientCell("Жиры", nutrients.fats ?: "-", Modifier.weight(1f))
        NutrientCell("Углеводы", nutrients.carbohydrates ?: "-", Modifier.weight(1f))
    }
    Spacer(Modifier.height(10.dp))
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        NutrientCell("Ккал", nutrients.calories ?: "-", Modifier.weight(1f))
        if (nutrients.fiber != null) {
            NutrientCell("Клетчатка", nutrients.fiber, Modifier.weight(1f))
        }
    }
}

@Composable
private fun NutrientCell(label: String, value: String, modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White)
            .padding(12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(label.uppercase(), color = Coco.Muted, fontSize = 10.sp, fontWeight = FontWeight.ExtraBold)
        Text(value, color = Coco.Ink, fontSize = 16.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun SwapScreen(onBack: () -> Unit, onClose: () -> Unit) {
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
            Text("Лучшая замена", color = Coco.Ink, fontSize = 17.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.weight(1f))
            RoundIcon(Icons.Rounded.Close, onClick = onClose)
        }
        Column(
            modifier = Modifier
                .weight(1f)
                .verticalScroll(rememberScrollState())
                .padding(start = 20.dp, end = 20.dp, bottom = 20.dp),
        ) {
            BrandTag("+39 better")
            Text(
                "Попробуйте RXBAR\nвместо Picky.",
                color = Coco.Ink,
                fontSize = 34.sp,
                fontWeight = FontWeight.ExtraBold,
                lineHeight = 36.sp,
                modifier = Modifier.padding(top = 12.dp),
            )
            Text(
                "Такой же вкус, но чище состав и в 3 раза больше белка.",
                color = Coco.Muted,
                fontSize = 14.sp,
                fontWeight = FontWeight.Medium,
                lineHeight = 20.sp,
                modifier = Modifier.padding(top = 8.dp, bottom = 22.dp),
            )
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SwapCol("Picky", "Злаковый батончик", 42, "P", dim = true, modifier = Modifier.weight(1f))
                Box(
                    modifier = Modifier.size(36.dp).clip(CircleShape).background(Coco.Ink),
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.AutoMirrored.Rounded.ArrowForward, null, tint = Color.White, modifier = Modifier.size(18.dp)) }
                SwapCol("RXBAR", "Шоколад и соль", 81, "R", winner = true, modifier = Modifier.weight(1f))
            }
            Spacer(Modifier.height(22.dp))
            SectionTitle("Что изменится")
            CocoCard(padding = 0.dp) {
                DeltaRow("Доб. сахар", "11g", "3g", good = true)
                DividerLine()
                DeltaRow("Белок", "3g", "12g", good = true)
                DividerLine()
                DeltaRow("Ингредиенты", "14", "6", good = true)
                DividerLine()
                DeltaRow("Ккал", "168", "210")
            }
            Spacer(Modifier.height(18.dp))
            Pill("Сохранить для покупок", icon = Icons.Rounded.FavoriteBorder, kind = PillKind.Brand, large = true) {}
            Spacer(Modifier.height(10.dp))
            Pill("Посмотреть еще 4 замены", kind = PillKind.Ghost) {}
        }
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
private fun ScoreRing(score: Int, size: Dp, thickness: Dp = 12.dp, showLabel: Boolean = true) {
    val t = tier(score)
    Box(Modifier.size(size), contentAlignment = Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val stroke = thickness.toPx()
            val arcSize = Size(this.size.width - stroke, this.size.height - stroke)
            val topLeft = Offset(stroke / 2f, stroke / 2f)
            drawArc(Coco.Hairline, -90f, 360f, false, topLeft, arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
            drawArc(t.color, -90f, 360f * (score / 100f), false, topLeft, arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
        }
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(score.toString(), color = Coco.Ink, fontSize = (size.value * 0.42f).sp, fontWeight = FontWeight.ExtraBold, lineHeight = (size.value * 0.38f).sp)
            if (showLabel) Text(t.label.uppercase(), color = t.color, fontSize = (size.value * 0.10f).sp, fontWeight = FontWeight.Bold)
        }
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
private fun FoodThumb(label: String, size: Dp, radius: Dp) {
    val palettes = listOf(
        Color(0xFFFFE4B5) to Color(0xFFF97316),
        Color(0xFFD9F99D) to Color(0xFF65A30D),
        Color(0xFFFECACA) to Color(0xFFDC2626),
        Color(0xFFE0F2FE) to Color(0xFF0284C7),
        Color(0xFFFEF3C7) to Color(0xFFA16207),
    )
    val pair = palettes[(label.firstOrNull()?.code ?: 0) % palettes.size]
    Box(
        modifier = Modifier.size(size).clip(RoundedCornerShape(radius)).background(pair.first),
        contentAlignment = Alignment.Center,
    ) {
        Canvas(Modifier.fillMaxSize()) {
            drawCircle(Color.White.copy(alpha = 0.55f), radius = this.size.minDimension * 0.55f, center = Offset(this.size.width * 0.28f, this.size.height * 0.25f))
        }
        Text(label.take(1), color = pair.second, fontSize = (size.value * 0.38f).sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
private fun FloatingScore(score: Int, modifier: Modifier) {
    Box(modifier) { ScoreChip(score, big = true) }
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
private fun CocoCard(
    modifier: Modifier = Modifier,
    background: Brush,
    padding: Dp = 18.dp,
    content: @Composable () -> Unit,
) {
    Column(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(28.dp))
            .background(background)
            .padding(padding),
    ) { content() }
}

private enum class PillKind { Ink, Brand, Ghost }

@Composable
private fun Pill(
    label: String,
    icon: ImageVector? = null,
    kind: PillKind = PillKind.Ink,
    large: Boolean = false,
    onClick: () -> Unit,
) {
    val brush = if (kind == PillKind.Brand) Coco.BrandBrush else Brush.linearGradient(listOf(if (kind == PillKind.Ink) Coco.Ink else Coco.Hairline, if (kind == PillKind.Ink) Coco.Ink else Coco.Hairline))
    val contentColor = when (kind) {
        PillKind.Brand -> Coco.BrownDeep
        PillKind.Ink -> Color.White
        PillKind.Ghost -> Coco.Ink
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

@Composable
private fun RoundIcon(icon: ImageVector, dark: Boolean = false, onClick: () -> Unit) {
    IconButton(
        onClick = onClick,
        modifier = Modifier.size(40.dp).clip(CircleShape).background(if (dark) Color.White.copy(alpha = 0.15f) else Coco.Hairline),
    ) {
        Icon(icon, null, tint = if (dark) Color.White else Coco.Ink, modifier = Modifier.size(22.dp))
    }
}

@Composable
private fun WeekBars(values: List<Int>) {
    val labels = listOf("П", "В", "С", "Ч", "П", "С", "В")
    Row(
        modifier = Modifier.fillMaxWidth().height(86.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        values.forEachIndexed { index, value ->
            Column(Modifier.weight(1f).fillMaxHeight(), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.BottomCenter) {
                    Box(
                        Modifier
                            .fillMaxWidth()
                            .fillMaxHeight(value / 100f)
                            .clip(RoundedCornerShape(8.dp))
                            .background(tier(value).color),
                    )
                }
                Text(labels[index], color = if (index == values.lastIndex) Coco.Ink else Coco.Muted, fontSize = 11.sp, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
private fun BottomNav(active: String, onScan: () -> Unit, onProfile: () -> Unit) {
    val context = LocalContext.current
    fun toast(msg: String) = android.widget.Toast.makeText(context, msg, android.widget.Toast.LENGTH_SHORT).show()
    Row(
        modifier = Modifier.fillMaxWidth().background(Color.White).padding(top = 8.dp, bottom = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceAround,
    ) {
        NavItem(Icons.Rounded.Home, "Главная", active == "home") {}
        NavItem(Icons.Rounded.EditNote, "Журнал", false) { toast("Журнал скоро появится") }
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .offset(y = (-12).dp)
                .clip(RoundedCornerShape(16.dp))
                .clickable(onClick = onScan)
                .padding(4.dp)
        ) {
            Box(Modifier.size(56.dp).clip(CircleShape).background(Coco.BrandBrush), contentAlignment = Alignment.Center) {
                Icon(Icons.Rounded.CenterFocusStrong, null, tint = Coco.BrownDeep)
            }
            Text("Скан", color = Coco.Ink, fontSize = 11.sp, fontWeight = FontWeight.Bold)
        }
        NavItem(Icons.Rounded.Groups, "Друзья", false) { toast("Раздел друзей скоро появится") }
        NavItem(Icons.Rounded.Person, "Профиль", active == "profile", onClick = onProfile)
    }
}

@Composable
private fun NavItem(icon: ImageVector, label: String, active: Boolean, onClick: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.widthIn(min = 56.dp).clip(RoundedCornerShape(8.dp)).clickable(onClick = onClick).padding(4.dp)) {
        Icon(icon, null, tint = if (active) Coco.Ink else Coco.Muted, modifier = Modifier.size(23.dp))
        Text(label, color = if (active) Coco.Ink else Coco.Muted, fontSize = 11.sp, fontWeight = if (active) FontWeight.Bold else FontWeight.Medium)
    }
}

@Composable
private fun ProductSilhouette(modifier: Modifier) {
    Box(
        modifier = modifier.size(width = 140.dp, height = 220.dp).clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp, bottomStart = 8.dp, bottomEnd = 8.dp)).background(
            Brush.verticalGradient(listOf(Color(0x66FFC896), Color(0x73503032))),
        ),
    ) {
        Box(Modifier.fillMaxWidth().height(30.dp).padding(horizontal = 24.dp).offset(y = 24.dp).clip(RoundedCornerShape(4.dp)).background(Color(0x66C8A05A)))
        Box(Modifier.fillMaxWidth().height(6.dp).padding(horizontal = 24.dp).align(Alignment.Center).clip(RoundedCornerShape(2.dp)).background(Color.Black.copy(alpha = 0.35f)))
    }
}

@Composable
private fun ScanReticle(modifier: Modifier) {
    Canvas(modifier.size(250.dp)) {
        val stroke = 4.dp.toPx()
        val len = 36.dp.toPx()
        fun corner(x: Float, y: Float, sx: Float, sy: Float) {
            drawLine(Coco.Lime, Offset(x, y), Offset(x + len * sx, y), strokeWidth = stroke, cap = StrokeCap.Round)
            drawLine(Coco.Lime, Offset(x, y), Offset(x, y + len * sy), strokeWidth = stroke, cap = StrokeCap.Round)
        }
        corner(0f, 0f, 1f, 1f)
        corner(size.width, 0f, -1f, 1f)
        corner(0f, size.height, 1f, -1f)
        corner(size.width, size.height, -1f, -1f)
        drawLine(Coco.Lime, Offset(8.dp.toPx(), size.height / 2f), Offset(size.width - 8.dp.toPx(), size.height / 2f), strokeWidth = 2.dp.toPx())
    }
}

@Composable
private fun AnimatedTabToggle(
    isManualMode: Boolean,
    onModeChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    BoxWithConstraints(
        modifier = modifier
            .fillMaxWidth()
            .height(54.dp)
            .clip(RoundedCornerShape(999.dp))
            .background(Coco.Cream)
            .padding(4.dp)
    ) {
        val halfWidth = maxWidth / 2
        val offset by animateDpAsState(
            targetValue = if (isManualMode) halfWidth else 0.dp,
            animationSpec = spring(dampingRatio = 0.8f, stiffness = 380f)
        )

        // The Sliding "Thumb"
        Box(
            modifier = Modifier
                .offset(x = offset)
                .width(halfWidth)
                .fillMaxHeight()
                .clip(RoundedCornerShape(999.dp))
                .background(Color.White)
        )

        Row(modifier = Modifier.fillMaxSize()) {
            ModeTab(
                icon = Icons.Rounded.DocumentScanner,
                label = "Автоскан",
                active = !isManualMode,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clickable { onModeChange(false) }
            )
            ModeTab(
                icon = Icons.Rounded.EditNote,
                label = "Вручную",
                active = isManualMode,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .clickable { onModeChange(true) }
            )
        }
    }
}

@Composable
private fun ModeTab(icon: ImageVector, label: String, active: Boolean, modifier: Modifier) {
    val color by animateColorAsState(if (active) Coco.Ink else Coco.Muted, label = "TabColor")
    
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = color, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(8.dp))
        Text(label, color = color, fontSize = 14.sp, fontWeight = if (active) FontWeight.ExtraBold else FontWeight.Bold)
    }
}

@Composable
private fun BrandTag(text: String) {
    Text(
        text.uppercase(),
        color = Coco.BrownDeep,
        fontSize = 12.sp,
        fontWeight = FontWeight.ExtraBold,
        modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(Coco.BrandBrush).padding(horizontal = 12.dp, vertical = 4.dp),
    )
}

@Composable
private fun ProgressStep(label: String, done: Boolean = false, active: Boolean = false) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp), modifier = Modifier.padding(vertical = 3.dp)) {
        Box(
            Modifier.size(20.dp).clip(CircleShape).background(if (done) Coco.Emerald else if (active) Coco.Amber else Coco.Hairline),
            contentAlignment = Alignment.Center,
        ) {
            if (done) Icon(Icons.Rounded.Check, null, tint = Color.White, modifier = Modifier.size(12.dp))
            if (active) Box(Modifier.size(8.dp).clip(CircleShape).background(Color.White))
        }
        Text(label, color = if (done || active) Coco.Ink else Coco.Muted, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
    }
}

@Composable
private fun AxisRow(axis: AxisScore) {
    val t = tier(axis.value)
    val color = if (axis.bad) Coco.Red else t.color
    Column(Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 10.dp)) {
        Row {
            Text(axis.label, color = Coco.Ink, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            Text(axis.value.toString(), color = color, fontSize = 13.sp, fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.height(6.dp))
        ProgressBar(axis.value / 100f, height = 8.dp, color = color)
        Text(axis.note, color = Coco.Muted, fontSize = 12.sp, fontWeight = FontWeight.Medium, modifier = Modifier.padding(top = 6.dp))
    }
}

@Composable
private fun ProgressBar(progress: Float, height: Dp, color: Color) {
    Box(Modifier.fillMaxWidth().height(height).clip(RoundedCornerShape(height / 2)).background(Coco.Hairline)) {
        Box(Modifier.fillMaxWidth(progress.coerceIn(0f, 1f)).fillMaxHeight().clip(RoundedCornerShape(height / 2)).background(color))
    }
}

@Composable
private fun Flag(color: Color, icon: ImageVector, title: String, sub: String) {
    CocoCard(padding = 14.dp) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(Modifier.size(36.dp).clip(CircleShape).background(color), contentAlignment = Alignment.Center) {
                Icon(icon, null, tint = Color.White, modifier = Modifier.size(18.dp))
            }
            Column(Modifier.weight(1f)) {
                Text(title, color = Coco.Ink, fontSize = 15.sp, fontWeight = FontWeight.ExtraBold)
                Text(sub, color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.Medium)
            }
        }
    }
}

@Composable
private fun SwapCol(name: String, sub: String, score: Int, thumb: String, dim: Boolean = false, winner: Boolean = false, modifier: Modifier = Modifier) {
    val t = tier(score)
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(22.dp))
            .background(if (winner) Color.White else Coco.Cream2)
            .padding(14.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        FoodThumb(thumb, size = 64.dp, radius = 18.dp)
        Text(name, color = Coco.Ink.copy(alpha = if (dim) 0.72f else 1f), fontSize = 14.sp, fontWeight = FontWeight.ExtraBold, textAlign = TextAlign.Center)
        Text(sub, color = Coco.Muted.copy(alpha = if (dim) 0.72f else 1f), fontSize = 11.sp, fontWeight = FontWeight.Medium, textAlign = TextAlign.Center, minLines = 2)
        Text(score.toString(), color = t.color, fontSize = 32.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
private fun DeltaRow(label: String, from: String, to: String, good: Boolean = false) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(label, color = Coco.Ink, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        Text(from, color = Coco.Muted, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, textDecoration = TextDecoration.LineThrough)
        Icon(Icons.AutoMirrored.Rounded.ArrowForward, null, tint = Coco.Muted, modifier = Modifier.size(14.dp))
        Text(to, color = if (good) Coco.Emerald else Coco.Ink, fontSize = 14.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
private fun SectionTitle(text: String) {
    Text(text, color = Coco.Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.padding(bottom = 10.dp))
}

@Composable
private fun DividerLine() {
    Box(Modifier.fillMaxWidth().height(1.dp).background(Coco.Hairline))
}

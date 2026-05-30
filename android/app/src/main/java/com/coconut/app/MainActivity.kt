package com.coconut.app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.activity.enableEdgeToEdge
import androidx.activity.compose.setContent
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.*
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.scaleIn
import androidx.compose.animation.scaleOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import coil.compose.AsyncImage
import com.coconut.app.domain.model.Nutrients
import com.coconut.app.domain.model.Product
import com.coconut.app.presentation.ui.*
import com.coconut.app.presentation.viewmodel.*
import kotlinx.coroutines.delay

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
                    nickname = user?.nickname ?: "Пользователь",
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
                    state = state,
                    onClose = { 
                        viewModel.resetState()
                        nav.popBackStack(Routes.Home, inclusive = false) 
                    },
                    onAnalyze = { barcode ->
                        viewModel.searchBarcode(barcode)
                    },
                    onResetState = { viewModel.resetState() },
                    onSwap = { nav.navigate(Routes.Swap) }
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
            contentPadding = PaddingValues(start = 20.dp, end = 20.dp, bottom = 16.dp),
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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ScanScreen(
    state: ProductState,
    onClose: () -> Unit,
    onAnalyze: (String) -> Unit,
    onResetState: () -> Unit,
    onSwap: () -> Unit
) {
    var barcode by remember { mutableStateOf("") }
    var isManualMode by remember { mutableStateOf(false) }
    var isFlashlightOn by remember { mutableStateOf(false) }
    var detectedRect by remember { mutableStateOf<android.graphics.Rect?>(null) }
    var previewSize by remember { mutableStateOf(IntSize.Zero) }
    
    val context = LocalContext.current
    var hasCameraPermission by remember {
        mutableStateOf(ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED)
    }

    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
        hasCameraPermission = isGranted
    }

    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    var showSheet by remember { mutableStateOf(false) }

    LaunchedEffect(state) {
        if (state is ProductState.Success) {
            showSheet = true
        }
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
                isScanning = !showSheet && state !is ProductState.Loading,
                onBarcodeDetected = { rect, size ->
                    detectedRect = rect
                    previewSize = size
                },
                onBarcodeScanned = { scannedBarcode ->
                    onAnalyze(scannedBarcode)
                }
            )
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
        
        if (!isManualMode && hasCameraPermission && detectedRect == null && !showSheet && state !is ProductState.Loading) {
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

        if (showSheet && state is ProductState.Success) {
            ModalBottomSheet(
                onDismissRequest = {
                    showSheet = false
                    detectedRect = null
                    onResetState()
                },
                sheetState = sheetState,
                containerColor = Coco.Cream,
                dragHandle = { BottomSheetDefaults.DragHandle(color = Coco.Hairline) },
                shape = RoundedCornerShape(topStart = 32.dp, topEnd = 32.dp)
            ) {
                FoodDetailContent(
                    product = state.product,
                    onBack = { 
                        showSheet = false
                        detectedRect = null
                        onResetState()
                    },
                    onSwap = onSwap
                )
            }
        }

        if (state is ProductState.Loading) {
            Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.4f)), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = Coco.Lime)
            }
        }
        
        if (state is ProductState.Error) {
            LaunchedEffect(state) {
                android.widget.Toast.makeText(context, state.message, android.widget.Toast.LENGTH_LONG).show()
                detectedRect = null
                onResetState()
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
    
    val product = (state as? ProductState.Success)?.product ?: return
    AdaptiveScreen {
        FoodDetailContent(product, onBack, onSwap)
    }
}

@Composable
private fun FoodDetailContent(product: Product, onBack: () -> Unit, onSwap: () -> Unit) {
    val score = ((product.totalRating) * 20).toInt()
    val t = tier(score)
    
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
                if (product.thumbnail != null) {
                    android.util.Log.d("COCO_IMG", "Detail Image URL: ${product.thumbnail}")
                    AsyncImage(
                        model = product.thumbnail,
                        contentDescription = null,
                        contentScale = ContentScale.Crop,
                        modifier = Modifier.size(88.dp).clip(RoundedCornerShape(22.dp))
                    )
                } else {
                    FoodThumb(product.title.take(1), size = 88.dp, radius = 22.dp)
                }
                Column(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text((product.manufacturer.ifEmpty { product.categoryName }.ifEmpty { "НЕИЗВЕСТНО" }).uppercase(), color = Coco.Muted, fontSize = 12.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.weight(1f, false))
                        if (product.hasQualityMark) Icon(Icons.Rounded.Verified, null, tint = Coco.Emerald, modifier = Modifier.size(18.dp))
                        if (product.hasBadQualityMark) Icon(Icons.Rounded.NewReleases, null, tint = Coco.Red, modifier = Modifier.size(18.dp))
                    }
                    Text(product.title, color = Coco.Ink, fontSize = 24.sp, fontWeight = FontWeight.ExtraBold, lineHeight = 27.sp)
                    Text(product.price, color = Coco.Muted, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                }
            }
            CocoCard(background = t.bg, padding = 20.dp) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    ScoreRing(score, size = 104.dp, showLabel = false)
                    Column(Modifier.weight(1f)) {
                        Text("${t.label}.", color = t.inkOn, fontSize = 26.sp, fontWeight = FontWeight.ExtraBold)
                        Text(
                            product.worth.firstOrNull() ?: "Рейтинг по стандартам Роскачества.",
                            color = t.inkOn.copy(alpha = 0.75f),
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            lineHeight = 18.sp,
                        )
                    }
                }
            }
            
            if (product.nutrients != null) {
                SectionTitle("Пищевая ценность")
                NutritionalGrid(product.nutrients)
            }

            if (!product.composition.isNullOrEmpty()) {
                SectionTitle("Состав")
                CocoCard(padding = 16.dp) {
                    Text(product.composition, color = Coco.Ink, fontSize = 14.sp, lineHeight = 20.sp)
                }
            }

            SectionTitle("Критерии качества")
            CocoCard(padding = 16.dp) {
                val ratings = product.criteriaRatings
                if (ratings.isEmpty()) {
                    Text("Детальные критерии отсутствуют.", color = Coco.Muted, fontSize = 14.sp)
                } else {
                    ratings.forEachIndexed { index, axis ->
                        AxisRow(axis.title, (axis.value * 20).toInt(), "${axis.value} / 5", bad = axis.value < 3.0)
                        if (index != ratings.lastIndex) DividerLine()
                    }
                }
            }
            if (product.worth.isNotEmpty()) {
                SectionTitle("Стоит отметить")
                product.worth.forEach { worth ->
                    Flag(Coco.Emerald, Icons.Rounded.Check, "Плюсы", worth)
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
            SwapCol("Чистая Линия", "Мороженое Пломбир ванильный в вафельном стаканчике", 95, "Ч", winner = true)
            Spacer(Modifier.height(24.dp))
            SectionTitle("Почему это лучше?")
            CocoCard(padding = 0.dp) {
                DeltaRow("Сахар", "24г", "14г", good = true)
                DividerLine()
                DeltaRow("Жиры", "18г", "12г", good = true)
                DividerLine()
                DeltaRow("Добавки", "E471, E412", "Нет", good = true)
            }
            Spacer(Modifier.height(30.dp))
            Pill("Выбрать этот продукт", kind = PillKind.Brand, large = true) { onClose() }
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

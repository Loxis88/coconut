package com.coconut.app.presentation.ui

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.DocumentScanner
import androidx.compose.material.icons.rounded.EditNote
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object Coco {
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

data class Tier(val label: String, val color: Color, val bg: Color, val inkOn: Color)

fun tier(score: Int): Tier = when {
    score >= 80 -> Tier("Супер", Coco.Emerald, Color(0xFFD7F5E6), Color(0xFF04432A))
    score >= 60 -> Tier("Норма", Color(0xFFA3B91D), Color(0xFFF0F6CF), Color(0xFF3A4407))
    score >= 40 -> Tier("Спорно", Coco.Coral, Color(0xFFFFE2CC), Color(0xFF5A1F00))
    else -> Tier("Мусор", Coco.Red, Color(0xFFFFD9DF), Color(0xFF5C0716))
}

@Composable
fun AdaptiveScreen(
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
fun CoconutMark(size: Dp, modifier: Modifier = Modifier) {
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
fun ScoreChip(score: Int, big: Boolean = false) {
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
fun FloatingScore(score: Int, modifier: Modifier) {
    Box(modifier) { ScoreChip(score, big = true) }
}

@Composable
fun CocoCard(
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
fun CocoCard(
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

enum class PillKind { Ink, Brand, Ghost }

@Composable
fun Pill(
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
        PillKind.Ghost -> if (label.contains("Выйти")) Coco.Red else Coco.Ink
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
fun RoundIcon(icon: ImageVector, dark: Boolean = false, onClick: () -> Unit) {
    IconButton(
        onClick = onClick,
        modifier = Modifier.size(40.dp).clip(CircleShape).background(if (dark) Color.White.copy(alpha = 0.15f) else Coco.Hairline),
    ) {
        Icon(icon, null, tint = if (dark) Color.White else Coco.Ink, modifier = Modifier.size(22.dp))
    }
}

@Composable
fun DividerLine() {
    Box(Modifier.fillMaxWidth().height(1.dp).background(Coco.Hairline))
}

@Composable
fun AnimatedTabToggle(
    isManualMode: Boolean,
    onModeChange: (Boolean) -> Unit,
    modifier: Modifier = Modifier
) {
    BoxWithConstraints(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .clip(RoundedCornerShape(20.dp))
            .background(Coco.Hairline)
            .padding(4.dp)
    ) {
        val halfWidth = maxWidth / 2
        val offset by animateDpAsState(
            targetValue = if (isManualMode) halfWidth else 0.dp,
            animationSpec = spring(dampingRatio = 0.85f, stiffness = 400f),
            label = "SliderOffset"
        )

        // Sliding background
        Box(
            modifier = Modifier
                .offset(x = offset)
                .width(halfWidth)
                .fillMaxHeight()
                .clip(RoundedCornerShape(16.dp))
                .background(Color.White)
                .shadow(elevation = 2.dp, shape = RoundedCornerShape(16.dp))
        )

        Row(modifier = Modifier.fillMaxSize()) {
            ModeTab(
                icon = Icons.Rounded.DocumentScanner,
                label = "Автоскан",
                active = !isManualMode,
                modifier = Modifier.weight(1f).fillMaxHeight().clickable { onModeChange(false) }
            )
            ModeTab(
                icon = Icons.Rounded.EditNote,
                label = "Вручную",
                active = isManualMode,
                modifier = Modifier.weight(1f).fillMaxHeight().clickable { onModeChange(true) }
            )
        }
    }
}

@Composable
private fun ModeTab(icon: ImageVector, label: String, active: Boolean, modifier: Modifier) {
    val color by animateColorAsState(if (active) Coco.Ink else Coco.Muted.copy(alpha = 0.6f), label = "TabColor")
    Row(
        modifier = modifier,
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = color, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(8.dp))
        Text(label, color = color, fontSize = 14.sp, fontWeight = if (active) FontWeight.ExtraBold else FontWeight.Bold)
    }
}

@Composable
fun SmartScannerFrame(
    detectedRect: android.graphics.Rect?,
    previewSize: IntSize,
    modifier: Modifier = Modifier
) {
    val left by animateFloatAsState(targetValue = detectedRect?.left?.toFloat() ?: 0f, label = "Left")
    val top by animateFloatAsState(targetValue = detectedRect?.top?.toFloat() ?: 0f, label = "Top")
    val right by animateFloatAsState(targetValue = detectedRect?.right?.toFloat() ?: 0f, label = "Right")
    val bottom by animateFloatAsState(targetValue = detectedRect?.bottom?.toFloat() ?: 0f, label = "Bottom")
    
    val infiniteTransition = rememberInfiniteTransition(label = "ScannerGlow")
    val glowProgress by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1500, easing = LinearEasing)
        ),
        label = "Glow"
    )

    Canvas(modifier.fillMaxSize()) {
        val strokeWidth = 4.dp.toPx()
        val cornerLen = 28.dp.toPx()
        val cornerRadius = 16.dp.toPx()

        val targetRect = if (detectedRect != null && previewSize.width > 0) {
            val scaleX = size.width / previewSize.height
            val scaleY = size.height / previewSize.width
            Rect(
                left = left * scaleX,
                top = top * scaleY,
                right = right * scaleX,
                bottom = bottom * scaleY
            ).inflate(30f)
        } else {
            val side = size.minDimension * 0.7f
            Rect(center = center, radius = side / 2f)
        }
        
        val color = if (detectedRect != null) Coco.Lime else Color.White.copy(alpha = 0.5f)

        val path = Path().apply {
            moveTo(targetRect.left, targetRect.top + cornerLen)
            lineTo(targetRect.left, targetRect.top + cornerRadius)
            quadraticBezierTo(targetRect.left, targetRect.top, targetRect.left + cornerRadius, targetRect.top)
            lineTo(targetRect.left + cornerLen, targetRect.top)

            moveTo(targetRect.right - cornerLen, targetRect.top)
            lineTo(targetRect.right - cornerRadius, targetRect.top)
            quadraticBezierTo(targetRect.right, targetRect.top, targetRect.right, targetRect.top + cornerRadius)
            lineTo(targetRect.right, targetRect.top + cornerLen)

            moveTo(targetRect.right, targetRect.bottom - cornerLen)
            lineTo(targetRect.right, targetRect.bottom - cornerRadius)
            quadraticBezierTo(targetRect.right, targetRect.bottom, targetRect.right - cornerRadius, targetRect.bottom)
            lineTo(targetRect.right, targetRect.bottom - cornerLen)

            moveTo(targetRect.left + cornerLen, targetRect.bottom)
            lineTo(targetRect.left + cornerRadius, targetRect.bottom)
            quadraticBezierTo(targetRect.left, targetRect.bottom, targetRect.left, targetRect.bottom - cornerRadius)
            lineTo(targetRect.left, targetRect.bottom - cornerLen)
        }
        drawPath(path, color, style = Stroke(width = strokeWidth, cap = StrokeCap.Round))
        
        if (detectedRect != null) {
            val scanLineY = targetRect.top + (targetRect.height * glowProgress)
            drawLine(
                brush = Brush.verticalGradient(listOf(Color.Transparent, color.copy(alpha = 0.4f), Color.Transparent)),
                start = Offset(targetRect.left, scanLineY),
                end = Offset(targetRect.right, scanLineY),
                strokeWidth = 10.dp.toPx()
            )
        }
    }
}

private fun Rect.inflate(delta: Float): Rect = Rect(left - delta, top - delta, right + delta, bottom + delta)

@Composable
fun BrandTag(text: String) {
    Text(
        text.uppercase(),
        color = Coco.BrownDeep,
        fontSize = 12.sp,
        fontWeight = FontWeight.ExtraBold,
        modifier = Modifier.clip(RoundedCornerShape(999.dp)).background(Coco.BrandBrush).padding(horizontal = 12.dp, vertical = 4.dp),
    )
}

@Composable
fun ProgressStep(label: String, done: Boolean = false, active: Boolean = false) {
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
fun AxisRow(label: String, value: Int, note: String, bad: Boolean = false) {
    val t = tier(value)
    val color = if (bad) Coco.Red else t.color
    Column(Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 10.dp)) {
        Row {
            Text(label, color = Coco.Ink, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            Text(value.toString(), color = color, fontSize = 13.sp, fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.height(6.dp))
        ProgressBar(value / 100f, height = 8.dp, color = color)
        Text(note, color = Coco.Muted, fontSize = 12.sp, fontWeight = FontWeight.Medium, modifier = Modifier.padding(top = 6.dp))
    }
}

@Composable
fun ProgressBar(progress: Float, height: Dp, color: Color) {
    Box(Modifier.fillMaxWidth().height(height).clip(RoundedCornerShape(height / 2)).background(Coco.Hairline)) {
        Box(Modifier.fillMaxWidth(progress.coerceIn(0f, 1f)).fillMaxHeight().clip(RoundedCornerShape(height / 2)).background(color))
    }
}

@Composable
fun Flag(color: Color, icon: ImageVector, title: String, sub: String) {
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
fun SwapCol(name: String, sub: String, score: Int, thumb: String, dim: Boolean = false, winner: Boolean = false, modifier: Modifier = Modifier) {
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
fun DeltaRow(label: String, from: String, to: String, good: Boolean = false) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(label, color = Coco.Ink, fontSize = 14.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
        Text(from, color = Coco.Muted, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, textDecoration = TextDecoration.LineThrough)
        Icon(Icons.AutoMirrored.Rounded.ArrowForward, null, tint = Coco.Muted, modifier = Modifier.size(14.dp))
        Text(to, color = if (good) Coco.Emerald else Coco.Ink, fontSize = 14.sp, fontWeight = FontWeight.ExtraBold)
    }
}

@Composable
fun SectionTitle(text: String) {
    Text(text, color = Coco.Ink, fontSize = 18.sp, fontWeight = FontWeight.ExtraBold, modifier = Modifier.padding(bottom = 10.dp))
}

@Composable
fun FoodThumb(label: String, size: Dp, radius: Dp) {
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
fun WeekBars(values: List<Int>) {
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
fun ScoreRing(score: Int, size: Dp, thickness: Dp = 12.dp, showLabel: Boolean = true) {
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

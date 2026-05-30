package com.coconut.app.presentation.ui

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
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

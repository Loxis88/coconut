import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.loading,
    this.scanLocked = false,
    required this.error,
    required this.onBack,
    required this.onFound,
  });

  final bool loading;
  final bool scanLocked;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function(String barcode) onFound;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    torchEnabled: false,
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
    detectionSpeed: DetectionSpeed.normal,
    useNewCameraSelector: false,
    returnImage: false,
  );

  var _manual = false;
  var _barcode = '';
  var _lastBarcode = '';
  var _flash = false;
  static final _barcodeRe = RegExp(r'^\d{6,8}$|^\d{12,13}$');

  var _detected = false;
  var _localLock = false;
  Rect? _focusRect;
  Timer? _detectedTimer;
  DateTime? _lastRectUpdate;

  @override
  void didUpdateWidget(ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.scanLocked == true) && !widget.scanLocked) {
      _lastBarcode = '';
      _localLock = false;
    }
    if (widget.error != null && widget.error != oldWidget.error) {
      _lastBarcode = '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.error!),
            backgroundColor: MayakTheme.scorePoor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _detectedTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onCapture(BarcodeCapture capture) {
    if (widget.loading || widget.scanLocked || _localLock) return;
    if (capture.barcodes.isEmpty) return;
    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    // Always compute rect from live corners regardless of barcode dedup
    final corners = barcode.corners;
    final camSize = _controller.value.size;
    Rect? newFocusRect;
    if (corners.length >= 4 && camSize != Size.zero) {
      final sw = MediaQuery.of(context).size.width;
      final sh = MediaQuery.of(context).size.height;
      var minX = double.infinity, minY = double.infinity;
      var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      for (final c in corners) {
        final px = c.dx / camSize.width * sw;
        final py = c.dy / camSize.height * sh;
        if (px < minX) minX = px;
        if (py < minY) minY = py;
        if (px > maxX) maxX = px;
        if (py > maxY) maxY = py;
      }
      const pad = 24.0;
      newFocusRect = Rect.fromLTRB(minX - pad, minY - pad, maxX + pad, maxY + pad);
    }

    final now = DateTime.now();
    final isNew = rawValue != _lastBarcode;

    if (isNew && _barcodeRe.hasMatch(rawValue)) {
      _lastBarcode = rawValue;
      _localLock = true;
      _detectedTimer?.cancel();
      _detectedTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() { _detected = false; _focusRect = null; });
      });
      _lastRectUpdate = now;
      setState(() { _focusRect = newFocusRect; _detected = true; });
      widget.onFound(rawValue);
    } else if (newFocusRect != null &&
        (_lastRectUpdate == null || now.difference(_lastRectUpdate!).inMilliseconds >= 300)) {
      _detectedTimer?.cancel();
      _detectedTimer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() { _detected = false; _focusRect = null; });
      });
      _lastRectUpdate = now;
      setState(() { _focusRect = newFocusRect; });
    }
  }

  void _submitManual() {
    if (_barcode.trim().length >= 4) {
      widget.onFound(_barcode.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScanningState = widget.loading;
    final size = MediaQuery.of(context).size;
    const bottomPanel = 148.0;
    const defaultW = 248.0;
    const defaultH = 164.0;
    final defaultLeft = (size.width - defaultW) / 2;
    final defaultTop = (size.height - bottomPanel - defaultH) / 2;

    final vfLeft = _focusRect?.left ?? defaultLeft;
    final vfTop = _focusRect?.top ?? defaultTop;
    final vfW = _focusRect?.width ?? defaultW;
    final vfH = _focusRect?.height ?? defaultH;

    return Scaffold(
      backgroundColor: const Color(0xFF080F09),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera or dark background
          if (!_manual)
            RepaintBoundary(
              child: _CameraPreview(
                key: const ValueKey('camera'),
                controller: _controller,
                onCapture: _onCapture,
              ),
            )
          else
            Container(color: const Color(0xFF080F09)),

          // Radial dark overlay
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2), // 40% down approx
                radius: 1.0,
                colors: [Color(0x000D1F0F), Color(0xFF080F09)],
                stops: [0.0, 1.0],
              ),
            ),
          ),

          // Flash ambient glow
          if (_flash)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 0.7,
                  colors: [Color(0x0FFFDC50), Colors.transparent], // rgba(255,220,80,0.06)
                  stops: [0.0, 1.0],
                ),
              ),
            ),

          // Scanning green ambient glow
          if (isScanningState)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 0.65,
                  colors: [Color(0x1A5BAF64), Colors.transparent], // rgba(91,175,100,0.1)
                  stops: [0.0, 1.0],
                ),
              ),
            ).animate().fade(duration: 800.ms),

          // Viewfinder — animates to detected barcode position
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            left: vfLeft,
            top: vfTop,
            width: vfW,
            height: vfH,
            child: Stack(
              children: [
                // Detection flash fill
                if (_detected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0x225BAF64),
                      ),
                    ),
                  ).animate().fade(begin: 1, end: 0, duration: 900.ms),
                // Corner brackets
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScannerFramePainter(isResult: _detected),
                  ),
                ),
                // Scan line
                if (isScanningState)
                  Positioned(
                    left: 8, right: 8, top: 0,
                    child: Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0xFF5BAF64), Color(0xFF5BAF64), Colors.transparent],
                          stops: [0.0, 0.3, 0.7, 1.0],
                        ),
                        boxShadow: [BoxShadow(color: Color(0x995BAF64), blurRadius: 8)],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).slideY(begin: 0, end: 164, duration: 1600.ms),
              ],
            ),
          ),

          // Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 56, bottom: 16, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xE6080F09), Colors.transparent], // rgba(8,15,9,0.9)
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
                    ),
                  ),
                  Text(
                    'Сканер',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _flash = !_flash);
                      _controller.toggleTorch();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: _flash ? const Color(0x2EFCdc50) : Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: _flash ? const Color(0x59FFDC50) : Colors.transparent),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.flash_on_rounded, color: _flash ? const Color(0xFFFFE04A) : Colors.white.withValues(alpha: 0.7), size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Panel Wrapper
          Positioned(
            left: 0, right: 0, bottom: 0,
            height: 148,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF080F09)],
                  stops: [0.0, 0.4],
                ),
              ),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0E6),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tabs
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0x140C1A09))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'Камера',
                              icon: Icons.document_scanner_outlined,
                              active: !_manual,
                              onTap: () => setState(() => _manual = false),
                            ),
                          ),
                          Expanded(
                            child: _TabButton(
                              label: 'Вручную',
                              icon: Icons.edit_note_rounded,
                              active: _manual,
                              onTap: () => setState(() => _manual = true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tab Body
                    SizedBox(
                      height: 76,
                      child: Stack(
                        children: [
                          if (!_manual)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isScanningState ? 'Ищем штрихкод…' : 'Автоскан активен',
                                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0C1A09)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isScanningState ? 'Держите упаковку ровно' : 'Наведи камеру на штрих-код.',
                                          style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5E6859)),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 52, height: 52,
                                      decoration: BoxDecoration(
                                        gradient: isScanningState ? null : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4A9152), Color(0xFF1E6B28)]),
                                        color: isScanningState ? const Color(0x26153918) : null,
                                        shape: BoxShape.circle,
                                        boxShadow: isScanningState ? null : const [BoxShadow(color: Color(0x661E6B28), blurRadius: 20, offset: Offset(0, 6))],
                                      ),
                                      alignment: Alignment.center,
                                      child: isScanningState 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: MayakTheme.primary, strokeWidth: 2))
                                        : const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ).animate().fade(duration: 150.ms).slideX(begin: -0.1, end: 0),
                            )
                          else
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 44,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: const Color(0x0F0C1A09),
                                          border: Border.all(color: const Color(0x1A0C1A09), width: 1.5),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.barcode_reader, size: 16, color: Color(0x590C1A09)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: TextField(
                                                keyboardType: TextInputType.number,
                                                onChanged: (v) => setState(() => _barcode = v),
                                                onSubmitted: (_) => _submitManual(),
                                                style: GoogleFonts.dmMono(fontSize: 14, color: const Color(0xFF0C1A09), letterSpacing: 14 * 0.04),
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: '4600000000000',
                                                  isDense: true,
                                                ),
                                              ),
                                            ),
                                            if (_barcode.isNotEmpty)
                                              GestureDetector(
                                                onTap: () => setState(() => _barcode = ''),
                                                child: const Icon(Icons.cancel, size: 16, color: Color(0xFF5E6859)),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _submitManual,
                                      child: Container(
                                        width: 52, height: 44,
                                        decoration: BoxDecoration(
                                          color: _barcode.trim().length >= 4 ? const Color(0xFF153918) : const Color(0x1F153918),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'OK',
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w700, fontSize: 14,
                                            color: _barcode.trim().length >= 4 ? Colors.white : const Color(0x4D153918),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fade(duration: 150.ms).slideX(begin: 0.1, end: 0),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: active ? const Color(0xFF0C1A09) : const Color(0xFF8A9486)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    fontSize: 13,
                    color: active ? const Color(0xFF0C1A09) : const Color(0xFF8A9486),
                  ),
                ),
              ],
            ),
          ),
          if (active)
            Positioned(
              bottom: 0, left: 20, right: 20,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: const Color(0xFF153918),
                  borderRadius: BorderRadius.circular(2),
                ),
              ).animate().scaleX(alignment: Alignment.center, duration: 200.ms),
            ),
        ],
      ),
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({super.key, required this.controller, required this.onCapture});

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onCapture;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(controller: controller, onDetect: onCapture);
  }
}

class _ScannerFramePainter extends CustomPainter {
  final bool isResult;
  _ScannerFramePainter({required this.isResult});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isResult ? const Color(0xFF5BAF64) : Colors.white.withValues(alpha: 0.65);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    const length = 24.0;
    const r = 6.0;

    // Top-Left
    canvas.drawPath(Path()..moveTo(0, length)..lineTo(0, r)..quadraticBezierTo(0, 0, r, 0)..lineTo(length, 0), paint);
    // Top-Right
    canvas.drawPath(Path()..moveTo(size.width - length, 0)..lineTo(size.width - r, 0)..quadraticBezierTo(size.width, 0, size.width, r)..lineTo(size.width, length), paint);
    // Bottom-Left
    canvas.drawPath(Path()..moveTo(0, size.height - length)..lineTo(0, size.height - r)..quadraticBezierTo(0, size.height, r, size.height)..lineTo(length, size.height), paint);
    // Bottom-Right
    canvas.drawPath(Path()..moveTo(size.width - length, size.height)..lineTo(size.width - r, size.height)..quadraticBezierTo(size.width, size.height, size.width, size.height - r)..lineTo(size.width, size.height - length), paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) => isResult != oldDelegate.isResult;
}

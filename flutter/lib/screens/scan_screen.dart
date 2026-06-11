import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onFound,
  });

  final bool loading;
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
    detectionTimeoutMs: 500,
    detectionSpeed: DetectionSpeed.noDuplicates,
    useNewCameraSelector: true,
    returnImage: false,
  );
  
  var _manual = false;
  var _barcode = '';
  var _lastBarcode = '';
  var _flash = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitManual() {
    if (_barcode.trim().length >= 4) {
      widget.onFound(_barcode.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error via snackbar if needed
    if (widget.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.error!),
            backgroundColor: MayakTheme.scorePoor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
      // Clear last barcode to allow scanning again
      _lastBarcode = '';
    }

    final isScanningState = widget.loading; // When loading, we show scanning animation

    return Scaffold(
      backgroundColor: const Color(0xFF080F09),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera or dark background
          if (!_manual)
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (capture.barcodes.isEmpty) return;
                final barcode = capture.barcodes.first.rawValue;
                if (barcode != null && barcode != _lastBarcode) {
                  _lastBarcode = barcode;
                  widget.onFound(barcode);
                }
              },
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
                  colors: [Color(0x0FFDC50), Colors.transparent], // rgba(255,220,80,0.06)
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

          // Viewfinder
          Positioned(
            left: 0, right: 0, top: 0, bottom: 148, // Bottom panel height
            child: Center(
              child: SizedBox(
                width: 248,
                height: 164,
                child: Stack(
                  children: [
                    // Corners
                    CustomPaint(
                      size: const Size(248, 164),
                      painter: _ScannerFramePainter(isResult: false), // In this app, we navigate away on result, so false
                    ),
                    // Scan line animation
                    if (isScanningState)
                      Positioned(
                        left: 8, right: 8,
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
                      ).animate(onPlay: (controller) => controller.repeat()).slideY(begin: 0, end: 164, duration: 1600.ms),
                  ],
                ),
              ),
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
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 15),
                    ),
                  ),
                  Text(
                    'Сканер',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white.withOpacity(0.9)),
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
                        color: _flash ? const Color(0x2EFCdc50) : Colors.white.withOpacity(0.08),
                        border: Border.all(color: _flash ? const Color(0x59FFDC50) : Colors.transparent),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.flash_on_rounded, color: _flash ? const Color(0xFFFFE04A) : Colors.white.withOpacity(0.7), size: 16),
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

class _ScannerFramePainter extends CustomPainter {
  final bool isResult;
  _ScannerFramePainter({required this.isResult});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isResult ? const Color(0xFF5BAF64) : Colors.white.withOpacity(0.65);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final length = 24.0;
    final r = 6.0;

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

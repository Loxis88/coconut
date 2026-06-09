import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import '../widgets/adaptive_screen.dart';
import '../widgets/pill_button.dart';
import '../widgets/scanner_frame.dart';
import '../widgets/shared.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onFound,
    required this.onScanAgain,
  });

  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function(String barcode) onFound;
  final VoidCallback onScanAgain;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    torchEnabled: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.qrCode,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  final _manualController = TextEditingController();
  var _manual = false;
  var _lastBarcode = '';

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
          Container(color: Coco.ink),
        Positioned.fill(child: CustomPaint(painter: ScannerFramePainter())),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    RoundIcon(icon: Icons.arrow_back, dark: true, onTap: widget.onBack),
                    const Spacer(),
                    RoundIcon(icon: Icons.flash_on, dark: true, onTap: () => _controller.toggleTorch()),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Coco.cream, borderRadius: BorderRadius.circular(28)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                      child: Container(
                        decoration: BoxDecoration(color: Coco.cream2, borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _ModeTab(
                              icon: Icons.document_scanner,
                              label: 'Камера',
                              active: !_manual,
                              onTap: () => setState(() => _manual = false),
                            ),
                            _ModeTab(
                              icon: Icons.edit_note,
                              label: 'Вручную',
                              active: _manual,
                              onTap: () => setState(() => _manual = true),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: _manual ? _manualInput() : _autoScanHint(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.loading) Container(color: Colors.black45, child: const CenteredLoader(compact: true)),
        if (widget.error != null)
          Container(
            color: Colors.black54,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Товар не найден', style: TextStyle(color: Coco.red, fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Text(widget.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    PillButton(
                      label: 'Сканировать снова',
                      onTap: () {
                        setState(() => _lastBarcode = '');
                        widget.onScanAgain();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _autoScanHint() => Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Автоскан активен', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text('Наведи камеру на штрих-код.', style: TextStyle(color: Coco.muted)),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _manual = true),
            child: const CircleIcon(icon: Icons.camera_alt),
          ),
        ],
      );

  Widget _manualInput() => Column(
        children: [
          TextField(
            controller: _manualController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Введите штрих-код',
              hintText: 'например 4603955002165',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ручной ввод', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    Text('Введите штрих-код для поиска.', style: TextStyle(color: Coco.muted)),
                  ],
                ),
              ),
              InkWell(
                onTap: () => widget.onFound(_manualController.text),
                child: const CircleIcon(icon: Icons.center_focus_strong),
              ),
            ],
          ),
        ],
      );
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.icon, required this.label, required this.active, required this.onTap});
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: active ? Coco.ink : Coco.muted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active ? Coco.ink : Coco.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

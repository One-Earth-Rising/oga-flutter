// lib/screens/fbs_qr_scanner_screen.dart
// FBS QR Code Scanner — mobile web + native
// Shown as a bottom sheet (same pattern as game_link_screen.dart).
// Scans packaging QR codes encoding:
//   https://oga.oneearthrising.com/redeem?code=FBS-XXXX-XXXX
// On detection, closes and returns the extracted code string.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FbsQrScannerSheet extends StatefulWidget {
  const FbsQrScannerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const FbsQrScannerSheet(),
    );
  }

  @override
  State<FbsQrScannerSheet> createState() => _FbsQrScannerSheetState();
}

class _FbsQrScannerSheetState extends State<FbsQrScannerSheet> {
  static const _black = Color(0xFF000000);
  static const _charcoal = Color(0xFF121212);
  static const _ironGrey = Color(0xFF2C2C2C);
  static const _neonGreen = Color(0xFF39FF14);
  static const _white = Color(0xFFFFFFFF);

  bool _detected = false;

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    // Extract ?code= param from URL, or use raw value directly
    final extracted =
        Uri.tryParse(raw)?.queryParameters['code']?.toUpperCase() ??
        raw.toUpperCase().trim();

    // Accept FBS-format codes or any reasonable raw value
    if (extracted.length < 4) return;

    setState(() => _detected = true);

    // Brief pause so user sees the green checkmark, then close
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(extracted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.78),
      decoration: const BoxDecoration(
        color: _black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: _ironGrey),
          left: BorderSide(color: _ironGrey),
          right: BorderSide(color: _ironGrey),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ─────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _ironGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Top bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _neonGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FBS',
                    style: TextStyle(
                      color: _black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SCAN QR CODE',
                  style: TextStyle(
                    color: _white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontFamily: 'Helvetica Neue',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 20,
                  ),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: _ironGrey, height: 1),

          // ── Scanner ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: _charcoal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _ironGrey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Live camera feed
                    MobileScanner(onDetect: _onDetect),

                    // Scan frame
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _detected
                              ? _neonGreen
                              : _neonGreen.withValues(alpha: 0.7),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _detected
                          ? Center(
                              child: Icon(
                                Icons.check_circle,
                                color: _neonGreen,
                                size: 64,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Instructions ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Point your camera at the QR code on the FBS candy packaging.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _white.withValues(alpha: 0.45),
                fontSize: 13,
                height: 1.5,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),

          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(
              'ENTER CODE MANUALLY INSTEAD',
              style: TextStyle(
                color: _white.withValues(alpha: 0.3),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
          SizedBox(height: 16 + MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}

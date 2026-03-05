// lib/screens/fbs_qr_scanner_screen.dart
// FBS QR Code Scanner — mobile only
// Scans packaging QR codes encoding:
//   https://oga.oneearthrising.com/redeem?code=FBS-XXXX-XXXX
// On detection, pops and returns the extracted code string.

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FbsQrScannerScreen extends StatefulWidget {
  const FbsQrScannerScreen({super.key});

  @override
  State<FbsQrScannerScreen> createState() => _FbsQrScannerScreenState();
}

class _FbsQrScannerScreenState extends State<FbsQrScannerScreen> {
  static const _black = Color(0xFF000000);
  static const _neonGreen = Color(0xFF39FF14);
  static const _charcoal = Color(0xFF121212);
  static const _ironGrey = Color(0xFF2C2C2C);
  static const _white = Color(0xFFFFFFFF);

  bool _detected = false;

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return; // prevent double-fire
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    // Extract code param from URL, or use raw value directly
    final extracted =
        Uri.tryParse(raw)?.queryParameters['code']?.toUpperCase() ??
        raw.toUpperCase().trim();

    // Only accept FBS-format codes
    if (!extracted.startsWith('FBS-') && extracted.length < 4) return;

    setState(() => _detected = true);
    Navigator.of(context).pop(extracted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Live camera feed ─────────────────────────────
          MobileScanner(onDetect: _onDetect),

          // ── Dark vignette around scan frame ──────────────
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              _black.withValues(alpha: 0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: _black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: _black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scan frame border ────────────────────────────
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _detected
                      ? _neonGreen
                      : _neonGreen.withValues(alpha: 0.7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
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
          ),

          // ── Top bar ──────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _charcoal.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _ironGrey.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(Icons.close, color: _white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'SCAN FBS CODE',
                      style: TextStyle(
                        color: _white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'Helvetica Neue',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom instructions ───────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _charcoal.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _ironGrey),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                          'FINAL BOSS SOUR',
                          style: TextStyle(
                            color: _white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontFamily: 'Helvetica Neue',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Point your camera at the QR code on the candy packaging.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _white.withValues(alpha: 0.5),
                        fontSize: 12,
                        height: 1.5,
                        fontFamily: 'Helvetica Neue',
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

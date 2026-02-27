import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Full-screen splash / landing screen for unauthenticated visitors.
///
/// Pure Flutter implementation matching the HTML/CSS CRT boot sequence:
///   Scene 1: DOS-style green text typing on black
///   Scene 2: CRT power-off effect (vertical collapse)
///   Scene 3: TV static + scanlines + neon OGA geometric logo with intense glow
class OGASplashScreen extends StatefulWidget {
  const OGASplashScreen({super.key});

  @override
  State<OGASplashScreen> createState() => _OGASplashScreenState();
}

class _OGASplashScreenState extends State<OGASplashScreen>
    with TickerProviderStateMixin {
  // ── Scene state ──────────────────────────────────
  int _scene = 1; // 1 = DOS, 2 = power-off, 3 = neon

  // ── Scene 1: DOS typing ──────────────────────────
  static const _dosLines = [
    '> INITIALIZING COMM_LINK...',
    '> SIGNAL PROTOCOL: EXTRATERRESTRIAL',
    '> SYNCHRONIZING WITH SECTOR [NULL]',
    '> DETECTING SHARED DOMAIN...',
    '> WARNING: YOU ARE ENTERING THE COLLECTIVE',
  ];
  String _displayedText = '';
  int _currentLine = 0;
  int _currentChar = 0;
  bool _cursorVisible = true;
  Timer? _typeTimer;
  Timer? _cursorTimer;

  // ── Scene 2: Power-off ───────────────────────────
  late AnimationController _powerOffCtrl;
  late Animation<double> _scaleY;
  late Animation<double> _scaleX;
  late Animation<double> _powerOffOpacity;

  // ── Scene 3: Neon reveal ─────────────────────────
  late AnimationController _neonCtrl;

  // Neon flicker
  double _flickerOpacity = 0.0;
  Timer? _flickerTimer;
  int _flickerCount = 0;

  // TV static refresh
  Timer? _staticTimer;
  int _staticSeed = 0;

  @override
  void initState() {
    super.initState();

    // ── Power-off animation ──
    _powerOffCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _powerOffCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _scaleY = Tween<double>(begin: 1.0, end: 0.001).animate(
      CurvedAnimation(
        parent: _powerOffCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInCubic),
      ),
    );

    _scaleX = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _powerOffCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _powerOffOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _powerOffCtrl, curve: const Interval(0.8, 1.0)),
    );

    // ── Neon reveal animation (5s total to match CSS timing) ──
    _neonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _neonCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    // ── Start cursor blink ──
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });

    // ── Start typing ──
    Future.delayed(const Duration(milliseconds: 800), _typeNext);
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    _flickerTimer?.cancel();
    _staticTimer?.cancel();
    _powerOffCtrl.dispose();
    _neonCtrl.dispose();
    super.dispose();
  }

  // ── Animation value helpers ─────────────────────

  // Matches CSS: neon-flicker-in 2s forwards (0%→100% of 5s = 0.0→0.4)
  double get _welcomeOpacity {
    final t = _neonCtrl.value;
    if (t < 0.0) return 0.0;
    if (t > 0.4) return 1.0;
    final p = t / 0.4;
    if (p < 0.05) return p * 20;
    if (p < 0.10) return 0.0;
    if (p < 0.15) return 1.0;
    if (p < 0.20) return 0.0;
    if (p < 0.25) return 1.0;
    if (p < 0.30) return 0.5;
    if (p < 0.40) return 1.0;
    if (p < 0.50) return 0.8;
    return 1.0;
  }

  // CSS: neon-flicker-svg 2.5s forwards 0.5s
  double get _logoOpacity {
    final t = _neonCtrl.value;
    if (t < 0.10) return 0.0;
    if (t > 0.60) return 1.0;
    final p = (t - 0.10) / 0.50;
    if (p < 0.05) return p * 20;
    if (p < 0.10) return 0.0;
    if (p < 0.15) return 1.0;
    if (p < 0.20) return 0.0;
    if (p < 0.25) return 1.0;
    if (p < 0.30) return 0.5;
    if (p < 0.40) return 1.0;
    if (p < 0.50) return 0.8;
    return 1.0;
  }

  double get _logoScale {
    final t = _neonCtrl.value;
    if (t < 0.10) return 0.95;
    if (t > 0.60) return 1.0;
    final p = ((t - 0.10) / 0.50).clamp(0.0, 1.0);
    return 0.95 + 0.05 * p;
  }

  // CSS: fade-pulse 2s forwards 2.5s
  double get _enterOpacity {
    final t = _neonCtrl.value;
    if (t < 0.50) return 0.0;
    if (t > 0.90) return 0.85;
    final p = (t - 0.50) / 0.40;
    if (p < 0.5) return p * 2;
    return 1.0 - (p - 0.5) * 0.3;
  }

  // CSS: fade-haze 5s forwards 1.5s
  double get _hazeOpacity {
    final t = _neonCtrl.value;
    if (t < 0.30) return 0.0;
    if (t > 0.95) return 1.0;
    return ((t - 0.30) / 0.65).clamp(0.0, 1.0);
  }

  // ── Scene 1: Typing engine ──────────────────────

  void _typeNext() {
    if (!mounted) return;

    if (_currentLine >= _dosLines.length) {
      Future.delayed(const Duration(milliseconds: 3500), _startPowerOff);
      return;
    }

    final line = _dosLines[_currentLine];

    if (_currentChar < line.length) {
      setState(() {
        _displayedText += line[_currentChar];
        _currentChar++;
      });
      final delay = Duration(milliseconds: 10 + Random().nextInt(20));
      _typeTimer = Timer(delay, _typeNext);
    } else {
      setState(() {
        _displayedText += '\n';
        _currentLine++;
        _currentChar = 0;
      });
      _typeTimer = Timer(const Duration(milliseconds: 150), _typeNext);
    }
  }

  // ── Scene 2: Power-off ──────────────────────────

  void _startPowerOff() {
    if (!mounted) return;
    setState(() => _scene = 2);
    _powerOffCtrl.forward().then((_) {
      if (mounted) {
        setState(() => _scene = 3);
        _startNeonScene();
      }
    });
  }

  // ── Scene 3: Neon reveal ────────────────────────

  void _startNeonScene() {
    _neonCtrl.forward();
    _startFlicker();
    _staticTimer = Timer.periodic(const Duration(milliseconds: 42), (_) {
      if (mounted) setState(() => _staticSeed++);
    });
  }

  void _startFlicker() {
    _flickerCount = 0;
    _flickerTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _flickerCount++;
      if (_flickerCount > 25) {
        timer.cancel();
        setState(() => _flickerOpacity = 1.0);
        return;
      }
      setState(() {
        if (_flickerCount < 5) {
          _flickerOpacity = Random().nextBool() ? 1.0 : 0.0;
        } else if (_flickerCount < 10) {
          _flickerOpacity = Random().nextBool() ? 1.0 : 0.3;
        } else if (_flickerCount < 18) {
          _flickerOpacity = Random().nextDouble() * 0.3 + 0.7;
        } else {
          _flickerOpacity = 1.0;
        }
      });
    });
  }

  // ── Navigation ──────────────────────────────────

  void _onEnterTapped() {
    Navigator.pushNamed(context, '/signin');
  }

  // ── Build ───────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Scene 1 & 2: DOS text
          if (_scene <= 2) _buildDosScene(),

          // Scene 3: Neon
          if (_scene == 3) _buildNeonScene(),

          // Scanlines overlay — ALWAYS on, over everything
          // CSS: opacity: 0.6, background-size: 100% 4px
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ScanlinePainter()),
            ),
          ),

          // CRT vignette — CSS: box-shadow: inset 0 0 100px rgba(0,0,0,0.9)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosScene() {
    Widget content = Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.all(32),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _displayedText,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 18,
                color: Color(0xFF33FF00),
                height: 1.6,
                shadows: [Shadow(color: Color(0xFF33FF00), blurRadius: 5)],
              ),
            ),
            TextSpan(
              text: '\u2588',
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 18,
                color: _cursorVisible
                    ? const Color(0xFF33FF00)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );

    if (_scene == 2) {
      return Opacity(
        opacity: _powerOffOpacity.value,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(_scaleX.value, _scaleY.value),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildNeonScene() {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 768;

    // CSS: width: 80vw; max-width: 450px (mobile: 90vw)
    final logoWidth = isMobile
        ? screenW * 0.90
        : (screenW * 0.55).clamp(300.0, 650.0);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF050505),
      child: Stack(
        children: [
          // ── TV Static background ──
          // CSS: canvas#static-canvas { opacity: 0.08 }
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                painter: _StaticNoisePainter(seed: _staticSeed),
              ),
            ),
          ),

          // ── Massive ambient green haze ──
          // CSS: width: 250%; height: 250%; radial-gradient; filter: blur(40px)
          Center(
            child: Opacity(
              opacity: _hazeOpacity,
              child: Container(
                width: screenW * 2.0,
                height: screenW * 2.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF39FF14).withValues(alpha: 0.18),
                      const Color(0xFF39FF14).withValues(alpha: 0.10),
                      const Color(0xFF39FF14).withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.45, 0.70],
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "WELCOME TO"
                // CSS: font-size: 2.5rem, letter-spacing: 12px
                Opacity(
                  opacity: _welcomeOpacity * _flickerOpacity,
                  child: Text(
                    'WELCOME TO',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: isMobile ? 20 : 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: isMobile ? 6 : 12,
                      shadows: [
                        const Shadow(color: Colors.white, blurRadius: 10),
                        Shadow(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.9),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: const Color(0xFF39FF14).withValues(alpha: 0.6),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 16),

                // ── OGA Geometric Logo ──
                // CSS: filter: drop-shadow(0 0 5px #fff)
                //   drop-shadow(0 0 20px neon) drop-shadow(0 0 60px neon)
                Opacity(
                  opacity: _logoOpacity * _flickerOpacity,
                  child: Transform.scale(
                    scale: _logoScale,
                    child: SizedBox(
                      width: logoWidth,
                      height: logoWidth * 0.30,
                      child: CustomPaint(
                        painter: _OGALogoPainter(
                          glowIntensity: _logoOpacity.clamp(0.0, 1.0),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isMobile ? 24 : 40),

                // "ENTER NOW"
                Opacity(
                  opacity: _enterOpacity,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _onEnterTapped,
                      child: const _EnterNowButton(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// OGA GEOMETRIC LOGO PAINTER
// Draws the blocky OGA letterforms with layered
// neon green glow + white fill
// ═══════════════════════════════════════════════════════

class _OGALogoPainter extends CustomPainter {
  final double glowIntensity;
  _OGALogoPainter({required this.glowIntensity});

  static const double _vbW = 420;
  static const double _vbH = 100;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final scaleVal = _min(size.width / _vbW, size.height / _vbH);
    final offsetX = (size.width - _vbW * scaleVal) / 2;
    final offsetY = (size.height - _vbH * scaleVal) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scaleVal);

    // Glow layers (largest blur first)
    _paintLayer(canvas, const Color(0xFF39FF14), 0.06 * glowIntensity, 80);
    _paintLayer(canvas, const Color(0xFF39FF14), 0.10 * glowIntensity, 50);
    _paintLayer(canvas, const Color(0xFF39FF14), 0.15 * glowIntensity, 30);
    _paintLayer(canvas, const Color(0xFF39FF14), 0.25 * glowIntensity, 15);
    _paintLayer(canvas, Colors.white, 0.20 * glowIntensity, 8);
    _paintLayer(canvas, Colors.white, 0.10 * glowIntensity, 20);

    // Solid white fill (topmost)
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    _drawLetters(canvas, fillPaint);

    canvas.restore();
  }

  void _paintLayer(Canvas canvas, Color color, double alpha, double blur) {
    if (alpha <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
      ..style = PaintingStyle.fill;
    _drawLetters(canvas, paint);
  }

  void _drawLetters(Canvas canvas, Paint paint) {
    // ── O ──
    final oOuter = Path()
      ..moveTo(25, 0)
      ..lineTo(105, 0)
      ..lineTo(130, 25)
      ..lineTo(130, 75)
      ..lineTo(105, 100)
      ..lineTo(25, 100)
      ..lineTo(0, 75)
      ..lineTo(0, 25)
      ..close();

    final oInner = Path()
      ..moveTo(25, 25)
      ..lineTo(105, 25)
      ..lineTo(105, 75)
      ..lineTo(25, 75)
      ..close();

    canvas.drawPath(
      Path.combine(PathOperation.difference, oOuter, oInner),
      paint,
    );

    // ── G (offset +145) ──
    // Single continuous path tracing the full G outline including
    // the right-side opening and inward tongue. Winding rule
    // naturally creates the hollow interior.
    canvas.save();
    canvas.translate(145, 0);
    final gPath = Path()
      // Start at inner top-right, trace clockwise
      ..moveTo(25, 25) // inner top-left
      ..lineTo(130, 25) // inner top-right (flush with outer chamfer)
      ..lineTo(105, 0) // outer top-right chamfer
      ..lineTo(25, 0) // outer top-left
      ..lineTo(0, 25) // outer top-left chamfer
      ..lineTo(0, 75) // outer left side
      ..lineTo(25, 100) // outer bottom-left chamfer
      ..lineTo(105, 100) // outer bottom
      ..lineTo(130, 75) // outer bottom-right chamfer
      ..lineTo(130, 50) // right side down to tongue opening
      ..lineTo(70, 50) // tongue extends left
      ..lineTo(70, 65) // tongue drops down
      ..lineTo(105, 65) // tongue goes right to inner wall
      ..lineTo(105, 75) // inner bottom-right
      ..lineTo(25, 75) // inner bottom
      ..close(); // back to (25,25) — inner top-left
    canvas.drawPath(gPath, paint);
    canvas.restore();

    // ── A (offset +290) ──
    canvas.save();
    canvas.translate(290, 0);
    final aOuter = Path()
      ..moveTo(0, 100)
      ..lineTo(0, 25)
      ..lineTo(25, 0)
      ..lineTo(105, 0)
      ..lineTo(130, 25)
      ..lineTo(130, 100)
      ..lineTo(105, 100)
      ..lineTo(105, 65)
      ..lineTo(25, 65)
      ..lineTo(25, 100)
      ..close();

    final aInner = Path()
      ..moveTo(25, 25)
      ..lineTo(105, 25)
      ..lineTo(105, 45)
      ..lineTo(25, 45)
      ..close();

    canvas.drawPath(
      Path.combine(PathOperation.difference, aOuter, aInner),
      paint,
    );
    canvas.restore();
  }

  double _min(double a, double b) => a < b ? a : b;

  @override
  bool shouldRepaint(_OGALogoPainter old) => old.glowIntensity != glowIntensity;
}

// ═══════════════════════════════════════════════════════
// TV STATIC NOISE PAINTER
// Draws horizontal bands of random brightness (fast)
// ═══════════════════════════════════════════════════════

class _StaticNoisePainter extends CustomPainter {
  final int seed;
  _StaticNoisePainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final bandH = 2.0;
    final rows = (size.height / bandH).ceil();

    for (int y = 0; y < rows; y++) {
      final v = rng.nextInt(60);
      final g = v + rng.nextInt(15);
      final paint = Paint()..color = Color.fromARGB(255, v, g, v);
      canvas.drawRect(Rect.fromLTWH(0, y * bandH, size.width, bandH), paint);

      if (rng.nextDouble() < 0.3) {
        final speckX = rng.nextDouble() * size.width;
        final speckW = 2.0 + rng.nextDouble() * 8;
        final bright = 80 + rng.nextInt(100);
        canvas.drawRect(
          Rect.fromLTWH(speckX, y * bandH, speckW, bandH),
          Paint()..color = Color.fromARGB(255, bright, bright, bright),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StaticNoisePainter old) => old.seed != seed;
}

// ═══════════════════════════════════════════════════════
// ENTER NOW BUTTON
// CSS hover: border neon-green, box-shadow inset + outer
// ═══════════════════════════════════════════════════════

class _EnterNowButton extends StatefulWidget {
  const _EnterNowButton();

  @override
  State<_EnterNowButton> createState() => _EnterNowButtonState();
}

class _EnterNowButtonState extends State<_EnterNowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 32,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: _hovering ? const Color(0xFF39FF14) : Colors.transparent,
            width: 2,
          ),
          color: _hovering
              ? const Color(0xFF39FF14).withValues(alpha: 0.1)
              : Colors.transparent,
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                  BoxShadow(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ]
              : [],
        ),
        child: Text(
          'ENTER NOW',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: isMobile ? 18 : 24,
            fontWeight: FontWeight.w400,
            letterSpacing: 8,
            color: _hovering ? Colors.white : const Color(0xFF39FF14),
            shadows: [
              Shadow(
                color: const Color(0xFF39FF14).withValues(alpha: 0.8),
                blurRadius: _hovering ? 10 : 5,
              ),
              Shadow(
                color: const Color(0xFF39FF14).withValues(alpha: 0.5),
                blurRadius: _hovering ? 20 : 10,
              ),
              if (_hovering) ...[
                const Shadow(color: Colors.white, blurRadius: 5),
                const Shadow(color: Colors.white, blurRadius: 10),
                Shadow(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.5),
                  blurRadius: 40,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SCANLINES OVERLAY
// CSS: .scanlines { opacity: 0.6;
//   background: linear-gradient(transparent 50%, rgba(0,0,0,0.2) 50%);
//   background-size: 100% 4px; }
// ═══════════════════════════════════════════════════════

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // CSS: 0.6 opacity * 0.2 alpha black = 0.12 effective
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 2.0;

    // Bottom half of every 4px band is dark
    for (double y = 2; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

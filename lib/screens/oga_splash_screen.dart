import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Full-screen splash / landing screen for unauthenticated visitors.
///
/// Pure Flutter implementation of the CRT boot sequence:
///   Scene 1: DOS-style green text typing on black
///   Scene 2: CRT power-off effect (vertical collapse)
///   Scene 3: Neon OGA logo with glow + "ENTER NOW"
///
/// Replaces the old chatbot-based OgaLandingPage for beta launch.
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
  late Animation<double> _welcomeFade;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _enterFade;
  late Animation<double> _hazeFade;

  // Neon flicker
  double _flickerOpacity = 0.0;
  Timer? _flickerTimer;
  int _flickerCount = 0;

  @override
  void initState() {
    super.initState();

    // ── Power-off animation ──
    _powerOffCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

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

    // ── Neon reveal animation ──
    _neonCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _welcomeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _neonCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _neonCtrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _neonCtrl,
        curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _enterFade = Tween<double>(begin: 0.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _neonCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut),
      ),
    );

    _hazeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _neonCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

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
    _powerOffCtrl.dispose();
    _neonCtrl.dispose();
    super.dispose();
  }

  // ── Scene 1: Typing engine ──────────────────────

  void _typeNext() {
    if (!mounted) return;

    if (_currentLine >= _dosLines.length) {
      // Done typing — wait, then power off
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
      // End of line
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
          // Scanlines overlay
          const _Scanlines(),

          // Scene 1 & 2: DOS text
          if (_scene <= 2) _buildDosScene(),

          // Scene 3: Neon
          if (_scene == 3) _buildNeonScene(),
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
              text: '█',
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
      return AnimatedBuilder(
        animation: _powerOffCtrl,
        builder: (context, child) {
          return Opacity(
            opacity: _powerOffOpacity.value,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scale(_scaleX.value, _scaleY.value),
              child: child,
            ),
          );
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildNeonScene() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AnimatedBuilder(
      animation: _neonCtrl,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF050505),
          child: Stack(
            children: [
              // Background haze glow
              Center(
                child: Opacity(
                  opacity: _hazeFade.value,
                  child: Container(
                    width: isMobile ? 400 : 600,
                    height: isMobile ? 400 : 600,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF39FF14).withValues(alpha: 0.12),
                          const Color(0xFF39FF14).withValues(alpha: 0.04),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // Content column
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "WELCOME TO"
                    Opacity(
                      opacity: _welcomeFade.value * _flickerOpacity,
                      child: Text(
                        'WELCOME TO',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: isMobile ? 18 : 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: isMobile ? 6 : 12,
                          shadows: [
                            Shadow(
                              color: const Color(
                                0xFF39FF14,
                              ).withValues(alpha: 0.6),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OGA Logo
                    Opacity(
                      opacity: _logoFade.value * _flickerOpacity,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF39FF14,
                                ).withValues(alpha: 0.3 * _logoFade.value),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFF39FF14,
                                ).withValues(alpha: 0.15 * _logoFade.value),
                                blurRadius: 80,
                                spreadRadius: 30,
                              ),
                            ],
                          ),
                          child: Image.network(
                            'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/oga-files/oga_logo.png',
                            width: isMobile ? 250 : 350,
                            errorBuilder: (_, __, ___) => Text(
                              'OGA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isMobile ? 64 : 96,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // "ENTER NOW"
                    Opacity(
                      opacity: _enterFade.value,
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
      },
    );
  }
}

// ── ENTER NOW button with hover glow ───────────────

class _EnterNowButton extends StatefulWidget {
  const _EnterNowButton();

  @override
  State<_EnterNowButton> createState() => _EnterNowButtonState();
}

class _EnterNowButtonState extends State<_EnterNowButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
          ),
          color: _hovering
              ? const Color(0xFF39FF14).withValues(alpha: 0.1)
              : Colors.transparent,
          boxShadow: _hovering
              ? [
                  BoxShadow(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                  BoxShadow(
                    color: const Color(0xFF39FF14).withValues(alpha: 0.15),
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
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.w400,
            letterSpacing: 8,
            color: _hovering ? Colors.white : const Color(0xFF39FF14),
            shadows: [
              Shadow(
                color: const Color(0xFF39FF14).withValues(alpha: 0.6),
                blurRadius: _hovering ? 20 : 10,
              ),
              if (_hovering)
                Shadow(
                  color: const Color(0xFF39FF14).withValues(alpha: 0.4),
                  blurRadius: 40,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scanlines overlay ──────────────────────────────

class _Scanlines extends StatelessWidget {
  const _Scanlines();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.06,
          child: CustomPaint(painter: _ScanlinePainter()),
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

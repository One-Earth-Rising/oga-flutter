import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/analytics_service.dart';
import '../services/character_service.dart';
import '../services/notification_service.dart';

/// Logout confirmation screen with Heimdal neon aesthetic.
///
/// Automatically signs the user out on load, then displays
/// a branded confirmation with option to log back in or
/// return to the splash screen.
///
/// Route: /logout
class OGALogoutScreen extends StatefulWidget {
  const OGALogoutScreen({super.key});

  @override
  State<OGALogoutScreen> createState() => _OGALogoutScreenState();
}

class _OGALogoutScreenState extends State<OGALogoutScreen>
    with SingleTickerProviderStateMixin {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _logoScale;
  late Animation<Offset> _slideUp;

  bool _signedOut = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
          ),
        );

    _performLogout();
  }

  Future<void> _performLogout() async {
    try {
      await AnalyticsService.endSession();
      await NotificationService.dispose();
      CharacterService.clearCache();
      await Supabase.instance.client.auth.signOut();
      debugPrint('👋 User signed out successfully');
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    }

    if (mounted) {
      setState(() => _signedOut = true);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: voidBlack,
      body: Center(
        child: _signedOut ? _buildContent(isMobile) : _buildLoading(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: neonGreen, strokeWidth: 2),
        ),
        SizedBox(height: 16),
        Text(
          'SIGNING OUT...',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isMobile) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 32 : 48,
            vertical: 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // OGA Logo with neon glow
              ScaleTransition(
                scale: _logoScale,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: neonGreen.withValues(alpha: 0.15),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                      BoxShadow(
                        color: neonGreen.withValues(alpha: 0.08),
                        blurRadius: 120,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                  child: Image.network(
                    'https://jmbzrbteizvuqwukojzu.supabase.co/storage/v1/object/public/oga-files/oga_logo.png',
                    height: 80,
                    errorBuilder: (_, __, ___) => const Text(
                      'OGA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Divider line with glow
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: neonGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: neonGreen.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Heading
              const Text(
                'SESSION ENDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'You\'ve been securely logged out.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              // LOG IN AGAIN button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/signin',
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: neonGreen,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: neonGreen.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'LOG IN AGAIN',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Back to home link
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ironGrey),
                  ),
                  child: Center(
                    child: Text(
                      'BACK TO HOME',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Security note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: deepCharcoal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ironGrey.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: neonGreen.withValues(alpha: 0.4),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your session has been securely cleared',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.2),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

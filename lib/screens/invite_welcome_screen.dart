import 'package:flutter/material.dart';
import '../models/oga_character.dart';

/// Simplified welcome screen for invited users.
/// Shows their free character with inviter context, then sends to dashboard.
class InviteWelcomeScreen extends StatefulWidget {
  final String? sessionId;
  final String characterId;
  final String inviterName;
  final String inviteCode;

  const InviteWelcomeScreen({
    super.key,
    this.sessionId,
    required this.characterId,
    required this.inviterName,
    required this.inviteCode,
  });

  @override
  State<InviteWelcomeScreen> createState() => _InviteWelcomeScreenState();
}

class _InviteWelcomeScreenState extends State<InviteWelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;
  late Animation<double> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // Rebuild on each animation tick
    _controller.addListener(() {
      if (mounted) setState(() {});
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final character = OGACharacter.fromId(widget.characterId);

    return Scaffold(
      backgroundColor: voidBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background glow
          Positioned.fill(
            child: Opacity(
              opacity: _fadeIn.value * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      character.glowColor.withValues(alpha: 0.15),
                      voidBlack,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Welcome text
                    Opacity(
                      opacity: _fadeIn.value,
                      child: Text(
                        'WELCOME TO OGA',
                        style: TextStyle(
                          color: neonGreen.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Character image
                    Transform.scale(
                      scale: _scaleIn.value,
                      child: Opacity(
                        opacity: _fadeIn.value,
                        child: Container(
                          width: 240,
                          height: 300,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: character.glowColor.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: character.glowColor.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              character.imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: character.cardColor,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white24,
                                      size: 64,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Character name
                    Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: Opacity(
                        opacity: _fadeIn.value,
                        child: Column(
                          children: [
                            Text(
                              character.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              character.ip,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // "Your first character" badge
                    Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: Opacity(
                        opacity: _fadeIn.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: neonGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: neonGreen.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.stars, color: neonGreen, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'YOUR FIRST CHARACTER',
                                style: TextStyle(
                                  color: neonGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Invited by context
                    Transform.translate(
                      offset: Offset(0, _slideUp.value),
                      child: Opacity(
                        opacity: _fadeIn.value,
                        child: Text(
                          'Invited by ${widget.inviterName}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // CTA
                    Transform.translate(
                      offset: Offset(0, _slideUp.value * 0.5),
                      child: Opacity(
                        opacity: _fadeIn.value,
                        child: GestureDetector(
                          onTap: _goToDashboard,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: neonGreen,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: neonGreen.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'ENTER MY LIBRARY',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.black,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
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

  void _goToDashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
      (route) => false,
      arguments: {
        'sessionId': widget.sessionId,
        'character': widget.characterId,
      },
    );
  }
}

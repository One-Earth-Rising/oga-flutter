import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Waitlist screen displayed when an authenticated user
/// does NOT have an active row in the beta_access table.
class BetaWaitlistScreen extends StatelessWidget {
  const BetaWaitlistScreen({super.key});

  static const Color neonGreen = Color(0xFF39FF14);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);
  static const Color voidBlack = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 700;
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      backgroundColor: voidBlack,
      // === ADDED: Standard Top Logo Navigation ===
      appBar: AppBar(
        backgroundColor: voidBlack,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        title: Center(
          child: Image.asset(
            'assets/logo.png',
            height: isMobile ? 24 : 32,
            errorBuilder: (_, __, ___) => const Text(
              'OGA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 48,
            vertical: 48,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // === STATUS BADGE ===
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: neonGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: neonGreen.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: neonGreen.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CLOSED BETA',
                        style: TextStyle(
                          color: neonGreen.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // === HEADER ===
                const Text(
                  'BETA ACCESS\nPENDING',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 16),

                // === EXPLANATION ===
                Text(
                  'OGA is currently in closed beta. Your account has been created, but access to the dashboard requires approval.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // === INFO CARD ===
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: deepCharcoal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ironGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: Colors.white.withValues(alpha: 0.4),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SIGNED IN AS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: ironGrey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We will notify you when your access is approved. You\'ll then be able to log in and explore your character library.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // === DISCORD CTA ===
                GestureDetector(
                  onTap: () async {
                    // <--- Added 'async' right here
                    debugPrint('📣 Open Discord link');

                    // Removed the trailing space at the end of the URL just to be safe!
                    final Uri url = Uri.parse('https://discord.gg/G9mbqyNhYD');

                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode
                            .externalApplication, // Opens in browser or Discord app
                      );
                    } else {
                      debugPrint('Could not launch $url');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: neonGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // ... the rest of the button stays exactly the same
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          color: Colors.black,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'JOIN OUR DISCORD',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // === SIGN OUT ===
                GestureDetector(
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/',
                        (route) => false,
                      );
                    }
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
                        'SIGN OUT',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // === FOOTER ===
                Text(
                  'ONE CHARACTER. INFINITE WORLDS.',
                  style: TextStyle(
                    color: neonGreen.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

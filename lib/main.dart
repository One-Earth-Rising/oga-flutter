import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oga_web_showcase/screens/oga_account_dashboard_main.dart';
import 'package:oga_web_showcase/screens/home/live_chatbot_widget.dart';
import 'package:oga_web_showcase/screens/home/landing_page_fbs.dart';
import 'package:oga_web_showcase/screens/confirm_login_screen.dart';
import 'services/campaign_service.dart';
import 'services/campaign_feature_flags.dart';
import 'services/campaign_analytics.dart';
import 'screens/welcome_screen_main.dart';
import 'screens/welcome_screen_fbs.dart';
import 'screens/fbs_account_screen.dart';
import 'screens/fbs_success_screen.dart';
import 'screens/fbs_campaign_dashboard.dart';
import 'screens/oga_signin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mlpinkcxdsmxicipseux.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1scGlua2N4ZHNteGljaXBzZXV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4MTI4MDAsImV4cCI6MjA4MzM4ODgwMH0.iX7By6rcSDrQ13reRrZ12C5SfHGOkKDvEOfI2dxfuDA',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  runApp(const OgaApp());
}

class OgaApp extends StatefulWidget {
  const OgaApp({super.key});
  @override
  State<OgaApp> createState() => _OgaAppState();
}

class _OgaAppState extends State<OgaApp> {
  @override
  void initState() {
    super.initState();
    _setupSilentFailGuard();
  }

  void _setupSilentFailGuard() {
    // Listens globally for successful Magic Link logins
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        debugPrint('⚡ Global Guard: Auth Handshake Complete');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'Inter',
      ),
      home: FutureBuilder<Widget>(
        future: _getLandingPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00C806)),
              ),
            );
          }
          return snapshot.data ?? const OgaLandingPage();
        },
      ),
      onGenerateRoute: (settings) {
        // Confirmation Buffer Route
        if (settings.name?.startsWith('/confirm') ?? false) {
          return MaterialPageRoute(
            builder: (context) => const ConfirmLoginScreen(),
          );
        }
        if (settings.name == '/signin') {
          return MaterialPageRoute(
            builder: (context) => const OGASignInScreen(),
          );
        }

        // FBS Account Screen
        if (settings.name == '/fbs-account') {
          final args = settings.arguments as Map?;
          return MaterialPageRoute(
            builder: (context) => FBSAccountScreen(
              sessionId: args?['sessionId'] ?? '',
              characterName: args?['character'] ?? 'caustica',
            ),
          );
        }

        // FBS Success Screen
        if (settings.name == '/fbs-success') {
          final args = settings.arguments as Map?;
          return MaterialPageRoute(
            builder: (context) => FBSSuccessScreen(
              sessionId: args?['sessionId'] ?? '',
              characterName: args?['character'] ?? 'caustica',
            ),
          );
        }

        // Welcome Screen
        if (settings.name == '/welcome') {
          return MaterialPageRoute(
            builder: (context) => FutureBuilder<Widget>(
              future: _getWelcomeScreen(settings.arguments as Map?),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00C806),
                      ),
                    ),
                  );
                }
                return snapshot.data ?? WelcomeScreenMain(sessionId: '');
              },
            ),
          );
        }

        // Dashboard Screen
        if (settings.name == '/dashboard') {
          final args = settings.arguments as Map?;
          final sessionId = args?['sessionId'];
          final character = args?['character'];
          final campaignId = args?['campaignId']; // Add campaign check

          return MaterialPageRoute(
            builder: (context) {
              // If FBS campaign, show FBS dashboard
              if (campaignId == 'fbs_launch') {
                return FBSCampaignDashboard(
                  sessionId: sessionId,
                  acquiredCharacterId: character,
                );
              }

              // Otherwise show main dashboard
              return OGAAccountDashboard(
                sessionId: sessionId,
                acquiredCharacterId: character,
              );
            },
          );
        }

        return null;
      },
    );
  }

  static Future<Widget> _getLandingPage() async {
    try {
      final uri = Uri.base;

      // ✅ Check if this is an auth callback (has access_token or code)
      if (uri.fragment.contains('access_token') ||
          uri.queryParameters.containsKey('code')) {
        debugPrint('🔐 Handling auth callback...');

        // Wait for PKCE code exchange to complete (up to 5 seconds)
        User? user;
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            debugPrint('✅ User authenticated after ${(i + 1) * 500}ms');
            break;
          }
          debugPrint('⏳ Waiting for auth... attempt ${i + 1}');
        }

        if (user != null) {
          try {
            // Fetch user's profile by email
            final response = await Supabase.instance.client
                .from('profiles')
                .select(
                  'starter_character, session_id, campaign_id, campaign_joined_at',
                )
                .eq('email', user.email!)
                .maybeSingle();

            // Extract data with fallbacks
            final character = response?['starter_character'] ?? 'ryu';
            final sessionId = response?['session_id'] ?? user.id;
            final campaignId = response?['campaign_id'];
            final joinedAt = response?['campaign_joined_at'];

            debugPrint('✅ User logged in: ${user.email}');
            debugPrint('   Character: $character');
            debugPrint('   Campaign: $campaignId');

            // If from FBS campaign
            if (campaignId == 'fbs_launch') {
              if (joinedAt != null) {
                final joinedDate = DateTime.parse(joinedAt);
                final difference = DateTime.now().difference(joinedDate);

                // New user: Show success screen first
                if (difference.inMinutes < 5) {
                  debugPrint('🎉 New FBS user - showing success screen');
                  return FBSSuccessScreen(
                    sessionId: sessionId,
                    characterName: character,
                  );
                }
              }

              // Existing FBS user: Go to FBS campaign dashboard
              debugPrint('👤 Returning FBS user - going to FBS dashboard');
              return FBSCampaignDashboard(
                sessionId: sessionId,
                acquiredCharacterId: character,
              );
            }

            // Non-FBS users: Go to main dashboard
            debugPrint('🎯 Routing to main dashboard');
            return OGAAccountDashboard(
              sessionId: sessionId,
              acquiredCharacterId: character,
            );
          } catch (e) {
            debugPrint('⚠️ Error fetching profile: $e');
            // Route to dashboard even on error
            return OGAAccountDashboard(
              sessionId: user.id,
              acquiredCharacterId: 'ryu',
            );
          }
        } else {
          debugPrint('❌ Auth timeout - no user after 5 seconds');
        }
      }

      // Check if URL is /fbs-success (direct navigation)
      if (uri.path.contains('fbs-success')) {
        final session = uri.queryParameters['session'] ?? '';
        final character = uri.queryParameters['character'] ?? 'caustica';

        debugPrint('✅ Direct success screen navigation');
        return FBSSuccessScreen(sessionId: session, characterName: character);
      }

      // Check for campaign parameter in URL
      final campaignId = CampaignService.getCampaignFromUrl();

      if (campaignId != null) {
        final isEnabled = await CampaignFeatureFlags.isCampaignEnabled(
          campaignId,
        );

        if (isEnabled && campaignId == 'fbs_launch') {
          debugPrint('✅ Showing FBS landing page');
          return const LandingPageFBS();
        }
      }

      // Default to main landing page
      debugPrint('✅ Showing main landing page');
      return const OgaLandingPage();
    } catch (e) {
      debugPrint('❌ Error determining landing page: $e');
      return const OgaLandingPage();
    }
  }

  static Future<Widget> _getWelcomeScreen(Map? args) async {
    final sessionId = args?['sessionId'] as String? ?? '';
    final campaignId = await CampaignService.getSafeCampaignId();

    if (campaignId == 'fbs_launch') {
      final isEnabled = await CampaignFeatureFlags.isCampaignEnabled(
        campaignId!,
      );
      if (isEnabled) return WelcomeScreenFBS(sessionId: sessionId);
    }
    return WelcomeScreenMain(sessionId: sessionId);
  }
}

// --- Main Landing Page ---

class OgaLandingPage extends StatefulWidget {
  const OgaLandingPage({super.key});
  @override
  State<OgaLandingPage> createState() => _OgaLandingPageState();
}

class _OgaLandingPageState extends State<OgaLandingPage> {
  bool _isOnboardingComplete = false;

  void _navigateToLibrary() {
    setState(() => _isOnboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      body: _isOnboardingComplete
          ? const OGAAccountDashboard()
          : (isDesktop ? _buildWeb() : _buildMobile()),
    );
  }

  Widget _buildWeb() {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: Center(
              child: ClipPath(
                clipper: OgaPolygonClipper(),
                child: Image.asset(
                  'assets/hero_monster.png',
                  fit: BoxFit.cover,
                  height: 600,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.orange.withValues(alpha: 0.1),
                    child: const Center(child: Text("Hero Placeholder")),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: Center(child: _buildDialoguePane())),
      ],
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 60),
          _buildDialoguePane(),
          const SizedBox(height: 40),
          ClipPath(
            clipper: OgaPolygonClipper(),
            child: Image.asset('assets/hero_monster.png', height: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildDialoguePane() {
    return Container(
      width: 450,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo.png',
            height: 60,
            errorBuilder: (_, __, ___) => const Text(
              "OGA",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Welcome to the OGA Ecosystem. Sign up to get started.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 40),
          ChatbotContainer(onComplete: _navigateToLibrary),
          const SizedBox(height: 24),
          _buildBypassLink(),
        ],
      ),
    );
  }

  Widget _buildBypassLink() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white70, fontSize: 14),
        children: [
          const TextSpan(text: "Already have your account? Access your "),
          TextSpan(
            text: "profile",
            style: const TextStyle(
              color: Color(0xFF00C806),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.pushNamed(context, '/signin');
              },
          ),
        ],
      ),
    );
  }
}

class OgaPolygonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.15, 0);
    path.lineTo(size.width * 0.95, size.height * 0.1);
    path.lineTo(size.width * 0.85, size.height);
    path.lineTo(size.width * 0.05, size.height * 0.9);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ChatbotContainer extends StatelessWidget {
  final VoidCallback onComplete;
  const ChatbotContainer({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LiveNetlifyChatbot(
        widgetUrl: 'https://oga-inline-chatbot.netlify.app',
        onComplete: onComplete,
      ),
    );
  }
}

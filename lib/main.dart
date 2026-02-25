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
import 'screens/invite_landing_screen.dart';
import 'screens/invite_signup_screen.dart';
import 'screens/invite_welcome_screen.dart';
import 'services/friend_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oga_web_showcase/config/environment.dart';
import 'screens/invite_onboarding_screen.dart';
import 'screens/character_detail_screen.dart';
import 'models/oga_character.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemNavigator.selectMultiEntryHistory();

  await Supabase.initialize(
    url: EnvironmentConfig.supabaseUrl,
    anonKey: EnvironmentConfig.supabaseAnonKey,
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
        final uri = Uri.parse(settings.name ?? '');
        // /#/character/ryu → CharacterDetailScreen
        // /#/character/ryu → CharacterDetailScreen
        if (uri.path.startsWith('/character/')) {
          final characterId = uri.path.replaceFirst('/character/', '');
          final character = OGACharacter.fromId(characterId);
          return PageRouteBuilder(
            settings: RouteSettings(name: '/character/$characterId'),
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, anim, secondAnim) => CharacterDetailScreen(
              character: character,
              isOwned: character.isOwned,
            ),
            transitionsBuilder: (_, anim, secondAnim, child) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
          );
        }

        // ═══════════════════════════════════════════════════════
        // INVITE ONBOARDING (profile setup after invite signup)
        // ═══════════════════════════════════════════════════════
        if (settings.name == '/invite-setup') {
          return MaterialPageRoute(
            builder: (_) => const InviteOnboardingScreen(),
          );
        }

        // ═══════════════════════════════════════════════════════
        // CONFIRMATION BUFFER ROUTE
        // ═══════════════════════════════════════════════════════
        if (settings.name?.startsWith('/confirm') ?? false) {
          final baseUri = Uri.base;

          // Extract invite code from URL if present (e.g. /confirm?invite=OGA-83E9)
          final routeUri = Uri.parse(settings.name!);
          final inviteFromUrl = routeUri.queryParameters['invite'];
          if (inviteFromUrl != null && inviteFromUrl.isNotEmpty) {
            debugPrint('🎟️ Found invite code in redirect URL: $inviteFromUrl');
            PendingInvite.save(inviteFromUrl);
          }

          if (baseUri.queryParameters.containsKey('code')) {
            return MaterialPageRoute(
              builder: (context) => FutureBuilder<Widget>(
                future: _getLandingPage(inviteCode: inviteFromUrl),
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
                  return snapshot.data ?? const OgaLandingPage();
                },
              ),
            );
          }

          return MaterialPageRoute(
            builder: (context) => const ConfirmLoginScreen(),
          );
        }

        // ═══════════════════════════════════════════════════════
        // INVITE ROUTES
        // ═══════════════════════════════════════════════════════

        // /#/invite/OGA-XXXX or /#/invite/OGA-XXXX/ryu
        if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'invite') {
          final inviteCode = uri.pathSegments[1];
          final characterId = uri.pathSegments.length >= 3
              ? uri.pathSegments[2]
              : null;
          return MaterialPageRoute(
            builder: (_) => InviteLandingScreen(
              inviteCode: inviteCode,
              characterId: characterId,
            ),
          );
        }

        // /#/join?code=OGA-XXXX (from QR code / share link)
        if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'join') {
          final inviteCode = uri.queryParameters['code'] ?? '';
          if (inviteCode.isNotEmpty) {
            return MaterialPageRoute(
              builder: (_) => InviteLandingScreen(inviteCode: inviteCode),
            );
          }
        }

        // ═══════════════════════════════════════════════════════
        // SIGN IN
        // ═══════════════════════════════════════════════════════
        if (settings.name == '/signin') {
          return MaterialPageRoute(
            builder: (context) => const OGASignInScreen(),
          );
        }

        // ═══════════════════════════════════════════════════════
        // FBS CAMPAIGN ROUTES
        // ═══════════════════════════════════════════════════════
        if (settings.name == '/fbs-account') {
          final args = settings.arguments as Map?;
          return MaterialPageRoute(
            builder: (context) => FBSAccountScreen(
              sessionId: args?['sessionId'] ?? '',
              characterName: args?['character'] ?? 'caustica',
            ),
          );
        }

        if (settings.name == '/fbs-success') {
          final args = settings.arguments as Map?;
          return MaterialPageRoute(
            builder: (context) => FBSSuccessScreen(
              sessionId: args?['sessionId'] ?? '',
              characterName: args?['character'] ?? 'caustica',
            ),
          );
        }

        // ═══════════════════════════════════════════════════════
        // WELCOME SCREEN
        // ═══════════════════════════════════════════════════════
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

        // ═══════════════════════════════════════════════════════
        // DASHBOARD
        // ═══════════════════════════════════════════════════════
        if (settings.name == '/dashboard') {
          final args = settings.arguments as Map?;
          final sessionId = args?['sessionId'];
          final character = args?['character'];
          final campaignId = args?['campaignId'];

          return MaterialPageRoute(
            builder: (context) {
              if (campaignId == 'fbs_launch') {
                return FBSCampaignDashboard(
                  sessionId: sessionId,
                  acquiredCharacterId: character,
                );
              }
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

  // ═══════════════════════════════════════════════════════════
  // LANDING PAGE LOGIC
  // ═══════════════════════════════════════════════════════════

  static Future<Widget> _getLandingPage({String? inviteCode}) async {
    try {
      final uri = Uri.base;

      // Check if this is an auth callback (has access_token or code)
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
                  'starter_character, session_id, campaign_id, campaign_joined_at, invited_by, first_name',
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

            // ═══════════════════════════════════════════════════════
            // INVITE FLOW
            // Primary: DB trigger set_invited_by_from_metadata()
            //   handles new signups automatically.
            // Fallback: Client-side detection for existing users
            //   who click an invite link (trigger only fires on INSERT).
            // ═══════════════════════════════════════════════════════
            String? pendingInvite = inviteCode;

            // Check shared_preferences (saved during InviteSignupScreen)
            if (pendingInvite == null || pendingInvite.isEmpty) {
              try {
                pendingInvite = await PendingInvite.read();
                if (pendingInvite != null && pendingInvite.isNotEmpty) {
                  debugPrint(
                    '🎟️ Found invite code in shared_preferences: $pendingInvite',
                  );
                  await PendingInvite.clear();
                }
              } catch (e) {
                debugPrint('⚠️ Error reading PendingInvite: $e');
              }
            }

            // Check user metadata (set via signInWithOtp data param)
            if (pendingInvite == null || pendingInvite.isEmpty) {
              pendingInvite = user.userMetadata?['invite_code'] as String?;
              if (pendingInvite != null) {
                debugPrint(
                  '🎟️ Found invite code in user metadata: $pendingInvite',
                );
              }
            }
            // If we have a pending invite, process it
            if (pendingInvite != null && pendingInvite.isNotEmpty) {
              final alreadyLinked = response?['invited_by'] as String?;

              if (alreadyLinked == null || alreadyLinked.isEmpty) {
                // Store the invite code — DB trigger auto-creates friendship
                await FriendService.setInvitedBy(pendingInvite);
                debugPrint('✅ Set invited_by to $pendingInvite');

                // Look up inviter name for welcome screen
                final inviterProfile = await FriendService.getPublicProfile(
                  pendingInvite,
                );
                final inviterName = inviterProfile?.displayName ?? 'a friend';

                debugPrint('🎉 Routing to invite welcome screen');
                return InviteWelcomeScreen(
                  sessionId: sessionId,
                  characterId: character,
                  inviterName: inviterName,
                  inviteCode: pendingInvite,
                );
              } else {
                debugPrint('ℹ️ User already linked to inviter: $alreadyLinked');
              }
            }

            // ═══════════════════════════════════════════════════════
            // FBS CAMPAIGN ROUTING
            // ═══════════════════════════════════════════════════════
            if (campaignId == 'fbs_launch') {
              if (joinedAt != null) {
                final joinedDate = DateTime.parse(joinedAt);
                final difference = DateTime.now().difference(joinedDate);

                if (difference.inMinutes < 5) {
                  debugPrint('🎉 New FBS user - showing success screen');
                  return FBSSuccessScreen(
                    sessionId: sessionId,
                    characterName: character,
                  );
                }
              }

              debugPrint('👤 Returning FBS user - going to FBS dashboard');
              return FBSCampaignDashboard(
                sessionId: sessionId,
                acquiredCharacterId: character,
              );
            }

            // ═══════════════════════════════════════════════════════
            // NEW ONBOARDING CHECK (Sprint 8A)
            // ═══════════════════════════════════════════════════════
            final invitedBy = response?['invited_by']?.toString();
            final firstName = response?['first_name']?.toString();
            final starterChar = response?['starter_character']?.toString();

            if (invitedBy != null &&
                invitedBy.isNotEmpty &&
                (firstName == null || firstName.isEmpty) &&
                (starterChar == null || starterChar.isEmpty)) {
              debugPrint('🚀 Routing to Onboarding (New Invited User)');
              return const InviteOnboardingScreen();
            }

            // Non-FBS users: Go to main dashboard
            debugPrint('🎯 Routing to main dashboard');
            return OGAAccountDashboard(
              sessionId: sessionId,
              acquiredCharacterId: character,
            );
          } catch (e) {
            debugPrint('⚠️ Error fetching profile: $e');
            return OGAAccountDashboard(
              sessionId: user.id,
              acquiredCharacterId: 'ryu',
            );
          }
        } else {
          debugPrint('❌ Auth timeout - no user after 5 seconds');
        }
      }
      // ═══════════════════════════════════════════════════════════
      // PATCH FOR main.dart — _getLandingPage()
      //
      // Add this block AFTER the closing brace of:
      //   if (uri.fragment.contains('access_token') || uri.queryParameters.containsKey('code')) { ... }
      //
      // And BEFORE the line:
      //   // Check if URL is /fbs-success (direct navigation)
      // ═══════════════════════════════════════════════════════════

      // ═══════════════════════════════════════════════════════
      // ALREADY AUTHENTICATED USER (session exists, no callback params)
      // This catches users returning from buffer page → Supabase verify → clean URL
      // ═══════════════════════════════════════════════════════
      final existingUser = Supabase.instance.client.auth.currentUser;
      if (existingUser != null) {
        debugPrint('👤 Found existing session for: ${existingUser.email}');

        try {
          final response = await Supabase.instance.client
              .from('profiles')
              .select(
                'starter_character, session_id, campaign_id, campaign_joined_at, invited_by, first_name',
              )
              .eq('email', existingUser.email!)
              .maybeSingle();

          final character = response?['starter_character'] ?? 'ryu';
          final sessionId = response?['session_id'] ?? existingUser.id;
          final campaignId = response?['campaign_id'];
          final joinedAt = response?['campaign_joined_at'];

          // ═══════════════════════════════════════════════════
          // INVITE CHECK for existing session
          // ═══════════════════════════════════════════════════
          final alreadyLinked = response?['invited_by'] as String?;

          if (alreadyLinked == null || alreadyLinked.isEmpty) {
            // Fallback invite detection for existing users
            String? pendingInvite;

            if (pendingInvite == null || pendingInvite.isEmpty) {
              try {
                pendingInvite = await PendingInvite.read();
                if (pendingInvite != null && pendingInvite.isNotEmpty) {
                  debugPrint(
                    '🎟️ [existing session] Found invite in shared_preferences: $pendingInvite',
                  );
                  await PendingInvite.clear();
                }
              } catch (e) {
                debugPrint('⚠️ Error reading PendingInvite: $e');
              }
            }

            if (pendingInvite == null || pendingInvite.isEmpty) {
              pendingInvite =
                  existingUser.userMetadata?['invite_code'] as String?;
              if (pendingInvite != null) {
                debugPrint(
                  '🎟️ [existing session] Found invite in user metadata: $pendingInvite',
                );
              }
            }

            // Process invite
            if (pendingInvite != null && pendingInvite.isNotEmpty) {
              await FriendService.setInvitedBy(pendingInvite);
              debugPrint('✅ Set invited_by to $pendingInvite');

              final inviterProfile = await FriendService.getPublicProfile(
                pendingInvite,
              );
              final inviterName = inviterProfile?.displayName ?? 'a friend';

              debugPrint(
                '🎉 Routing to invite welcome screen (existing session)',
              );
              return InviteWelcomeScreen(
                sessionId: sessionId,
                characterId: character,
                inviterName: inviterName,
                inviteCode: pendingInvite,
              );
            }
          }

          // ═══════════════════════════════════════════════════
          // CAMPAIGN ROUTING for existing session
          // ═══════════════════════════════════════════════════
          if (campaignId == 'fbs_launch') {
            if (joinedAt != null) {
              final joinedDate = DateTime.parse(joinedAt);
              final difference = DateTime.now().difference(joinedDate);
              if (difference.inMinutes < 5) {
                return FBSSuccessScreen(
                  sessionId: sessionId,
                  characterName: character,
                );
              }
            }
            return FBSCampaignDashboard(
              sessionId: sessionId,
              acquiredCharacterId: character,
            );
          }

          // ═══════════════════════════════════════════════════════
          // NEW ONBOARDING CHECK (Sprint 8A - Existing Session)
          // ═══════════════════════════════════════════════════════
          final invitedBy = response?['invited_by']?.toString();
          final firstName = response?['first_name']?.toString();
          final starterChar = response?['starter_character']?.toString();

          if (invitedBy != null &&
              invitedBy.isNotEmpty &&
              (firstName == null || firstName.isEmpty) &&
              (starterChar == null || starterChar.isEmpty)) {
            debugPrint('🚀 Routing to Onboarding (Existing Session)');
            return const InviteOnboardingScreen();
          }

          // Default: main dashboard
          debugPrint('🎯 Routing to main dashboard (existing session)');
          return OGAAccountDashboard(
            sessionId: sessionId,
            acquiredCharacterId: character,
          );
        } catch (e) {
          debugPrint('⚠️ Error fetching profile for existing user: $e');
          return OGAAccountDashboard(
            sessionId: existingUser.id,
            acquiredCharacterId: 'ryu',
          );
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

// ═══════════════════════════════════════════════════════════
// MAIN LANDING PAGE
// ═══════════════════════════════════════════════════════════

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

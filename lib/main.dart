import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:oga_web_showcase/screens/library/library_view.dart';
import 'package:oga_web_showcase/screens/home/live_chatbot_widget.dart';
import 'package:oga_web_showcase/screens/welcome_screen.dart';
import 'package:oga_web_showcase/screens/oga_account_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mlpinkcxdsmxicipseux.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1scGlua2N4ZHNteGljaXBzZXV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4MTI4MDAsImV4cCI6MjA4MzM4ODgwMH0.iX7By6rcSDrQ13reRrZ12C5SfHGOkKDvEOfI2dxfuDA',
  );

  runApp(const OgaApp());
}

class OgaApp extends StatelessWidget {
  const OgaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OGA',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'Inter',
      ),
      routes: {
        '/': (context) => const OgaLandingPage(),
        '/welcome': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return WelcomeScreen(sessionId: args['sessionId']);
        },
        '/dashboard': (context) {
          // Get arguments from welcome screen
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return OGAAccountDashboard(
            sessionId: args?['sessionId'],
            acquiredCharacterId: args?['character'],
          );
        },
      },
      initialRoute: '/',
    );
  }
}

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
          ? const LibraryView()
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
                    color: Colors.orange.withOpacity(0.1),
                    child: const Center(
                      child: Text("Monster Hero Placeholder"),
                    ),
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
          Image.asset('assets/logo.png', height: 60),
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
              color: Color(0xFF00FF00),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = _navigateToLibrary,
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
        color: const Color.fromARGB(255, 0, 0, 0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LiveNetlifyChatbot(
        widgetUrl: 'https://oga-inline-chatbot.netlify.app/',
        onComplete: onComplete,
      ),
    );
  }
}

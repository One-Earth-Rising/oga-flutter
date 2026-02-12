import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FBSSuccessScreen extends StatefulWidget {
  final String sessionId;
  final String characterName;

  const FBSSuccessScreen({
    super.key,
    required this.sessionId,
    required this.characterName,
  });

  @override
  State<FBSSuccessScreen> createState() => _FBSSuccessScreenState();
}

class _FBSSuccessScreenState extends State<FBSSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isGranting = true;

  @override
  void initState() {
    super.initState();
    _claimCharacter(); // Automatically grant character on load
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(_controller);
    _controller.forward();
  }

  Future<void> _claimCharacter() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // RPC call to the SQL function we created
        await Supabase.instance.client.rpc(
          'grant_fbs_character',
          params: {
            'target_user_id': user.id,
            'character_slug': widget.characterName.toLowerCase(),
          },
        );
      }
    } catch (e) {
      debugPrint('Error granting character: $e');
    } finally {
      if (mounted) setState(() => _isGranting = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF00).withOpacity(0.15),
                        blurRadius: _glowAnimation.value * 5,
                        spreadRadius: _glowAnimation.value,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'ACQUISITION COMPLETE',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 450),
                      child: Image.network(
                        'https://mlpinkcxdsmxicipseux.supabase.co/storage/v1/object/public/campaign-assets/fbs_launch/${widget.characterName.toLowerCase()}.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    widget.characterName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 300,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF00),
                      ),
                      onPressed: _isGranting
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context,
                              '/dashboard',
                              arguments: {
                                'sessionId': widget.sessionId,
                                'character': widget.characterName,
                                'campaignId': 'fbs_launch', // ← ADD THIS LINE
                              },
                            ),
                      child: _isGranting
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'DISCOVER IN LIBRARY',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

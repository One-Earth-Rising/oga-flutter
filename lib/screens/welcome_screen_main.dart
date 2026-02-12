import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeScreenMain extends StatefulWidget {
  final String sessionId;

  const WelcomeScreenMain({super.key, required this.sessionId});

  @override
  State<WelcomeScreenMain> createState() => _WelcomeScreenMainState();
}

class _WelcomeScreenMainState extends State<WelcomeScreenMain> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _characterName = 'RYU';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch user data
      final response = await supabase
          .from('profiles')
          .select()
          .eq('session_id', widget.sessionId)
          .single();

      setState(() {
        _characterName = response['starter_character']?.toUpperCase() ?? 'RYU';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00C806)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00C806), size: 100),
            const SizedBox(height: 40),
            const Text(
              'YOU HAVE ACQUIRED',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _characterName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Main Character',
              style: TextStyle(color: Color(0xFF00C806), fontSize: 20),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(
                  context,
                  '/dashboard',
                  arguments: {
                    'sessionId': widget.sessionId,
                    'character': _characterName.toLowerCase(),
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C806),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
              ),
              child: const Text(
                'DISCOVER',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

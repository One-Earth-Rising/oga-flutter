import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

class LiveNetlifyChatbot extends StatefulWidget {
  final String widgetUrl;
  final VoidCallback onComplete;

  const LiveNetlifyChatbot({
    super.key,
    required this.widgetUrl,
    required this.onComplete,
  });

  @override
  State<LiveNetlifyChatbot> createState() => _LiveNetlifyChatbotState();
}

class _LiveNetlifyChatbotState extends State<LiveNetlifyChatbot> {
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();

    // Register the iframe view
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      'netlify-chatbot-view',
      (int viewId) => html.IFrameElement()
        ..src = widget.widgetUrl
        ..style.border = 'none'
        ..style.height = '100%'
        ..style.width = '100%',
    );

    // Listen for messages from the chatbot iframe
    _messageSubscription = html.window.onMessage.listen((event) {
      print('📩 Received message from chatbot: ${event.data}');

      // Handle simple string message
      if (event.data == "ONBOARDING_COMPLETE") {
        print('✅ Onboarding complete (simple message)');
        widget.onComplete();
        return;
      }

      // Handle structured message with session_id
      if (event.data is String) {
        try {
          final data = jsonDecode(event.data as String);

          if (data['type'] == 'ONBOARDING_REDIRECT') {
            final sessionId =
                data['userData']?['sessionId'] ?? data['sessionId'];

            print('🎯 Navigating to welcome screen with session: $sessionId');

            if (sessionId != null && mounted) {
              Navigator.of(context).pushReplacementNamed(
                '/welcome',
                arguments: {'sessionId': sessionId},
              );
            } else {
              print('⚠️ No session ID found, falling back to library');
              widget.onComplete();
            }
          } else if (data['type'] == 'ONBOARDING_COMPLETE') {
            print('✅ Onboarding complete (structured message)');
            widget.onComplete();
          }
        } catch (e) {
          print('⚠️ Could not parse message: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'netlify-chatbot-view');
  }
}

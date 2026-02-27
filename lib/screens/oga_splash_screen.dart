import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

/// Full-screen splash / landing screen for unauthenticated visitors.
///
/// Embeds the CRT loading animation (web/splash/) via iframe.
/// When user clicks "ENTER NOW", the iframe sends a postMessage
/// and this screen navigates to the sign-in page.
///
/// Replaces the old chatbot-based OgaLandingPage for the beta launch.
class OGASplashScreen extends StatefulWidget {
  const OGASplashScreen({super.key});

  @override
  State<OGASplashScreen> createState() => _OGASplashScreenState();
}

class _OGASplashScreenState extends State<OGASplashScreen> {
  static const _viewType = 'oga-splash-iframe';
  static bool _factoryRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _listenForMessages();
  }

  void _registerViewFactory() {
    if (_factoryRegistered) return;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.IFrameElement()
        ..src = 'splash/index.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'autoplay'
        ..setAttribute('scrolling', 'no');
    });

    _factoryRegistered = true;
  }

  void _listenForMessages() {
    html.window.onMessage.listen((event) {
      try {
        if (event.data is! String) return;
        final data = jsonDecode(event.data as String);

        if (data['type'] == 'enterOGA' && mounted) {
          debugPrint('🚀 ENTER NOW clicked — navigating to sign-in');
          Navigator.pushNamed(context, '/signin');
        }
      } catch (_) {
        // Ignore non-JSON messages (browser extensions, etc.)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: HtmlElementView(viewType: _viewType),
    );
  }
}

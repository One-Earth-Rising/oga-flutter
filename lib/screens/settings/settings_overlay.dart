import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsOverlay extends StatefulWidget {
  const SettingsOverlay({super.key});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  String _activeTab = 'Account'; // Account, Password, Payment, Connections
  static const Color ogaGreen = Color(0xFF00C806);

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          width: isMobile ? double.infinity : 800,
          height: isMobile ? double.infinity : 600,
          margin: isMobile ? EdgeInsets.zero : const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D),
            borderRadius: BorderRadius.circular(isMobile ? 0 : 12),
            border: Border.all(color: Colors.white12),
          ),
          child: isMobile ? _buildMobileView() : _buildWebView(),
        ),
      ),
    );
  }

  // --- WEB VIEW: Sidebar Layout ---
  Widget _buildWebView() {
    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: 200,
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 40),
              _settingsTab('Account'),
              _settingsTab('Password'),
              _settingsTab('Payment Method'),
              _settingsTab('Connections'),
              const Spacer(),
              const Text(
                "Log out",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
        // Content Area
        Expanded(child: _buildActiveContent(false)),
      ],
    );
  }

  // --- MOBILE VIEW: Tab Bar Layout ---
  Widget _buildMobileView() {
    return Column(
      children: [
        AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "SETTINGS",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _settingsTab('Account'),
              _settingsTab('Password'),
              _settingsTab('Payment Method'),
              _settingsTab('Connections'),
            ],
          ),
        ),
        Expanded(child: _buildActiveContent(true)),
      ],
    );
  }

  Widget _buildActiveContent(bool isMobile) {
    switch (_activeTab) {
      case 'Connections':
        return _buildConnections(isMobile);
      case 'Password':
        return _buildPasswordForm();
      case 'Payment Method':
        return _buildPaymentForm();
      default:
        return _buildAccountForm();
    }
  }

  // --- CONTENT MODULES (MATCHING WHITEBOARD FLOW) ---

  Widget _buildConnections(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PLATFORM CONNECTIONS",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          _connectionTile("Playstation Network", "Connected", true),
          _connectionTile("Xbox Network", "Connect Account", false),
          _connectionTile("Nintendo Network", "Connect Account", false),
          _connectionTile("Wallet Connect", "Connect Wallet", false),
        ],
      ),
    );
  }

  Widget _connectionTile(String label, String status, bool connected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Text(
            status,
            style: TextStyle(
              color: connected ? ogaGreen : Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountForm() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          _buildTextField("USERNAME", "@nknight"),
          _buildTextField("FIRST NAME", "Jan"),
          _buildTextField("LAST NAME", "Roessner"),
          _buildTextField("EMAIL", "jan@oga.com"),
          const SizedBox(height: 20),
          _themedButton("SAVE CHANGES", ogaGreen),
        ],
      ),
    );
  }

  // --- REUSABLE UI COMPONENTS ---

  Widget _settingsTab(String label) {
    bool active = _activeTab == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _activeTab = label);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Text(
          label,
          style: TextStyle(
            color: active ? ogaGreen : Colors.white38,
            fontWeight: active ? FontWeight.w900 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      children: [
        const CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage('assets/characters/guggimon.png'),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: ogaGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, size: 12, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: value),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 10),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white12),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: ogaGreen),
          ),
        ),
      ),
    );
  }

  Widget _themedButton(String label, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordForm() => const Center(child: Text("Password Logic"));
  Widget _buildPaymentForm() => const Center(child: Text("Payment Logic"));
}

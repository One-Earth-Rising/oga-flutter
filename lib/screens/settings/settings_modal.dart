import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Account settings modal.
/// Desktop: Centered overlay with sidebar navigation + content panel.
/// Mobile: Full-screen with horizontal pill tabs.
class SettingsModal extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? avatarImagePath;

  const SettingsModal({super.key, this.userData, this.avatarImagePath});

  /// Show as a dialog overlay
  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? userData,
    String? avatarImagePath,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsModal(
            userData: userData,
            avatarImagePath: avatarImagePath,
          ),
        ),
      );
    }

    return showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: SettingsModal(
            userData: userData,
            avatarImagePath: avatarImagePath,
          ),
        ),
      ),
    );
  }

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color surfaceCard = Color(0xFF1A1A1A);
  static const Color ironGrey = Color(0xFF2C2C2C);

  final _tabs = ['Profile', 'Account', 'Password', 'Payment Method', 'Connect'];
  int _selectedTabIndex = 1; // Default to Account

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return isMobile ? _buildMobileLayout() : _buildDesktopLayout();
  }

  // ═══════════════════════════════════════════════════════════
  // DESKTOP: Centered modal with sidebar
  // ═══════════════════════════════════════════════════════════

  Widget _buildDesktopLayout() {
    return Container(
      width: 680,
      height: 520,
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ironGrey),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Sidebar
            SizedBox(width: 200, child: _buildSidebar()),
            // Divider
            Container(width: 1, color: ironGrey),
            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: surfaceCard,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _buildAvatarSection(),
          const SizedBox(height: 28),

          // Tab list
          ..._tabs.asMap().entries.map((e) => _buildSidebarTab(e.key, e.value)),

          const Spacer(),

          // Log out
          GestureDetector(
            onTap: _handleLogout,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Log out',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: deepCharcoal,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ironGrey),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: widget.avatarImagePath != null
                ? Image.asset(
                    widget.avatarImagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarFallback(),
                  )
                : _avatarFallback(),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: voidBlack,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: ironGrey),
            ),
            child: const Icon(Icons.edit, color: Colors.white54, size: 12),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: deepCharcoal,
      child: const Center(
        child: Icon(Icons.person, color: Colors.white24, size: 30),
      ),
    );
  }

  Widget _buildSidebarTab(int index, String label) {
    final isActive = _selectedTabIndex == index;
    // Show green dot for "Account" tab
    final showDot = label == 'Account';

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: neonGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MOBILE: Full-screen with pill tabs
  // ═══════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: voidBlack,
      body: SafeArea(
        child: Column(
          children: [
            // Horizontal pill tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isActive = _selectedTabIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isActive ? Colors.white : ironGrey,
                          ),
                        ),
                        child: Text(
                          _tabs[index],
                          style: TextStyle(
                            color: isActive ? Colors.black : Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Avatar (mobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildAvatarSection(),
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENT PANEL
  // ═══════════════════════════════════════════════════════════

  Widget _buildContent() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(child: _buildTabContent()),
        ),
        // Close button
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: voidBlack,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_tabs[_selectedTabIndex]) {
      case 'Profile':
        return _buildProfileContent();
      case 'Account':
        return _buildAccountContent();
      case 'Password':
        return _buildPasswordContent();
      case 'Payment Method':
        return _buildPaymentContent();
      case 'Connect':
        return _buildConnectContent();
      default:
        return const SizedBox();
    }
  }

  // ─── Profile Tab ──────────────────────────────────────────

  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('PROFILE'),
        const SizedBox(height: 20),
        _buildTextField('DISPLAY NAME', widget.userData?['full_name'] ?? ''),
        _buildTextField('BIO', widget.userData?['bio'] ?? '', maxLines: 3),
        _buildTextField('LOCATION', ''),
      ],
    );
  }

  // ─── Account Tab ──────────────────────────────────────────

  Widget _buildAccountContent() {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final username = widget.userData?['full_name'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ACCOUNT'),
        const SizedBox(height: 20),
        _buildTextField(
          'USERNAME',
          '@${username.toLowerCase().replaceAll(' ', '')}',
        ),
        _buildTextField('FIRST NAME', username.split(' ').first),
        _buildTextField(
          'LAST NAME',
          username.split(' ').length > 1 ? username.split(' ').last : '',
        ),
        _buildTextField('EMAIL', email),
        const SizedBox(height: 20),
        _buildOutlinedButton('DELETE MY ACCOUNT'),
      ],
    );
  }

  // ─── Password Tab ─────────────────────────────────────────

  Widget _buildPasswordContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('PASSWORD'),
        const SizedBox(height: 20),
        _buildTextField('CURRENT PASSWORD', '••••••••••••••', obscure: true),
        const SizedBox(height: 16),
        _buildOutlinedButton('CHANGE MY PASSWORD'),
      ],
    );
  }

  // ─── Payment Method Tab ───────────────────────────────────

  Widget _buildPaymentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('PAYMENT METHOD'),
        const SizedBox(height: 40),
        Center(
          child: Text(
            'No payment methods added yet.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Connect Tab ──────────────────────────────────────────

  Widget _buildConnectContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('OGA ACCOUNT'),
        const SizedBox(height: 20),
        _buildConnectRow(
          icon: Icons.videogame_asset,
          name: 'Playstation Network',
          status: 'Connected',
          isConnected: true,
        ),
        _buildConnectRow(
          icon: Icons.sports_esports,
          name: 'Xbox Network',
          status: 'Connect Account',
          isConnected: false,
        ),
        _buildConnectRow(
          icon: Icons.gamepad,
          name: 'Nintendo Network',
          status: 'Connect Account',
          isConnected: false,
        ),
        _buildConnectRow(
          icon: Icons.account_balance_wallet,
          name: 'Wallet Connect',
          status: 'Connect Account',
          isConnected: false,
        ),
        const SizedBox(height: 24),
        _buildOutlinedButton('DISCONNECT ALL MY ACCOUNTS'),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value, {
    bool obscure = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ironGrey),
            ),
            child: Text(
              obscure ? '••••••••••••••' : value,
              style: TextStyle(
                color: value.isEmpty
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white70,
                fontSize: 14,
              ),
              maxLines: maxLines,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutlinedButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ironGrey),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildConnectRow({
    required IconData icon,
    required String name,
    required String status,
    required bool isConnected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Platform icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ironGrey),
            ),
            child: Icon(icon, color: Colors.white54, size: 20),
          ),
          const SizedBox(width: 14),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: isConnected ? neonGreen : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Action
          isConnected
              ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 16),
                )
              : const Icon(
                  Icons.arrow_forward,
                  color: Colors.white38,
                  size: 20,
                ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}

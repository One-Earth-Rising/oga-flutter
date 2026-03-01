import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/friend_service.dart';
import '../../screens/feedback_modal.dart';
import '../../services/analytics_service.dart';

// For web file picking
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Account settings modal.
/// Desktop: Centered overlay with sidebar navigation + content panel.
/// Mobile: Full-screen with horizontal pill tabs.
/// Fields are editable and persist to Supabase.
class SettingsModal extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? avatarImagePath;
  final VoidCallback? onProfileUpdated;

  const SettingsModal({
    super.key,
    this.userData,
    this.avatarImagePath,
    this.onProfileUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? userData,
    String? avatarImagePath,
    VoidCallback? onProfileUpdated,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsModal(
            userData: userData,
            avatarImagePath: avatarImagePath,
            onProfileUpdated: onProfileUpdated,
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
            onProfileUpdated: onProfileUpdated,
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

  static const _months = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final _tabs = ['Profile', 'Account', 'Password', 'Payment Method', 'Connect'];
  int _selectedTabIndex = 0; // Default to Profile

  // Editable controllers - Profile tab
  late TextEditingController _displayNameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;

  // Editable controllers - Account tab
  late TextEditingController _usernameCtrl;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _hasChanges = false;
  String? _avatarUrl;
  String? _inviteCode;
  DateTime? _joinedDate;

  @override
  void initState() {
    super.initState();
    final data = widget.userData ?? {};
    _displayNameCtrl = TextEditingController(text: data['full_name'] ?? '');
    _bioCtrl = TextEditingController(text: data['bio'] ?? '');
    _locationCtrl = TextEditingController(text: data['location'] ?? '');
    _usernameCtrl = TextEditingController(text: data['username'] ?? '');
    _firstNameCtrl = TextEditingController(text: data['first_name'] ?? '');
    _lastNameCtrl = TextEditingController(text: data['last_name'] ?? '');
    _avatarUrl = data['avatar_url'] as String?;
    _inviteCode = data['invite_code'] as String?;

    // Get joined date
    final user = Supabase.instance.client.auth.currentUser;
    _joinedDate = user?.createdAt != null
        ? DateTime.tryParse(user!.createdAt)
        : null;
    if (_joinedDate == null && data['created_at'] != null) {
      _joinedDate = DateTime.tryParse(data['created_at'].toString());
    }

    // Listen for changes
    _displayNameCtrl.addListener(_markChanged);
    _bioCtrl.addListener(_markChanged);
    _locationCtrl.addListener(_markChanged);
    _usernameCtrl.addListener(_markChanged);
    _firstNameCtrl.addListener(_markChanged);
    _lastNameCtrl.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _usernameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  String get _joinedText {
    if (_joinedDate == null) return '';
    return 'Joined ${_months[_joinedDate!.month]} ${_joinedDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return isMobile ? _buildMobileLayout() : _buildDesktopLayout();
  }

  // ═══════════════════════════════════════════════════════════
  // DESKTOP LAYOUT
  // ═══════════════════════════════════════════════════════════

  Widget _buildDesktopLayout() {
    return Container(
      width: 700,
      height: 560,
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ironGrey),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            SizedBox(width: 200, child: _buildSidebar()),
            Container(width: 1, color: ironGrey),
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
          _buildAvatarSection(),
          const SizedBox(height: 12),
          // Name under avatar
          Text(
            '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim().isEmpty
                ? _displayNameCtrl.text
                : '${_firstNameCtrl.text} ${_lastNameCtrl.text}'.trim(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (_usernameCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '@${_usernameCtrl.text}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 20),
          ..._tabs.asMap().entries.map((e) => _buildSidebarTab(e.key, e.value)),
          const Spacer(),
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
    return GestureDetector(
      onTap: _pickAvatar,
      child: Stack(
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
              child: _isUploadingAvatar
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 57, 255, 20),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _avatarUrl != null
                  ? Image.network(
                      _avatarUrl!,
                      fit: BoxFit.cover,
                      width: 72,
                      height: 72,
                      errorBuilder: (_, __, ___) => _avatarFallback(),
                    )
                  : widget.avatarImagePath != null
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
      ),
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
  // MOBILE LAYOUT
  // ═══════════════════════════════════════════════════════════

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: voidBlack,
      appBar: AppBar(
        backgroundColor: voidBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Pill tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
          // Avatar
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENT
  // ═══════════════════════════════════════════════════════════

  Widget _buildContent() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(child: _buildTabContent()),
        ),
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

  // ─── Profile Tab (editable) ───────────────────────────────

  Widget _buildProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('PROFILE'),
        const SizedBox(height: 20),
        _buildEditableField('DISPLAY NAME', _displayNameCtrl),
        _buildEditableField('BIO', _bioCtrl, maxLines: 3),
        _buildEditableField('LOCATION', _locationCtrl),

        // Invite code (read-only)
        if (_inviteCode != null) ...[
          const SizedBox(height: 8),
          _buildReadOnlyField('YOUR INVITE CODE', _inviteCode!),
        ],

        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  // ─── Account Tab ──────────────────────────────────────────

  Widget _buildAccountContent() {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ACCOUNT'),
        const SizedBox(height: 20),
        _buildEditableField('USERNAME', _usernameCtrl, prefix: '@'),
        _buildEditableField('FIRST NAME', _firstNameCtrl),
        _buildEditableField('LAST NAME', _lastNameCtrl),
        _buildReadOnlyField('EMAIL', email),

        // Joined date
        if (_joinedText.isNotEmpty)
          _buildReadOnlyField('MEMBER SINCE', _joinedText),

        const SizedBox(height: 24),
        _buildSaveButton(),
        const SizedBox(height: 16),
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
        _buildReadOnlyField('CURRENT PASSWORD', '••••••••••••••'),
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

  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? prefix,
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
            decoration: BoxDecoration(
              color: deepCharcoal,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ironGrey),
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              decoration: InputDecoration(
                prefixText: prefix,
                prefixStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                ),
                hintText: label,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
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
              border: Border.all(color: ironGrey.withValues(alpha: 0.5)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _hasChanges && !_isSaving ? _handleSave : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: _hasChanges ? neonGreen : ironGrey,
          borderRadius: BorderRadius.circular(6),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'SAVE CHANGES',
                style: TextStyle(
                  color: _hasChanges ? Colors.black : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
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

  // ═══════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    // Compute full_name from first + last
    final first = _firstNameCtrl.text.trim();
    final last = _lastNameCtrl.text.trim();
    final computedFullName = '$first $last'.trim();

    final success = await FriendService.updateProfile(
      fullName: computedFullName.isNotEmpty
          ? computedFullName
          : _displayNameCtrl.text.trim(),
      firstName: first,
      lastName: last,
      username: _usernameCtrl.text.trim().toLowerCase().replaceAll(' ', ''),
      bio: _bioCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
    );

    setState(() {
      _isSaving = false;
      if (success) _hasChanges = false;
    });

    if (success) {
      AnalyticsService.trackSettingsAction('profile_saved');
      widget.onProfileUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated!'),
            backgroundColor: neonGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _pickAvatar() {
    // Web file picker
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    input.onChange.listen((event) async {
      final file = input.files?.first;
      if (file == null) return;

      setState(() => _isUploadingAvatar = true);

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;

      final bytes = Uint8List.fromList(reader.result as List<int>);
      final url = await FriendService.uploadAvatar(bytes, file.name);

      setState(() {
        _isUploadingAvatar = false;
        if (url != null) _avatarUrl = url;
      });

      if (url != null) {
        widget.onProfileUpdated?.call();
      }
    });
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

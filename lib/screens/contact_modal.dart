import 'package:flutter/material.dart';

/// Contact Us modal / full-screen overlay.
/// Fields: First Name, Last Name, Email Address, Message.
/// SEND button activates (turns green) when all fields have content.
class ContactModal extends StatefulWidget {
  const ContactModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const Center(
        child: Material(color: Colors.transparent, child: ContactModal()),
      ),
    );
  }

  @override
  State<ContactModal> createState() => _ContactModalState();
}

class _ContactModalState extends State<ContactModal> {
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color voidBlack = Color(0xFF000000);
  static const Color deepCharcoal = Color(0xFF121212);
  static const Color ironGrey = Color(0xFF2C2C2C);

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  bool get _isValid =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _messageController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final contentWidth = isMobile ? screenWidth - 40 : 500.0;

    return SizedBox(
      width: screenWidth,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          // Scrollable content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    const Text(
                      'CONTACT US',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We\'ll get back to you as soon we\'re\nready for you!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Form fields
                    _buildField('FIRST NAME*', _firstNameController),
                    const SizedBox(height: 12),
                    _buildField('LAST NAME*', _lastNameController),
                    const SizedBox(height: 12),
                    _buildField(
                      'EMAIL ADDRESS *',
                      _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildField('MESSAGE*', _messageController, maxLines: 6),
                    const SizedBox(height: 24),

                    // Send button
                    GestureDetector(
                      onTap: _isValid ? _handleSend : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isValid
                              ? neonGreen
                              : Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'SEND',
                            style: TextStyle(
                              color: _isValid
                                  ? Colors.black
                                  : Colors.white.withValues(alpha: 0.3),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 24,
            right: 24,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: deepCharcoal,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ironGrey),
                ),
                child: const Icon(Icons.close, color: Colors.white70, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
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
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            decoration: InputDecoration(
              hintText: label.replaceAll('*', '').trim(),
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleSend() {
    // TODO: Wire to backend (Supabase function or email service)
    debugPrint(
      'Contact form submitted: '
      '${_firstNameController.text}, '
      '${_lastNameController.text}, '
      '${_emailController.text}',
    );
    Navigator.pop(context);

    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message sent! We\'ll be in touch.'),
        backgroundColor: const Color(0xFF39FF14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

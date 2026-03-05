// lib/modals/fbs_redeem_modal.dart
// Sprint 17 — FBS Candy Code Redeem Modal
// Slide-up modal for entering a code from FBS candy packaging.
// On success, shows inline character reveal before closing.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/fbs_service.dart';

class FbsRedeemModal extends StatefulWidget {
  /// Called on successful redemption with the unlocked character ID.
  final void Function(String characterId) onSuccess;

  const FbsRedeemModal({super.key, required this.onSuccess});

  static Future<void> show(
    BuildContext context, {
    required void Function(String characterId) onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => FbsRedeemModal(onSuccess: onSuccess),
    );
  }

  @override
  State<FbsRedeemModal> createState() => _FbsRedeemModalState();
}

class _FbsRedeemModalState extends State<FbsRedeemModal>
    with SingleTickerProviderStateMixin {
  // ─── Colors ────────────────────────────────────────────────
  static const _black = Color(0xFF000000);
  static const _charcoal = Color(0xFF121212);
  static const _ironGrey = Color(0xFF2C2C2C);
  static const _neonGreen = Color(0xFF39FF14);
  static const _white = Color(0xFFFFFFFF);
  static const _fbsCyan = Color(
    0xFF00CFCF,
  ); // FBS brand accent (borrower btn established in Sprint 16)

  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  // Success state
  bool _showSuccess = false;
  String? _unlockedCharacterId;
  FbsCharacter? _unlockedCharacter;

  late AnimationController _successAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _successAnim,
      curve: Curves.easeOutBack,
    );
    _glowAnim = CurvedAnimation(parent: _successAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  // ─── Redeem ─────────────────────────────────────────────────
  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(
        () => _errorMessage = 'Enter the code from your FBS candy packaging.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await FbsService.redeemCode(code);

    if (!mounted) return;

    if (result.success && result.characterId != null) {
      _unlockedCharacterId = result.characterId;
      _unlockedCharacter = FbsService.allFbsCharacters
          .where((c) => c.id == result.characterId)
          .firstOrNull;

      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });
      _successAnim.forward();

      // Notify parent after a short display pause
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          widget.onSuccess(result.characterId!);
        }
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = FbsService.errorMessage(result.error!);
      });
    }
  }

  // ─── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: _charcoal,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: _ironGrey, width: 1),
            left: BorderSide(color: _ironGrey, width: 1),
            right: BorderSide(color: _ironGrey, width: 1),
          ),
        ),
        child: _showSuccess ? _buildSuccessState() : _buildInputState(),
      ),
    );
  }

  // ─── Input State ────────────────────────────────────────────
  Widget _buildInputState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _ironGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _neonGreen.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: _neonGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ENTER REDEEM CODE',
                    style: TextStyle(
                      color: _white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Helvetica Neue',
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Found on FBS candy packaging',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                      fontFamily: 'Helvetica Neue',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Code input
          TextField(
            controller: _codeController,
            focusNode: _focusNode,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              UpperCaseTextFormatter(),
            ],
            style: const TextStyle(
              color: _white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              fontFamily: 'Helvetica Neue',
            ),
            decoration: InputDecoration(
              hintText: 'FBS-XXXX-XXXX',
              hintStyle: TextStyle(
                color: _white.withValues(alpha: 0.2),
                fontSize: 20,
                letterSpacing: 3,
                fontFamily: 'Helvetica Neue',
              ),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _ironGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _ironGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _neonGreen, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              suffixIcon: _codeController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: Color(0xFF666666),
                        size: 18,
                      ),
                      onPressed: () => setState(() => _codeController.clear()),
                    )
                  : null,
            ),
            onSubmitted: (_) => _submit(),
            onChanged: (_) => setState(() => _errorMessage = null),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontFamily: 'Helvetica Neue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // CTA button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonGreen,
                disabledBackgroundColor: _neonGreen.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _black,
                      ),
                    )
                  : const Text(
                      'UNLOCK CHARACTER',
                      style: TextStyle(
                        color: _black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontFamily: 'Helvetica Neue',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Buy link
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Buy FBS candy at Walmart →',
                style: TextStyle(
                  color: _white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontFamily: 'Helvetica Neue',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Success State ──────────────────────────────────────────
  Widget _buildSuccessState() {
    final char = _unlockedCharacter;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glow ring + character icon
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, child) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _neonGreen.withValues(alpha: 0.6 * _glowAnim.value),
                    blurRadius: 40 * _glowAnim.value,
                    spreadRadius: 8 * _glowAnim.value,
                  ),
                ],
                border: Border.all(
                  color: _neonGreen.withValues(alpha: _glowAnim.value),
                  width: 2,
                ),
                color: _charcoal,
              ),
              child: child,
            ),
            child: const Center(
              child: Icon(
                Icons.emoji_events_outlined,
                color: _neonGreen,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Unlocked badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _neonGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _neonGreen.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'CHARACTER UNLOCKED',
              style: TextStyle(
                color: _neonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Character name
          ScaleTransition(
            scale: _scaleAnim,
            child: Text(
              char?.name ?? _unlockedCharacterId?.toUpperCase() ?? 'CHARACTER',
              style: const TextStyle(
                color: _white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ),
          if (char?.flavor != null) ...[
            const SizedBox(height: 6),
            Text(
              char!.flavor,
              style: TextStyle(
                color: _white.withValues(alpha: 0.5),
                fontSize: 14,
                fontFamily: 'Helvetica Neue',
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Added to your library',
            style: TextStyle(
              color: _white.withValues(alpha: 0.35),
              fontSize: 13,
              fontFamily: 'Helvetica Neue',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formatter ──────────────────────────────────────────────────
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

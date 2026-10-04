import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/providers/wilddeck_providers.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

/// WildDeck Login screen — email/password + guest entry.
/// No Firebase dependency in M1; uses MockPlayerService.
class WildDeckLoginScreen extends ConsumerStatefulWidget {
  const WildDeckLoginScreen({super.key});

  @override
  ConsumerState<WildDeckLoginScreen> createState() => _WildDeckLoginScreenState();
}

class _WildDeckLoginScreenState extends ConsumerState<WildDeckLoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _guestCtrl    = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _isLoading    = false;
  bool _guestMode    = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    unawaited(_fadeCtrl.forward());
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _guestCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(playerProvider.notifier).signInWithEmail(
        _emailCtrl.text.trim(), _passwordCtrl.text,
      );
      if (mounted) context.go(WildRoutes.home);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _guestEntry() async {
    final name = _guestCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Please enter a display name');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(playerProvider.notifier).signInAsGuest(name);
      if (mounted) context.go(WildRoutes.home);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: WildDeckTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WildDeckTheme.heroGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildModeToggle(),
                  const SizedBox(height: 24),
                  _guestMode ? _buildGuestForm() : _buildEmailForm(),
                  const SizedBox(height: 16),
                  _buildSwitchModeText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [WildDeckTheme.cardRed, WildDeckTheme.cardWild],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: WildDeckTheme.buttonGlow(WildDeckTheme.cardRed),
          ),
          child: const Center(
            child: Text('WD', style: TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2,
            )),
          ),
        ),
        const SizedBox(height: 16),
        const Text('WILDDECK', style: TextStyle(
          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 5,
        )),
        const SizedBox(height: 4),
        const Text('Play Wild. Win Fast.', style: TextStyle(
          color: WildDeckTheme.gold, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5,
        )),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusMedium,
        border: Border.all(color: WildDeckTheme.navyBorder),
      ),
      child: Row(
        children: [
          _Tab(label: 'Sign In',   active: !_guestMode, onTap: () => setState(() => _guestMode = false)),
          _Tab(label: 'Play as Guest', active: _guestMode,  onTap: () => setState(() => _guestMode = true)),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email required';
              if (!v.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: !_showPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Password required' : null,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'SIGN IN',
            onPressed: _signInWithEmail,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Create Account',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildGuestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Jump in without an account. Progress is saved locally.',
          style: TextStyle(color: WildDeckTheme.textSecond, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _guestCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Your display name',
            prefixIcon: Icon(Icons.person_outline),
            hintText: 'e.g. WildAce',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'PLAY AS GUEST',
          onPressed: _guestEntry,
          isLoading: _isLoading,
          icon: Icons.bolt,
        ),
      ],
    );
  }

  Widget _buildSwitchModeText() {
    if (_guestMode) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('New to WildDeck? ', style: TextStyle(color: WildDeckTheme.textMuted)),
        GestureDetector(
          onTap: () => setState(() => _guestMode = true),
          child: const Text('Try as Guest', style: TextStyle(
            color: WildDeckTheme.gold, fontWeight: FontWeight.w700,
          )),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: active ? WildDeckTheme.primaryButtonGradient : null,
            borderRadius: WildDeckTheme.radiusMedium,
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(
            color: active ? Colors.white : WildDeckTheme.textMuted,
            fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          )),
        ),
      ),
    );
  }
}

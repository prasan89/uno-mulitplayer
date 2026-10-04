import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:wilddeck/core/providers/auth_provider.dart';
import 'package:wilddeck/shared/widgets/loading_overlay.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;

  // Stats — replace these with values from a user stats provider
  final int _elo = 1200;
  final int _gamesPlayed = 47;
  final int _gamesWon = 23;

  double get _winRate =>
      _gamesPlayed > 0 ? _gamesWon / _gamesPlayed : 0.0;

  User? get _user => ref.read(currentUserProvider);

  String get _displayName =>
      _user?.displayName?.isNotEmpty == true
          ? _user!.displayName!
          : 'Player';

  @override
  void initState() {
    super.initState();
    _nameController.text = _displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName.length < 2 || newName.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Name must be 2–50 characters'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateDisplayName(newName);
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signOut();
      // GoRouter redirect handles navigation to /auth/login
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the display name rebuilds if the user profile updates
    ref.watch(authProvider);
    final theme = Theme.of(context);
    final name = _displayName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/lobby'),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _nameController.text = name;
                setState(() => _isEditing = true);
              },
              tooltip: 'Edit profile',
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Signing out...',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: theme.colorScheme.primary,
                        backgroundImage: _user?.photoURL != null
                            ? NetworkImage(_user!.photoURL!)
                            : null,
                        child: _user?.photoURL == null
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.camera_alt, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Display Name
                if (_isEditing) ...[
                  TextFormField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'Your name',
                    ),
                    maxLength: 50,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveDisplayName,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Text(
                      name,
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_user?.email != null) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        _user!.email!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 32),

                // Stats Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatRow(
                          label: 'ELO Rating',
                          value: _elo.toString(),
                          icon: Icons.star,
                          iconColor: theme.colorScheme.secondary,
                        ),
                        const Divider(height: 24),
                        _StatRow(
                          label: 'Games Played',
                          value: _gamesPlayed.toString(),
                          icon: Icons.sports_esports,
                          iconColor: theme.colorScheme.primary,
                        ),
                        const Divider(height: 24),
                        _StatRow(
                          label: 'Games Won',
                          value: _gamesWon.toString(),
                          icon: Icons.emoji_events,
                          iconColor: theme.colorScheme.secondary,
                        ),
                        const Divider(height: 24),
                        _StatRow(
                          label: 'Win Rate',
                          value:
                              '${(_winRate * 100).toStringAsFixed(1)}%',
                          icon: Icons.percent,
                          iconColor: _winRate >= 0.5
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Win rate progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Win Rate', style: theme.textTheme.bodySmall),
                        Text(
                          '${(_winRate * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _winRate,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _winRate >= 0.5
                              ? Colors.green
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Sign Out
                OutlinedButton.icon(
                  key: const Key('sign_out_button'),
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

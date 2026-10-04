import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wilddeck/core/providers/wilddeck_providers.dart';
import 'package:wilddeck/core/router/wilddeck_router.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late SettingsState _settings;

  @override
  void initState() {
    super.initState();
    _settings = ref.read(settingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    _settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            const WildDeckTopBar(title: 'Settings'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _Section(title: 'AUDIO', children: [
                    _SwitchRow(
                      icon: Icons.volume_up_rounded,
                      label: 'Sound Effects',
                      value: _settings.soundEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setSoundEnabled(value: v)),
                    _SwitchRow(
                      icon: Icons.music_note_rounded,
                      label: 'Background Music',
                      value: _settings.musicEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setMusicEnabled(value: v)),
                    _SliderRow(
                      icon: Icons.volume_down_rounded,
                      label: 'Master Volume',
                      value: _settings.masterVolume,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setMasterVolume(v)),
                  ]),
                  const SizedBox(height: 16),
                  _Section(title: 'GAMEPLAY', children: [
                    _SwitchRow(
                      icon: Icons.vibration_rounded,
                      label: 'Vibration',
                      value: _settings.vibrationEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setVibrationEnabled(value: v)),
                    _SwitchRow(
                      icon: Icons.notifications_rounded,
                      label: 'Push Notifications',
                      value: _settings.notificationsEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setNotificationsEnabled(value: v)),
                    _SelectRow(
                      icon: Icons.language_rounded,
                      label: 'Language',
                      value: _settings.language,
                      options: const ['English', 'Spanish', 'French', 'German', 'Japanese'],
                      onChanged: (v) => ref.read(settingsProvider.notifier).setLanguage(v)),
                  ]),
                  const SizedBox(height: 16),
                  _Section(title: 'PRIVACY', children: [
                    _SwitchRow(
                      icon: Icons.remove_red_eye_rounded,
                      label: 'Show Online Status',
                      value: _settings.showOnlineStatus,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setShowOnlineStatus(value: v)),
                    _SwitchRow(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      value: _settings.analyticsEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).setAnalyticsEnabled(value: v)),
                  ]),
                  const SizedBox(height: 16),
                  _Section(title: 'ACCOUNT', children: [
                    _ActionRow(icon: Icons.person_rounded, label: 'Edit Profile', onTap: () {}),
                    _ActionRow(icon: Icons.lock_outline,   label: 'Change Password', onTap: () {}),
                    _ActionRow(icon: Icons.bug_report_rounded, label: 'Send Feedback', onTap: () {}),
                    _ActionRow(icon: Icons.info_outline,   label: 'About WildDeck v1.0.0', onTap: () {}),
                  ]),
                  const SizedBox(height: 16),
                  // Danger zone
                  _Section(title: 'DANGER ZONE', children: [
                    _ActionRow(
                      icon: Icons.logout_rounded,
                      label: 'Log Out',
                      color: WildDeckTheme.error,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: WildDeckTheme.navySurface,
                            title: const Text('Log Out', style: TextStyle(color: Colors.white)),
                            content: const Text('Are you sure you want to log out?',
                              style: TextStyle(color: WildDeckTheme.textSecond)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true),
                                child: const Text('Log Out',
                                  style: TextStyle(color: WildDeckTheme.error))),
                            ],
                          ),
                        );
                        if (confirm == true && mounted) context.go(WildRoutes.login);
                      }),
                  ]),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: const TextStyle(
          color: WildDeckTheme.textMuted, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.5))),
      Container(
        decoration: BoxDecoration(
          color: WildDeckTheme.navySurface,
          borderRadius: WildDeckTheme.radiusLarge,
          border: Border.all(color: WildDeckTheme.navyBorder)),
        child: Column(children: children.asMap().entries.map((e) {
          final isLast = e.key == children.length - 1;
          return Column(children: [
            e.value,
            if (!isLast) Divider(
              height: 1, color: WildDeckTheme.navyBorder, indent: 48, endIndent: 16),
          ]);
        }).toList()),
      ),
    ]);
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.label,
    required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: WildDeckTheme.textMuted, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
        Switch(
          value: value, onChanged: onChanged,
          activeThumbColor: WildDeckTheme.cardRed,
          activeTrackColor: WildDeckTheme.cardRed.withValues(alpha: 0.3)),
      ]),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.icon, required this.label,
    required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: WildDeckTheme.textMuted, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text('${(value * 100).round()}%',
            style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 12)),
        ]),
        Slider(
          value: value, onChanged: onChanged,
          activeColor: WildDeckTheme.cardRed,
          inactiveColor: WildDeckTheme.navyBorder),
      ]),
    );
  }
}

class _SelectRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _SelectRow({required this.icon, required this.label, required this.value,
    required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: WildDeckTheme.textMuted, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
        DropdownButton<String>(
          value: value,
          onChanged: (v) { if (v != null) onChanged(v); },
          dropdownColor: WildDeckTheme.navySurface,
          style: const TextStyle(color: WildDeckTheme.textSecond, fontSize: 13),
          underline: const SizedBox.shrink(),
          icon: const Icon(Icons.chevron_right_rounded, color: WildDeckTheme.textMuted, size: 18),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList()),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: WildDeckTheme.radiusMedium,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: c, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(color: c, fontSize: 14))),
          Icon(Icons.chevron_right_rounded, color: WildDeckTheme.textMuted, size: 18),
        ]),
      ),
    );
  }
}

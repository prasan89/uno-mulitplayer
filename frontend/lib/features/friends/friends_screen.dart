import 'package:flutter/material.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const _friends = [
    ('Blaze99',   'Online', true,  WildDeckTheme.success,     '42 wins'),
    ('CardShark', 'In Game', true, WildDeckTheme.cardBlue,    '71 wins'),
    ('Panda',     'Offline', false, WildDeckTheme.textMuted,  '18 wins'),
    ('Riku',      'Offline', false, WildDeckTheme.textMuted,  '99 wins'),
  ];

  static const _requests = [
    ('NovaStar', '2 mutual friends'),
    ('WildKing', '5 mutual friends'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            const WildDeckTopBar(title: 'Friends'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: WildDeckTheme.navySurface,
                borderRadius: WildDeckTheme.radiusMedium,
                border: Border.all(color: WildDeckTheme.navyBorder)),
              child: TabBar(
                controller: _tab,
                tabs: const [Tab(text: 'Online'), Tab(text: 'All'), Tab(text: 'Requests')],
                indicator: const BoxDecoration(
                  gradient: WildDeckTheme.primaryButtonGradient,
                  borderRadius: WildDeckTheme.radiusMedium),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: WildDeckTheme.textMuted,
                dividerColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: TabBarView(controller: _tab, children: [
              _FriendsList(friends: _friends.where((f) => f.$3).toList()),
              const _FriendsList(friends: _friends),
              const _RequestsList(requests: _requests),
            ])),
            _InviteBar(),
          ]),
        ),
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  final List<(String, String, bool, Color, String)> friends;
  const _FriendsList({required this.friends});

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return const Center(child: Text('No friends online right now.',
        style: TextStyle(color: WildDeckTheme.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: friends.length,
      itemBuilder: (context, i) {
        final (name, status, online, statusColor, wins) = friends[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: WildDeckTheme.navySurface,
            borderRadius: WildDeckTheme.radiusMedium,
            border: Border.all(color: WildDeckTheme.navyBorder)),
          child: Row(children: [
            Stack(children: [
              PlayerAvatar(displayName: name, size: 42),
              if (online) Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: statusColor, shape: BoxShape.circle,
                    border: Border.all(color: WildDeckTheme.navySurface, width: 2))),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w700)),
              Row(children: [
                Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
                const Text('  •  ', style: TextStyle(color: WildDeckTheme.textDisabled)),
                Text(wins, style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 12)),
              ]),
            ])),
            if (online && status == 'In Game')
              _SmallButton(label: 'Watch', color: WildDeckTheme.cardBlue, onTap: () {})
            else if (online)
              _SmallButton(label: 'Invite', color: WildDeckTheme.cardGreen, onTap: () {}),
          ]),
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  final List<(String, String)> requests;
  const _RequestsList({required this.requests});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final (name, mutual) = requests[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: WildDeckTheme.navySurface,
            borderRadius: WildDeckTheme.radiusMedium,
            border: Border.all(color: WildDeckTheme.navyBorder)),
          child: Row(children: [
            PlayerAvatar(displayName: name, size: 42),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 15,
                fontWeight: FontWeight.w700)),
              Text(mutual, style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 12)),
            ])),
            _SmallButton(label: 'Accept', color: WildDeckTheme.success, onTap: () {}),
            const SizedBox(width: 8),
            _SmallButton(label: 'Decline', color: WildDeckTheme.error, onTap: () {}),
          ]),
        );
      },
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SmallButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4))),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))),
    );
  }
}

class _InviteBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SecondaryButton(
        label: 'Invite Friends  •  Share Room Code',
        icon: Icons.share_rounded,
        onPressed: () {},
      ),
    );
  }
}

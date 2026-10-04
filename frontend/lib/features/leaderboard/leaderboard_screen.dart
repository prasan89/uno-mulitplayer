import 'package:flutter/material.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
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

  static const _global = [
    ('CardKing',   1420, 312, WildDeckTheme.cardRed,  false),
    ('WildAce',    1380, 290, WildDeckTheme.gold,      true),
    ('BlazeStar',  1350, 278, WildDeckTheme.cardBlue, false),
    ('NovaDeck',   1310, 265, WildDeckTheme.cardGreen, false),
    ('DeckMaster', 1280, 250, WildDeckTheme.cardWild,  false),
    ('QuickFire',  1220, 238, WildDeckTheme.cardRed,   false),
    ('Riku',       1190, 221, WildDeckTheme.gold,      false),
    ('Panda99',    1150, 210, WildDeckTheme.cardBlue,  false),
  ];

  static const _friends = [
    ('Blaze99',   1380, 155, WildDeckTheme.cardRed,   false),
    ('WildAce',   1350, 142, WildDeckTheme.gold,       true),
    ('CardShark', 1290, 130, WildDeckTheme.cardBlue,  false),
    ('Riku',      1210, 99,  WildDeckTheme.cardGreen, false),
  ];

  static const _season = [
    ('CardKing',   8420, 312, WildDeckTheme.cardRed,  false),
    ('WildAce',    7860, 290, WildDeckTheme.gold,      true),
    ('BlazeStar',  7450, 278, WildDeckTheme.cardBlue, false),
    ('NovaDeck',   6910, 265, WildDeckTheme.cardGreen, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            const WildDeckTopBar(title: 'Leaderboard'),
            // Top 3 podium for global
            _Podium(leaders: _global.take(3).toList()),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: WildDeckTheme.navySurface,
                borderRadius: WildDeckTheme.radiusMedium,
                border: Border.all(color: WildDeckTheme.navyBorder)),
              child: TabBar(
                controller: _tab,
                tabs: const [Tab(text: 'GLOBAL'), Tab(text: 'FRIENDS'), Tab(text: 'SEASON')],
                indicator: BoxDecoration(
                  gradient: WildDeckTheme.primaryButtonGradient,
                  borderRadius: WildDeckTheme.radiusMedium),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: WildDeckTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: TabBarView(controller: _tab, children: [
              _LeaderList(entries: _global),
              _LeaderList(entries: _friends),
              _LeaderList(entries: _season),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  final List<(String, int, int, Color, bool)> leaders;
  const _Podium({required this.leaders});

  @override
  Widget build(BuildContext context) {
    if (leaders.length < 3) return const SizedBox(height: 80);
    final (n1, s1, _, c1, me1) = leaders[0];
    final (n2, s2, __, c2, me2) = leaders[1];
    final (n3, s3, ___, c3, me3) = leaders[2];

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // 2nd
        Expanded(child: _PodiumSlot(name: n2, score: s2, rank: 2, height: 80, color: c2, isMe: me2)),
        const SizedBox(width: 8),
        // 1st
        Expanded(child: _PodiumSlot(name: n1, score: s1, rank: 1, height: 110, color: c1, isMe: me1)),
        const SizedBox(width: 8),
        // 3rd
        Expanded(child: _PodiumSlot(name: n3, score: s3, rank: 3, height: 64, color: c3, isMe: me3)),
      ]),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final String name;
  final int score, rank, height;
  final Color color;
  final bool isMe;
  const _PodiumSlot({required this.name, required this.score, required this.rank,
    required this.height, required this.color, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      PlayerAvatar(displayName: name, size: 34, isCurrentTurn: rank == 1 || isMe),
      const SizedBox(height: 4),
      Text(name, style: const TextStyle(color: Colors.white, fontSize: 10,
        fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Container(
        height: height.toDouble(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.3)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
        child: Center(child: Text('#$rank', style: const TextStyle(
          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
      ),
    ]);
  }
}

class _LeaderList extends StatelessWidget {
  final List<(String, int, int, Color, bool)> entries;
  const _LeaderList({required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final (name, score, wins, color, isMe) = entries[i];
        final rank = i + 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? WildDeckTheme.gold.withValues(alpha: 0.06) : WildDeckTheme.navySurface,
            borderRadius: WildDeckTheme.radiusMedium,
            border: Border.all(
              color: isMe ? WildDeckTheme.gold.withValues(alpha: 0.3) : WildDeckTheme.navyBorder)),
          child: Row(children: [
            SizedBox(
              width: 28,
              child: Text('#$rank', style: TextStyle(
                color: rank <= 3 ? WildDeckTheme.gold : WildDeckTheme.textMuted,
                fontSize: 13, fontWeight: FontWeight.w800))),
            PlayerAvatar(displayName: name, size: 36, isCurrentTurn: isMe),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isMe ? 'You ($name)' : name, style: TextStyle(
                color: isMe ? WildDeckTheme.gold : Colors.white,
                fontSize: 14, fontWeight: FontWeight.w700)),
              Text('$wins wins', style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 11)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$score', style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              const Text('pts', style: TextStyle(color: WildDeckTheme.textMuted, fontSize: 10)),
            ]),
          ]),
        );
      },
    );
  }
}

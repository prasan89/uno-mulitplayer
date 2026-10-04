import 'package:flutter/material.dart';
import 'package:wilddeck/core/services/mock_services.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen>
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

  static List<MissionData> get _weekly => [
    const MissionData(id: 'w1', title: 'Win 10 matches',
      description: 'Win any 10 games this week', progress: 4, goal: 10,
      coinReward: 500, xpReward: 200, type: MissionType.weekly),
    const MissionData(id: 'w2', title: 'Play 50 cards',
      description: 'Play a total of 50 cards', progress: 23, goal: 50,
      coinReward: 300, xpReward: 120, type: MissionType.weekly),
  ];

  static List<MissionData> get _achievements => [
    const MissionData(id: 'a1', title: 'First Steps',
      description: 'Play your first match', progress: 1, goal: 1,
      coinReward: 100, xpReward: 50, type: MissionType.achievement),
    const MissionData(id: 'a2', title: 'Wild Mastery',
      description: 'Play 50 wild cards total', progress: 32, goal: 50,
      coinReward: 1000, xpReward: 400, type: MissionType.achievement),
    const MissionData(id: 'a3', title: 'Unstoppable',
      description: 'Win 100 matches', progress: 42, goal: 100,
      coinReward: 2000, xpReward: 800, type: MissionType.achievement),
  ];

  @override
  Widget build(BuildContext context) {
    final daily = MockData.dailyMissions;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            const WildDeckTopBar(title: 'Missions'),
            // XP summary
            _MissionsSummary(daily: daily),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: WildDeckTheme.navySurface,
                borderRadius: WildDeckTheme.radiusMedium,
                border: Border.all(color: WildDeckTheme.navyBorder)),
              child: TabBar(
                controller: _tab,
                tabs: const [Tab(text: 'DAILY'), Tab(text: 'WEEKLY'), Tab(text: 'ACHIEVEMENTS')],
                indicator: const BoxDecoration(
                  gradient: WildDeckTheme.primaryButtonGradient,
                  borderRadius: WildDeckTheme.radiusMedium),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: WildDeckTheme.textMuted,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                dividerColor: Colors.transparent,
              ),
            ),
            Expanded(child: TabBarView(controller: _tab, children: [
              _MissionList(missions: daily),
              _MissionList(missions: _weekly),
              _MissionList(missions: _achievements),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _MissionsSummary extends StatelessWidget {
  final List<MissionData> daily;
  const _MissionsSummary({required this.daily});

  @override
  Widget build(BuildContext context) {
    final done = daily.where((m) => m.progress >= m.goal).length;
    final total = daily.length;
    final coins = daily.where((m) => m.progress >= m.goal).fold(0, (acc, m) => acc + m.coinReward);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusLarge,
        border: Border.all(color: WildDeckTheme.navyBorder)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily Progress', style: TextStyle(color: Colors.white, fontSize: 14,
            fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('$done / $total missions completed',
            style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 12)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [
            const Icon(Icons.monetization_on, color: WildDeckTheme.gold, size: 14),
            Text(' $coins / ${daily.fold(0, (a, m) => a + m.coinReward)}',
              style: const TextStyle(color: WildDeckTheme.gold, fontSize: 13,
                fontWeight: FontWeight.w700)),
          ]),
          const Text('Resets in 14h 22m',
            style: TextStyle(color: WildDeckTheme.textMuted, fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _MissionList extends StatelessWidget {
  final List<MissionData> missions;
  const _MissionList({required this.missions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: missions.length,
      itemBuilder: (context, i) => _MissionCard(mission: missions[i]),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final MissionData mission;
  const _MissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final done = mission.progress >= mission.goal;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusLarge,
        border: Border.all(
          color: done ? WildDeckTheme.success.withValues(alpha: 0.3) : WildDeckTheme.navyBorder)),
      child: Column(children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: done ? WildDeckTheme.success.withValues(alpha: 0.12) : WildDeckTheme.navyCard,
              shape: BoxShape.circle),
            child: Icon(
              done ? Icons.check_circle_outline : Icons.assignment_rounded,
              color: done ? WildDeckTheme.success : WildDeckTheme.textMuted, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(mission.title, style: const TextStyle(color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w700)),
            Text(mission.description,
              style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              const Icon(Icons.monetization_on, color: WildDeckTheme.gold, size: 12),
              Text(' ${mission.coinReward}', style: const TextStyle(
                color: WildDeckTheme.gold, fontSize: 12, fontWeight: FontWeight.w700)),
            ]),
            Row(children: [
              const Icon(Icons.star, color: WildDeckTheme.cardBlue, size: 12),
              Text(' ${mission.xpReward} XP', style: const TextStyle(
                color: WildDeckTheme.cardBlue, fontSize: 11)),
            ]),
          ]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: XPBar(
            xp: mission.progress, xpToNext: mission.goal)),
          const SizedBox(width: 10),
          Text('${mission.progress}/${mission.goal}',
            style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 11)),
        ]),
        if (done) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: WildDeckTheme.success.withValues(alpha: 0.08),
              borderRadius: WildDeckTheme.radiusSmall),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check, color: WildDeckTheme.success, size: 14),
              SizedBox(width: 6),
              Text('Completed — rewards collected', style: TextStyle(
                color: WildDeckTheme.success, fontSize: 11, fontWeight: FontWeight.w600)),
            ])),
        ],
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:wilddeck/core/services/mock_services.dart';
import 'package:wilddeck/shared/theme/wilddeck_theme.dart';
import 'package:wilddeck/shared/widgets/wilddeck_components.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _coins = 2400;
  int _gems = 45;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const _cardBacks = [
    ('Classic',   WildDeckTheme.navyCard,    0,    true,  0),
    ('Fire',      WildDeckTheme.cardRed,     800,  false, 0),
    ('Ocean',     WildDeckTheme.cardBlue,    800,  false, 0),
    ('Forest',    WildDeckTheme.cardGreen,   800,  false, 0),
    ('Galaxy',    WildDeckTheme.cardWild,    1200, false, 0),
    ('Gold',      WildDeckTheme.gold,        1500, false, 5),
  ];

  static const _avatars = [
    ('Fox',      WildDeckTheme.cardRed,    600,  false, 0),
    ('Shark',    WildDeckTheme.cardBlue,   600,  false, 0),
    ('Dragon',   WildDeckTheme.cardWild,   1200, false, 3),
    ('Panda',    WildDeckTheme.cardGreen,  800,  false, 0),
  ];

  static const _tables = [
    ('Wood',    WildDeckTheme.navyCard,   0,    true,  0),
    ('Marble',  WildDeckTheme.platinum,  1000, false, 0),
    ('Neon',    WildDeckTheme.cardWild,  1500, false, 4),
  ];

  static const _emotes = [
    ('Nice!',  Icons.thumb_up_rounded,   WildDeckTheme.cardGreen,  200,  false),
    ('Oof',    Icons.sentiment_dissatisfied, WildDeckTheme.cardYellow, 200, false),
    ('Fire!',  Icons.local_fire_department, WildDeckTheme.cardRed, 300, false),
    ('GG',     Icons.handshake_rounded, WildDeckTheme.cardBlue, 200, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(children: [
            WildDeckTopBar(title: 'Shop'),
            // Balance row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                CoinBadge(amount: _coins),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [WildDeckTheme.cardWild, Color(0xFF4527A0)]),
                    borderRadius: WildDeckTheme.radiusSmall),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.diamond, color: Colors.white, size: 13),
                    const SizedBox(width: 4),
                    Text('$_gems', style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.w800)),
                  ])),
              ]),
            ),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: WildDeckTheme.navySurface,
                borderRadius: WildDeckTheme.radiusMedium,
                border: Border.all(color: WildDeckTheme.navyBorder)),
              child: TabBar(
                controller: _tab,
                tabs: const [Tab(text: 'CARDS'), Tab(text: 'AVATARS'),
                  Tab(text: 'TABLES'), Tab(text: 'EMOTES')],
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
              _ItemGrid(items: _cardBacks.map((e) => _ShopItem(
                name: e.$1, color: e.$2, price: e.$3, owned: e.$4,
                gemPrice: e.$5, coins: _coins, gems: _gems)).toList()),
              _ItemGrid(items: _avatars.map((e) => _ShopItem(
                name: e.$1, color: e.$2, price: e.$3, owned: e.$4,
                gemPrice: e.$5, coins: _coins, gems: _gems)).toList()),
              _ItemGrid(items: _tables.map((e) => _ShopItem(
                name: e.$1, color: e.$2, price: e.$3, owned: e.$4,
                gemPrice: e.$5, coins: _coins, gems: _gems)).toList()),
              _EmoteList(emotes: _emotes.map((e) => _EmoteShopItem(
                label: e.$1, icon: e.$2, color: e.$3,
                price: e.$4, owned: e.$5)).toList()),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _ShopItem {
  final String name;
  final Color color;
  final int price;
  final bool owned;
  final int gemPrice;
  final int coins;
  final int gems;
  const _ShopItem({
    required this.name, required this.color, required this.price,
    required this.owned, required this.gemPrice,
    required this.coins, required this.gems,
  });
}

class _EmoteShopItem {
  final String label;
  final IconData icon;
  final Color color;
  final int price;
  final bool owned;
  const _EmoteShopItem({required this.label, required this.icon, required this.color,
    required this.price, required this.owned});
}

class _ItemGrid extends StatelessWidget {
  final List<_ShopItem> items;
  const _ItemGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.85,
        crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (context, i) => _ItemCard(item: items[i]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final _ShopItem item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final canAfford = item.owned || (item.gemPrice > 0 ? item.gems >= item.gemPrice : item.coins >= item.price);
    return Container(
      decoration: BoxDecoration(
        color: WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusLarge,
        border: Border.all(color: item.owned ? item.color.withValues(alpha: 0.4) : WildDeckTheme.navyBorder)),
      child: Column(children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: WildDeckTheme.cardGradient(item.color),
              borderRadius: WildDeckTheme.radiusMedium),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(children: [
            Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 13,
              fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (item.owned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: WildDeckTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4)),
                child: const Text('OWNED', style: TextStyle(
                  color: WildDeckTheme.success, fontSize: 9, fontWeight: FontWeight.w800)))
            else
              GestureDetector(
                onTap: canAfford ? () {} : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: canAfford ? WildDeckTheme.gold.withValues(alpha: 0.15)
                                     : WildDeckTheme.navyCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: canAfford ? WildDeckTheme.gold.withValues(alpha: 0.4)
                                       : WildDeckTheme.navyBorder)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(item.gemPrice > 0 ? Icons.diamond : Icons.monetization_on,
                      color: canAfford ? WildDeckTheme.gold : WildDeckTheme.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text('${item.gemPrice > 0 ? item.gemPrice : item.price}',
                      style: TextStyle(
                        color: canAfford ? WildDeckTheme.gold : WildDeckTheme.textMuted,
                        fontSize: 12, fontWeight: FontWeight.w800)),
                  ])),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _EmoteList extends StatelessWidget {
  final List<_EmoteShopItem> emotes;
  const _EmoteList({required this.emotes});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: emotes.length,
      itemBuilder: (context, i) {
        final e = emotes[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: WildDeckTheme.navySurface,
            borderRadius: WildDeckTheme.radiusMedium,
            border: Border.all(color: WildDeckTheme.navyBorder)),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: e.color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(e.icon, color: e.color, size: 24)),
            const SizedBox(width: 14),
            Expanded(child: Text(e.label, style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
            if (e.owned)
              const Text('OWNED', style: TextStyle(
                color: WildDeckTheme.success, fontSize: 10, fontWeight: FontWeight.w800))
            else
              Row(children: [
                const Icon(Icons.monetization_on, color: WildDeckTheme.gold, size: 14),
                const SizedBox(width: 4),
                Text('${e.price}', style: const TextStyle(
                  color: WildDeckTheme.gold, fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
          ]),
        );
      },
    );
  }
}

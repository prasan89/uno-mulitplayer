import 'package:flutter/material.dart';
import 'package:wilddeck/features/game/widgets/card_widget.dart';

class PlayerHand extends StatelessWidget {
  final List<WildCard> cards;
  final Set<String> playableCardIds;
  final String? selectedCardId;
  final void Function(WildCard card) onCardTap;

  const PlayerHand({
    super.key,
    required this.cards,
    required this.playableCardIds,
    this.selectedCardId,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(
          top: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: cards.isEmpty
          ? const Center(
              child: Text(
                'No cards in hand',
                style: TextStyle(color: Colors.white38),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final isPlayable = playableCardIds.contains(card.id);
                final isSelected = selectedCardId == card.id;

                return Padding(
                  padding: EdgeInsets.only(
                    right: index < cards.length - 1 ? 8 : 0,
                    top: isSelected ? 0 : 10,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    transform: isSelected
                        ? Matrix4.translationValues(0.0, -10.0, 0)
                        : Matrix4.identity(),
                    child: CardWidget(
                      card: card,
                      isPlayable: isPlayable,
                      isSelected: isSelected,
                      onTap: isPlayable ? () => onCardTap(card) : null,
                      width: 65,
                      height: 92,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';

class PlayerScore {
  final String name;
  final int score;
  final int eloChange;
  final bool isCurrentPlayer;

  const PlayerScore({
    required this.name,
    required this.score,
    required this.eloChange,
    this.isCurrentPlayer = false,
  });
}

class GameOverDialog extends StatelessWidget {
  final String winnerName;
  final List<PlayerScore> playerScores;
  final VoidCallback? onPlayAgain;
  final VoidCallback? onBackToLobby;

  const GameOverDialog({
    required this.winnerName, required this.playerScores, super.key,
    this.onPlayAgain,
    this.onBackToLobby,
  });

  static Future<void> show({
    required BuildContext context,
    required String winnerName,
    required List<PlayerScore> playerScores,
    VoidCallback? onPlayAgain,
    VoidCallback? onBackToLobby,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(
        winnerName: winnerName,
        playerScores: playerScores,
        onPlayAgain: onPlayAgain,
        onBackToLobby: onBackToLobby,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            '🎉',
            style: TextStyle(fontSize: 40),
            textScaler: TextScaler.noScaling,
          ),
          const SizedBox(height: 8),
          const Text(
            'Game Over!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Winner: ',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: winnerName,
                  style: const TextStyle(
                    color: Color(0xFFF9A825),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          const Text(
            'Scores',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...playerScores.map((ps) => _ScoreRow(score: ps)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBackToLobby,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Lobby',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onPlayAgain,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final PlayerScore score;

  const _ScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final eloPositive = score.eloChange >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: score.isCurrentPlayer
            ? const Color(0xFFE53935).withValues(alpha: 0.1)
            : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: score.isCurrentPlayer
              ? const Color(0xFFE53935).withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _getAvatarColor(score.name),
                  child: Text(
                    score.name.isNotEmpty ? score.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    score.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: score.isCurrentPlayer
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 13,
                      fontWeight: score.isCurrentPlayer
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${score.score} pts',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: eloPositive
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
                  : const Color(0xFFE53935).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${eloPositive ? '+' : ''}${score.eloChange} ELO',
              style: TextStyle(
                color: eloPositive
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE57373),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFF1565C0),
      const Color(0xFF2E7D32),
      const Color(0xFFF9A825),
      const Color(0xFF6A1B9A),
    ];
    final index =
        name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;
    return colors[index];
  }
}

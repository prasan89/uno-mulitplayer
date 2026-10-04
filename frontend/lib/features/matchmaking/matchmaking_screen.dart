import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/wilddeck_providers.dart';
import '../../core/router/wilddeck_router.dart';
import '../../core/services/wilddeck_services.dart';
import '../../core/services/mock_services.dart';
import '../../shared/theme/wilddeck_theme.dart';
import '../../shared/widgets/wilddeck_components.dart';

/// Matchmaking screen — shows animated slot fill as players join.
/// Uses IMatchmakingService; mock implementation used in M1.
class MatchmakingScreen extends ConsumerStatefulWidget {
  final String gameMode;
  const MatchmakingScreen({super.key, required this.gameMode});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  final MockMatchmakingService _service = MockMatchmakingService();
  StreamSubscription<MatchmakingState>? _sub;
  MatchmakingState _state = const MatchmakingState(
    status: MatchmakingStatus.searching,
    slots: [],
  );

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _startSearch();
  }

  void _startSearch() {
    _sub?.cancel();
    _sub = _service.searchForMatch(
      gameMode: widget.gameMode,
      maxPlayers: 4,
      fillWithBots: true,
    ).listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
      if (state.status == MatchmakingStatus.found && state.matchId != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            context.pushReplacement(
              '${WildRoutes.gameLobby}?gameId=${state.matchId}',
            );
          }
        });
      }
    });
  }

  Future<void> _cancel() async {
    await _service.cancelSearch();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _pulseCtrl.dispose();
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }

  String get _modeLabel {
    switch (widget.gameMode) {
      case 'quick':   return 'Quick Match';
      case 'private': return 'Private Room';
      default:        return 'Classic Match';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFound = _state.status == MatchmakingStatus.found;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: WildDeckTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              WildDeckTopBar(title: 'Finding Players'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      // Animated search indicator
                      ScaleTransition(
                        scale: isFound ? const AlwaysStoppedAnimation(1.0) : _pulse,
                        child: _SearchIndicator(
                          spinCtrl: _spinCtrl,
                          isFound: isFound,
                          filled: _state.filledSlots,
                          total: _state.totalSlots,
                        ),
                      ),
                      const SizedBox(height: 24),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isFound
                            ? const Text('Match Found!', key: ValueKey('found'),
                                style: TextStyle(color: WildDeckTheme.success, fontSize: 22,
                                    fontWeight: FontWeight.w800))
                            : Text('Finding Players…', key: const ValueKey('searching'),
                                style: const TextStyle(color: Colors.white, fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _state.status != MatchmakingStatus.found
                            ? '${_state.filledSlots} / ${_state.totalSlots.clamp(1, 99)} players found'
                            : 'Starting game…',
                        style: const TextStyle(color: WildDeckTheme.textSecond, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatElapsed(_state.elapsedSeconds),
                        style: const TextStyle(color: WildDeckTheme.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 32),
                      // Player slots
                      if (_state.slots.isNotEmpty)
                        _SlotsPanel(slots: _state.slots, gameMode: _modeLabel),
                      const Spacer(),
                      if (widget.gameMode == 'classic' || widget.gameMode == 'quick')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.info_outline, color: WildDeckTheme.textMuted, size: 13),
                              SizedBox(width: 6),
                              Text('Real players preferred • AI fills if needed',
                                style: TextStyle(color: WildDeckTheme.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                      if (!isFound)
                        SecondaryButton(
                          label: 'Cancel',
                          icon: Icons.close,
                          onPressed: _cancel,
                          borderColor: WildDeckTheme.error.withOpacity(0.5),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatElapsed(int s) {
    if (s < 60) return '${s}s';
    return '${s ~/ 60}m ${s % 60}s';
  }
}

class _SearchIndicator extends StatelessWidget {
  final AnimationController spinCtrl;
  final bool isFound;
  final int filled;
  final int total;

  const _SearchIndicator({
    required this.spinCtrl,
    required this.isFound,
    required this.filled,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110, height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isFound)
            RotationTransition(
              turns: spinCtrl,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      WildDeckTheme.cardRed.withOpacity(0),
                      WildDeckTheme.cardRed,
                      WildDeckTheme.gold,
                    ],
                  ),
                ),
              ),
            ),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFound ? WildDeckTheme.success.withOpacity(0.15) : WildDeckTheme.navyMid,
              border: Border.all(
                color: isFound ? WildDeckTheme.success : WildDeckTheme.navyBorder,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFound ? Icons.check_circle_outline : Icons.search_rounded,
                  color: isFound ? WildDeckTheme.success : WildDeckTheme.gold,
                  size: 30,
                ),
                const SizedBox(height: 4),
                if (total > 0)
                  Text('$filled/$total', style: TextStyle(
                    color: isFound ? WildDeckTheme.success : Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w800,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotsPanel extends StatelessWidget {
  final List<MatchmakingSlot> slots;
  final String gameMode;

  const _SlotsPanel({required this.slots, required this.gameMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WildDeckTheme.navySurface,
        borderRadius: WildDeckTheme.radiusLarge,
        border: Border.all(color: WildDeckTheme.navyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_rounded, color: WildDeckTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(gameMode, style: const TextStyle(
                color: WildDeckTheme.textMuted, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.2,
              )),
            ],
          ),
          const SizedBox(height: 12),
          ...slots.map((slot) => _SlotRow(slot: slot)),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final MatchmakingSlot slot;
  const _SlotRow({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: slot.isOccupied
                ? PlayerAvatar(
                    displayName: slot.playerName ?? '?',
                    size: 36,
                    isBot: slot.isBot,
                  )
                : Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: WildDeckTheme.navyCard,
                      border: Border.all(
                        color: WildDeckTheme.navyBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: WildDeckTheme.textDisabled, size: 18),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.isCurrentPlayer ? 'You'
                    : slot.isOccupied ? (slot.playerName ?? 'Player')
                    : 'Searching…',
                  style: TextStyle(
                    color: slot.isCurrentPlayer ? WildDeckTheme.gold
                        : slot.isOccupied ? Colors.white
                        : WildDeckTheme.textMuted,
                    fontSize: 14,
                    fontWeight: slot.isCurrentPlayer ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                if (slot.isBot)
                  const Text('AI Player', style: TextStyle(
                    color: WildDeckTheme.textMuted, fontSize: 11,
                  )),
              ],
            ),
          ),
          if (slot.isOccupied)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: WildDeckTheme.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('READY', style: TextStyle(
                color: WildDeckTheme.success, fontSize: 9,
                fontWeight: FontWeight.w800, letterSpacing: 1,
              )),
            )
          else
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: WildDeckTheme.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

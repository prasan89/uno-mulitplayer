import 'package:flutter/material.dart';
import '../widgets/room_code_entry.dart';

enum _LobbyMode { idle, quickMatch, createPrivate, joinPrivate }

class LobbyScreen extends StatefulWidget {
  final void Function()? onQuickMatch;
  final void Function(String roomCode)? onJoinPrivateGame;
  final void Function()? onCreatePrivateGame;

  /// Demo room code shown when the user creates a private game.
  final String? createdRoomCode;

  const LobbyScreen({
    super.key,
    this.onQuickMatch,
    this.onJoinPrivateGame,
    this.onCreatePrivateGame,
    this.createdRoomCode,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  _LobbyMode _mode = _LobbyMode.idle;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _setMode(_LobbyMode mode) {
    setState(() => _mode = mode);
    if (mode == _LobbyMode.createPrivate || mode == _LobbyMode.joinPrivate) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 48),
              _buildQuickMatchSection(),
              const SizedBox(height: 24),
              const _OrDivider(),
              const SizedBox(height: 24),
              _buildPrivateGameSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE53935),
                Color(0xFFB71C1C),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'WD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Multiplayer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Play with friends or random opponents',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMatchSection() {
    final isActive = _mode == _LobbyMode.quickMatch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'QUICK MATCH',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE53935),
                Color(0xFFC62828),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935)
                    .withOpacity(isActive ? 0.5 : 0.3),
                blurRadius: isActive ? 20 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                _setMode(_LobbyMode.quickMatch);
                widget.onQuickMatch?.call();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 18, horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Match',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Match with random players',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateGameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'PRIVATE GAME',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        // Create game button
        _PrivateOptionTile(
          icon: Icons.add_circle_outline,
          title: 'Create Game',
          subtitle: 'Get a room code to share',
          isSelected: _mode == _LobbyMode.createPrivate,
          onTap: () {
            if (_mode == _LobbyMode.createPrivate) {
              _setMode(_LobbyMode.idle);
            } else {
              _setMode(_LobbyMode.createPrivate);
              widget.onCreatePrivateGame?.call();
            }
          },
        ),
        const SizedBox(height: 10),
        // Join game button
        _PrivateOptionTile(
          icon: Icons.login,
          title: 'Join Game',
          subtitle: 'Enter a 6-character room code',
          isSelected: _mode == _LobbyMode.joinPrivate,
          onTap: () {
            if (_mode == _LobbyMode.joinPrivate) {
              _setMode(_LobbyMode.idle);
            } else {
              _setMode(_LobbyMode.joinPrivate);
            }
          },
        ),
        // Expanded panel for room code
        SizeTransition(
          sizeFactor: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildRoomCodePanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCodePanel() {
    if (_mode == _LobbyMode.createPrivate) {
      return RoomCodeEntry(
        roomCode: widget.createdRoomCode ?? 'ABC123',
      );
    }
    if (_mode == _LobbyMode.joinPrivate) {
      return RoomCodeEntry(
        onCodeSubmitted: widget.onJoinPrivateGame,
      );
    }
    return const SizedBox.shrink();
  }
}

class _PrivateOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PrivateOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFE53935).withOpacity(0.08)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFE53935)
              : Colors.white12,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? const Color(0xFFE53935)
                      : Colors.white38,
                  size: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isSelected ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: isSelected
                        ? const Color(0xFFE53935)
                        : Colors.white24,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }
}

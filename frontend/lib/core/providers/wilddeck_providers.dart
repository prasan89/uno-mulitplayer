import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wilddeck_services.dart';
import '../services/mock_services.dart';

// ─── Service Providers ────────────────────────────────────────────────────────
// Swap mock implementations for real ones in future milestones.

final playerServiceProvider = Provider<IPlayerService>(
  (_) => MockPlayerService(),
);

final matchmakingServiceProvider = Provider<IMatchmakingService>(
  (_) => MockMatchmakingService(),
);

final walletServiceProvider = Provider<IWalletService>(
  (_) => MockWalletService(),
);

// ─── Auth / Player State ──────────────────────────────────────────────────────

class PlayerNotifier extends AsyncNotifier<WildDeckPlayer?> {
  @override
  Future<WildDeckPlayer?> build() async {
    return ref.read(playerServiceProvider).getCurrentPlayer();
  }

  Future<void> signInAsGuest(String displayName) async {
    state = const AsyncLoading();
    state = AsyncData(
      await ref.read(playerServiceProvider).signInAsGuest(displayName),
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(playerServiceProvider).signInWithEmail(email, password),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = const AsyncLoading();
    try {
      state = AsyncData(
        await ref.read(playerServiceProvider).register(email, password, displayName),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    await ref.read(playerServiceProvider).signOut();
    state = const AsyncData(null);
  }
}

final playerProvider = AsyncNotifierProvider<PlayerNotifier, WildDeckPlayer?>(
  PlayerNotifier.new,
);

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(playerProvider).valueOrNull != null;
});

final currentPlayerProvider = Provider<WildDeckPlayer?>((ref) {
  return ref.watch(playerProvider).valueOrNull;
});

// ─── Game State ───────────────────────────────────────────────────────────────

class GameNotifier extends AutoDisposeNotifier<WildGameState?> {
  @override
  WildGameState? build() => null;

  void loadMockGame(WildGameState mockState) {
    state = mockState;
  }

  Future<void> drawCard() async {
    final s = state;
    if (s == null || !s.isMyTurn) return;
    final drawn = WildGameCard(
      id: 'drawn_${DateTime.now().millisecondsSinceEpoch}',
      color: WildCardColor.values[DateTime.now().millisecond % (WildCardColor.values.length - 1)],
      type: WildCardType.number,
      number: DateTime.now().second % 10,
    );
    state = WildGameState(
      gameId: s.gameId, phase: s.phase, mode: s.mode,
      currentPlayerId: s.currentPlayerId, players: s.players,
      myHand: [...s.myHand, drawn], topCard: s.topCard,
      activeColor: s.activeColor, drawPileCount: s.drawPileCount - 1,
      discardCount: s.discardCount, isMyTurn: false,
      winnerId: s.winnerId,
    );
  }

  Future<void> playCard(String cardId, {WildCardColor? chosenColor}) async {
    final s = state;
    if (s == null) return;
    final card = s.myHand.firstWhere((c) => c.id == cardId, orElse: () => s.myHand.first);
    final newHand = s.myHand.where((c) => c.id != cardId).toList();
    state = WildGameState(
      gameId: s.gameId, phase: newHand.isEmpty ? GamePhase.finished : s.phase,
      mode: s.mode, currentPlayerId: s.currentPlayerId, players: s.players,
      myHand: newHand, topCard: card,
      activeColor: chosenColor ?? card.color,
      drawPileCount: s.drawPileCount, discardCount: s.discardCount + 1,
      isMyTurn: false, winnerId: newHand.isEmpty ? 'me' : s.winnerId,
    );
  }
}

final gameProvider = AutoDisposeNotifierProvider<GameNotifier, WildGameState?>(
  GameNotifier.new,
);

// ─── Settings State ───────────────────────────────────────────────────────────

class SettingsState {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool notificationsEnabled;
  final bool vibrationEnabled;
  final bool showOnlineStatus;
  final bool analyticsEnabled;
  final String language;
  final double sfxVolume;
  final double musicVolume;
  final double masterVolume;

  const SettingsState({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.notificationsEnabled = true,
    this.vibrationEnabled = true,
    this.showOnlineStatus = true,
    this.analyticsEnabled = true,
    this.language = 'English',
    this.sfxVolume = 0.8,
    this.musicVolume = 0.6,
    this.masterVolume = 0.8,
  });

  SettingsState copyWith({
    bool? soundEnabled, bool? musicEnabled, bool? notificationsEnabled,
    bool? vibrationEnabled, bool? showOnlineStatus, bool? analyticsEnabled,
    String? language, double? sfxVolume, double? musicVolume, double? masterVolume,
  }) => SettingsState(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
    analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    language: language ?? this.language,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    musicVolume: musicVolume ?? this.musicVolume,
    masterVolume: masterVolume ?? this.masterVolume,
  );
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void setSoundEnabled(bool v)         => state = state.copyWith(soundEnabled: v);
  void setMusicEnabled(bool v)         => state = state.copyWith(musicEnabled: v);
  void setNotificationsEnabled(bool v) => state = state.copyWith(notificationsEnabled: v);
  void setVibrationEnabled(bool v)     => state = state.copyWith(vibrationEnabled: v);
  void setShowOnlineStatus(bool v)     => state = state.copyWith(showOnlineStatus: v);
  void setAnalyticsEnabled(bool v)     => state = state.copyWith(analyticsEnabled: v);
  void setMasterVolume(double v)       => state = state.copyWith(masterVolume: v);
  void setSfxVolume(double v)          => state = state.copyWith(sfxVolume: v);
  void setMusicVolume(double v)        => state = state.copyWith(musicVolume: v);
  void setLanguage(String lang)        => state = state.copyWith(language: lang);
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

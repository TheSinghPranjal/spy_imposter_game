import '../../features/imposter/domain/entities/player.dart';
import '../constants/game_constants.dart';

class PlayerValidation {
  const PlayerValidation._();

  static String? validateName(
    String raw, {
    required List<Player> existing,
    bool allowDuplicates = false,
    String? excludePlayerId,
  }) {
    final name = raw.trim();
    if (name.isEmpty) return "Name can't be empty.";
    if (name.length > GameConstants.maxNameLength) {
      return 'Keep names under ${GameConstants.maxNameLength} characters.';
    }
    if (!allowDuplicates) {
      final dup = existing.any(
        (p) =>
            p.id != excludePlayerId &&
            p.name.toLowerCase() == name.toLowerCase(),
      );
      if (dup) return "Two agents can't have the same name.";
    }
    return null;
  }

  static String? canAdd(List<Player> existing) {
    if (existing.length >= GameConstants.maxPlayers) {
      return 'Maximum ${GameConstants.maxPlayers} agents.';
    }
    return null;
  }

  static String? canContinue(List<Player> existing) {
    if (existing.length < GameConstants.minPlayers) {
      return 'Add at least ${GameConstants.minPlayers} agents to start.';
    }
    return null;
  }
}

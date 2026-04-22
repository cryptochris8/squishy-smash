import '../models/player_profile.dart';
import '../persistence.dart';
import 'pack_repository.dart';

class ProgressionRepository {
  ProgressionRepository(this._persistence, this._packs)
      : profile = _persistence.loadProfile();

  final Persistence _persistence;
  final PackRepository _packs;
  PlayerProfile profile;

  bool isUnlocked(String packId) => profile.unlockedPackIds.contains(packId);

  Future<bool> tryUnlock(String packId) async {
    final pack = _packs.byId(packId);
    if (pack == null || isUnlocked(packId)) return false;
    if (profile.coins < pack.unlockCost) return false;
    profile.coins -= pack.unlockCost;
    profile.unlockedPackIds.add(packId);
    await _persistence.saveProfile(profile);
    return true;
  }

  Future<void> awardCoins(int n) async {
    profile.coins += n;
    await _persistence.saveProfile(profile);
  }

  Future<void> recordRound({required int score, required int combo}) async {
    var dirty = false;
    if (score > profile.bestScore) {
      profile.bestScore = score;
      dirty = true;
    }
    if (combo > profile.bestCombo) {
      profile.bestCombo = combo;
      dirty = true;
    }
    if (dirty) await _persistence.saveProfile(profile);
  }

  /// Increment and persist [PlayerProfile.sessionCount]. Call at the
  /// start of each gameplay round, before the level_start analytics
  /// event fires, so `session_index` matches what the round logs.
  Future<void> noteSessionStart() async {
    profile.sessionCount += 1;
    await _persistence.saveProfile(profile);
  }
}

import 'models/economy_config.dart';

/// Compose the canonical claim-key for a `(packId, percent)` pair.
/// Using a function (instead of inlining the format string) means a
/// future format change is a one-file edit, and tests can verify the
/// same shape the production code uses.
String packMilestoneClaimKey({
  required String packId,
  required int percent,
}) =>
    '$packId:$percent';

/// Pure: which configured [milestones] has the player just crossed
/// for [packId] but not yet claimed?
///
/// Crossing is one-way (you reach 50%, you can't un-cross). Idempotent
/// against re-evaluation: repeated calls with the same inputs return
/// the same set, and once a key lands in [alreadyClaimedKeys] the
/// milestone never appears again.
///
/// Returns an empty list if [totalInPack] is 0 (avoid divide-by-zero
/// on a freshly-installed pack with no objects yet) or if [milestones]
/// is empty.
List<PackMilestone> evaluatePackMilestoneCrossings({
  required String packId,
  required int discoveredCount,
  required int totalInPack,
  required Set<String> alreadyClaimedKeys,
  required Iterable<PackMilestone> milestones,
}) {
  if (totalInPack <= 0) return const <PackMilestone>[];
  if (milestones.isEmpty) return const <PackMilestone>[];
  final percent = (100 * discoveredCount) ~/ totalInPack;
  return milestones.where((m) {
    if (percent < m.percent) return false;
    final key = packMilestoneClaimKey(packId: packId, percent: m.percent);
    return !alreadyClaimedKeys.contains(key);
  }).toList(growable: false);
}

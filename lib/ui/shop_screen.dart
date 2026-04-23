import 'package:flutter/material.dart';

import '../core/service_locator.dart';
import '../data/models/content_pack.dart';
import '../game/systems/arena_registry.dart';
import 'widgets/coin_badge.dart';
import 'widgets/pack_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final packs = ServiceLocator.packs.packs;
    final progression = ServiceLocator.progression;
    final standaloneArenas = ArenaRegistry.standalone.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SHOP', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: CoinBadge(coins: progression.profile.coins)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Object Packs'),
          const SizedBox(height: 8),
          for (final pack in packs) ...[
            PackCard(
              pack: pack,
              unlocked: progression.isUnlocked(pack.packId),
              onUnlock: progression.isUnlocked(pack.packId)
                  ? null
                  : () => _attemptUnlockPack(pack),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          const _SectionHeader('Arenas'),
          const SizedBox(height: 8),
          for (final theme in standaloneArenas) ...[
            _ArenaSkuCard(
              theme: theme,
              unlocked: progression.isArenaUnlocked(theme.key),
              onUnlock: progression.isArenaUnlocked(theme.key)
                  ? null
                  : () => _attemptUnlockArena(theme),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _attemptUnlockPack(ContentPack pack) async {
    final ok = await ServiceLocator.progression.tryUnlock(pack.packId);
    if (!mounted) return;
    setState(() {});
    final msg = ok
        ? 'Unlocked ${pack.displayName}!'
        : 'Need ${pack.unlockCost} coins (you have ${ServiceLocator.progression.profile.coins})';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _attemptUnlockArena(ArenaTheme theme) async {
    final ok = await ServiceLocator.progression.tryUnlockArena(theme.key);
    if (!mounted) return;
    setState(() {});
    final msg = ok
        ? 'Unlocked ${theme.displayName}! Set as active in Settings.'
        : 'Need ${theme.cost} coins (you have ${ServiceLocator.progression.profile.coins})';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Color(0xFFFFD36E),
        letterSpacing: 1.4,
      ),
    );
  }
}

/// Compact storefront card for a standalone arena SKU. Layout mirrors
/// PackCard so the shop reads consistently — gradient swatch from the
/// arena's calmColors, cost or checkmark on the right, unlock CTA when
/// locked.
class _ArenaSkuCard extends StatelessWidget {
  const _ArenaSkuCard({
    required this.theme,
    required this.unlocked,
    required this.onUnlock,
  });

  final ArenaTheme theme;
  final bool unlocked;
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final swatchTop = theme.calmColors.first;
    final swatchBottom = theme.calmColors.last;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            swatchTop.withValues(alpha: 0.35),
            swatchBottom.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: swatchTop, width: 1.4),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.calmColors,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  theme.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  unlocked ? 'Owned — switch in Settings' : 'Standalone arena',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle, color: Color(0xFFB6FF5C))
          else ...[
            Text(
              '${theme.cost}',
              style: const TextStyle(
                color: Color(0xFFFFD36E),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: swatchTop,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'UNLOCK',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

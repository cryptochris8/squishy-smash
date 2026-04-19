import 'package:flutter/material.dart';

import '../core/service_locator.dart';
import '../data/models/content_pack.dart';
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('PACKS', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: CoinBadge(coins: progression.profile.coins)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: packs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final pack = packs[i];
          final unlocked = progression.isUnlocked(pack.packId);
          return PackCard(
            pack: pack,
            unlocked: unlocked,
            onUnlock: unlocked ? null : () => _attemptUnlock(pack),
          );
        },
      ),
    );
  }

  Future<void> _attemptUnlock(ContentPack pack) async {
    final ok = await ServiceLocator.progression.tryUnlock(pack.packId);
    if (!mounted) return;
    setState(() {});
    final msg = ok
        ? 'Unlocked ${pack.displayName}!'
        : 'Need ${pack.unlockCost} coins (you have ${ServiceLocator.progression.profile.coins})';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

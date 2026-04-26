import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import 'widgets/big_button.dart';
import 'widgets/coin_badge.dart';
import 'widgets/floating_mascot.dart';
import '../core/constants.dart';

/// Hero image shown idling on the menu's dead space. Picked from the
/// launch pack's Legendary tier — splashy art that signals "rare
/// goodness lives here" the moment the app opens. Swapping to a
/// different card later is a one-line change.
const String _kMenuMascotAsset =
    'assets/cards/final_48/016_Celestial_Dumpling_Core.webp';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = ServiceLocator.packs.schedule.currentWeek(DateTime.now());
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SQUISHY\nSMASH',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                  CoinBadge(coins: ServiceLocator.progression.profile.coins),
                ],
              ),
              const SizedBox(height: 12),
              if (featured != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Palette.pink, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Palette.cream),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Featured: ${featured.promoLabel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Expanded(
                child: Center(
                  child: FloatingMascot(
                    assetPath: _kMenuMascotAsset,
                    width: 200,
                  ),
                ),
              ),
              BigButton(
                label: 'PLAY',
                color: Palette.pink,
                onTap: () => Navigator.pushNamed(context, AppRoutes.play),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'SHOP',
                color: Palette.cream,
                onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'COLLECTION',
                color: Palette.lavender,
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.collection),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'SETTINGS',
                color: Palette.jellyBlue,
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

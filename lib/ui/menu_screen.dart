import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import 'widgets/big_button.dart';
import 'widgets/coin_badge.dart';

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
                    border: Border.all(color: const Color(0xFFFF8FB8), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Color(0xFFFFD36E)),
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
              const Spacer(),
              BigButton(
                label: 'PLAY',
                color: const Color(0xFFFF8FB8),
                onTap: () => Navigator.pushNamed(context, AppRoutes.play),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'SHOP',
                color: const Color(0xFFFFD36E),
                onTap: () => Navigator.pushNamed(context, AppRoutes.shop),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'SETTINGS',
                color: const Color(0xFF7FE7FF),
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

import 'package:flutter/material.dart';

import '../core/routes.dart';
import '../core/service_locator.dart';
import 'gameplay_screen.dart';
import 'widgets/big_button.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as ResultsArgs?;
    final score = args?.score ?? 0;
    final combo = args?.combo ?? 0;
    final coins = args?.coinsEarned ?? 0;
    final best = ServiceLocator.progression.profile.bestScore;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'NICE MESS',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _StatRow(label: 'Score', value: '$score'),
              _StatRow(label: 'Best Combo', value: 'x$combo'),
              _StatRow(label: 'Coins Earned', value: '+$coins'),
              _StatRow(label: 'Best Score', value: '$best'),
              const Spacer(),
              BigButton(
                label: 'PLAY AGAIN',
                color: const Color(0xFFFF8FB8),
                onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.play),
              ),
              const SizedBox(height: 12),
              BigButton(
                label: 'MENU',
                color: const Color(0xFF7FE7FF),
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.menu,
                  (_) => false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18, color: Colors.white70)),
          Text(value, style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

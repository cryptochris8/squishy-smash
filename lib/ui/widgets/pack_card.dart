import 'package:flutter/material.dart';

import '../../data/models/content_pack.dart';

class PackCard extends StatelessWidget {
  const PackCard({
    super.key,
    required this.pack,
    required this.unlocked,
    required this.onUnlock,
  });

  final ContentPack pack;
  final bool unlocked;
  final VoidCallback? onUnlock;

  Color _hex(String s) {
    var h = s.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final primary = _hex(pack.palette.primary);
    final secondary = _hex(pack.palette.secondary);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(0.35), secondary.withOpacity(0.25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary, width: 1.4),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pack.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (unlocked)
                const Icon(Icons.check_circle, color: Color(0xFFB6FF5C))
              else
                Text(
                  '${pack.unlockCost} coins',
                  style: const TextStyle(
                    color: Color(0xFFFFD36E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: pack.objects
                .take(6)
                .map((o) => Chip(
                      label: Text(o.name),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ))
                .toList(),
          ),
          if (!unlocked && onUnlock != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('UNLOCK', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ],
      ),
    );
  }
}

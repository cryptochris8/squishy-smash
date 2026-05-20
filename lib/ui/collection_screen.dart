import 'package:flutter/material.dart';

import '../analytics/events.dart';
import '../core/routes.dart';
import '../core/service_locator.dart';
import '../data/achievement_registry.dart';
import '../data/card_unlock.dart';
import '../data/models/achievement.dart';
import '../data/models/card_entry.dart';
import '../data/models/rarity.dart';
import 'widgets/big_button.dart';
import 'widgets/card_album_widgets.dart';
import '../core/constants.dart';
import 'theme/app_theme.dart';

/// Card-album collection screen. Shows all 48 cards from the manifest
/// in a pack-grouped grid; locked cards render as silhouettes, unlocked
/// cards show their full WebP art. Tapping a card opens a detail
/// bottom-sheet with three progress paths (burst, achievement, coin
/// purchase). Custom family cards live in a clearly separate hidden
/// section at the bottom — never mixed into the 48-card progression.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  /// `null` means "all packs". Selecting a pack filters the grid down
  /// to that pack's 16 cards.
  CardPack? _packFilter;

  /// `null` means "all rarities".
  Rarity? _rarityFilter;

  @override
  Widget build(BuildContext context) {
    final cards = ServiceLocator.cards.cards;
    final custom = ServiceLocator.cards.custom;
    final profile = ServiceLocator.progression.profile;

    final unlockedFromAch = unlockedCardNumbersFromAchievements(
      achievements: starterAchievements,
      claimedIds: profile.claimedAchievements,
    );

    final economy = ServiceLocator.economy;
    int unlockedTotal = 0;
    for (final c in cards) {
      if (isCardUnlocked(
        card: c,
        cardBurstCounts: profile.cardBurstCounts,
        cardsPurchased: profile.cardsPurchased,
        unlockedFromAchievements: unlockedFromAch,
        grandfatheredCards: profile.grandfatheredCards,
        config: economy,
      )) {
        unlockedTotal++;
      }
    }

    final filtered = cards.where((c) {
      if (_packFilter != null && c.pack != _packFilter) return false;
      if (_rarityFilter != null && c.rarity != _rarityFilter) return false;
      return true;
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'COLLECTION',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _AlbumHeader(
            unlocked: unlockedTotal,
            total: cards.length,
          ),
          // GAME_POLISH_AUDIT.md UX-4: when the album is fully locked
          // (brand-new player tapped COLLECTION before playing) the
          // screen used to be a wall of 48 lock silhouettes with no
          // explanation. Now we render an empty-state banner with a
          // PLAY shortcut so the dead end becomes a funnel.
          if (unlockedTotal == 0) ...[
            const SizedBox(height: AppSpacing.lg),
            const _EmptyAlbumBanner(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _PackFilterRow(
            value: _packFilter,
            onChanged: (v) => setState(() => _packFilter = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _RarityFilterRow(
            value: _rarityFilter,
            onChanged: (v) => setState(() => _rarityFilter = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          // UX-7: cognitive-load relief on the filter row. The
          // "Showing X of Y" readout gives an at-a-glance status,
          // and a single Clear pill collapses two reset actions
          // (clear pack + clear rarity) into one tap when any filter
          // is active.
          _FilterStatusRow(
            shownCount: filtered.length,
            totalCount: cards.length,
            anyFilterActive:
                _packFilter != null || _rarityFilter != null,
            onClear: () => setState(() {
              _packFilter = null;
              _rarityFilter = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          if (filtered.isEmpty)
            const _EmptyState()
          else
            _CardGrid(
              cards: filtered,
              profile: profile,
              unlockedFromAch: unlockedFromAch,
              onTap: (card) =>
                  _showCardDetail(context, card, unlockedFromAch),
            ),
          if (custom.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxl),
            _CustomFamilySection(custom: custom),
          ],
        ],
      ),
    );
  }

  Future<void> _showCardDetail(
    BuildContext context,
    CardEntry card,
    Set<String> unlockedFromAch,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.bgSurface,
      isScrollControlled: true,
      builder: (_) => _CardDetailSheet(
        card: card,
        unlockedFromAch: unlockedFromAch,
      ),
    );
    // Re-render in case a purchase landed.
    if (mounted) setState(() {});
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: Palette.pink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$unlocked / $total CARDS',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Palette.toxicLime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// UX-7: filter-row status + clear action. Renders a quiet
/// "Showing X of Y" readout always; surfaces a brand-pink "Clear"
/// pill only when at least one filter is active so the affordance
/// only exists when it can do something.
class _FilterStatusRow extends StatelessWidget {
  const _FilterStatusRow({
    required this.shownCount,
    required this.totalCount,
    required this.anyFilterActive,
    required this.onClear,
  });

  final int shownCount;
  final int totalCount;
  final bool anyFilterActive;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Showing $shownCount of $totalCount',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const Spacer(),
        if (anyFilterActive)
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Palette.pink.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadii.full),
                border: Border.all(color: Palette.pink, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 12, color: Palette.pink),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'Clear filters',
                    style: TextStyle(
                      color: Palette.pink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PackFilterRow extends StatelessWidget {
  const _PackFilterRow({required this.value, required this.onChanged});

  final CardPack? value;
  final ValueChanged<CardPack?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterPill(
            label: 'ALL PACKS',
            selected: value == null,
            onTap: () => onChanged(null),
          ),
          for (final p in CardPack.values) ...[
            const SizedBox(width: AppSpacing.sm),
            FilterPill(
              label: p.displayLabel.toUpperCase(),
              selected: value == p,
              onTap: () => onChanged(p),
            ),
          ],
        ],
      ),
    );
  }
}

class _RarityFilterRow extends StatelessWidget {
  const _RarityFilterRow({required this.value, required this.onChanged});

  final Rarity? value;
  final ValueChanged<Rarity?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterPill(
            label: 'ALL RARITIES',
            selected: value == null,
            onTap: () => onChanged(null),
          ),
          for (final r in Rarity.values) ...[
            const SizedBox(width: AppSpacing.sm),
            FilterPill(
              label: r.displayLabel.toUpperCase(),
              selected: value == r,
              tint: cardRarityColor(r),
              onTap: () => onChanged(r),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.profile,
    required this.unlockedFromAch,
    required this.onTap,
  });

  final List<CardEntry> cards;
  final dynamic profile; // PlayerProfile — keep loose to avoid an import cycle
  final Set<String> unlockedFromAch;
  final ValueChanged<CardEntry> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final card = cards[i];
        final source = resolveCardUnlock(
          card: card,
          cardBurstCounts: profile.cardBurstCounts,
          cardsPurchased: profile.cardsPurchased,
          unlockedFromAchievements: unlockedFromAch,
          grandfatheredCards: profile.grandfatheredCards,
          config: ServiceLocator.economy,
        );
        return _CardTile(
          card: card,
          source: source,
          onTap: () => onTap(card),
        );
      },
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.source,
    required this.onTap,
  });

  final CardEntry card;
  final CardUnlockSource source;
  final VoidCallback onTap;

  bool get unlocked => source != CardUnlockSource.locked;

  @override
  Widget build(BuildContext context) {
    final rarityColor = cardRarityColor(card.rarity);
    final borderColor = unlocked
        ? rarityColor
        : Colors.white.withValues(alpha: 0.1);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.xs),
                // cacheWidth keeps each thumbnail decoded at ~grid
                // resolution rather than the source 1086x1448 RGBA.
                // 48 cards x ~6 MB decoded = ~290 MB resident on
                // iPhone — pre-fix this could OOM. Cap at 320 px
                // wide; the grid cell is ~110-180 px wide, so a 2x
                // upscale-buffer covers high-DPI without bloat.
                child: unlocked
                    ? Image.asset(
                        card.assetPath,
                        fit: BoxFit.cover,
                        cacheWidth: 320,
                        errorBuilder: (_, __, ___) =>
                            const _CardArtFallback(),
                      )
                    : const _LockedSilhouette(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              unlocked ? card.name : '???',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: unlocked
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
            Text(
              card.cardNumber,
              textAlign: TextAlign.center,
              // GAME_POLISH_AUDIT.md UI-1: previous treatment (9 sp,
              // alpha 0.5 on near-black bg) was ≈ 4.2:1 — under WCAG
              // 2.1 AA's 4.5:1 minimum for small text. Bumped to
              // 11 sp at white70 (≈ 9.4:1) so the info-dense card
              // grid stays legible for tired-parent eyes.
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedSilhouette extends StatelessWidget {
  const _LockedSilhouette();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Icon(
          Icons.lock_outline,
          size: 32,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }
}

class _CardArtFallback extends StatelessWidget {
  const _CardArtFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          Icons.bubble_chart,
          size: 32,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _CardDetailSheet extends StatefulWidget {
  const _CardDetailSheet({
    required this.card,
    required this.unlockedFromAch,
  });

  final CardEntry card;
  final Set<String> unlockedFromAch;

  @override
  State<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<_CardDetailSheet> {
  bool _purchaseInFlight = false;
  String? _purchaseError;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final profile = ServiceLocator.progression.profile;
    final economy = ServiceLocator.economy;
    final source = resolveCardUnlock(
      card: card,
      cardBurstCounts: profile.cardBurstCounts,
      cardsPurchased: profile.cardsPurchased,
      unlockedFromAchievements: widget.unlockedFromAch,
      grandfatheredCards: profile.grandfatheredCards,
      config: economy,
    );
    final unlocked = source != CardUnlockSource.locked;
    final bursts = profile.cardBurstCounts[card.cardNumber] ?? 0;
    final required =
        CardUnlockThresholds.requiredBursts(card.rarity, config: economy);
    final price = CardCoinPrice.coinsFor(card.rarity, config: economy);
    final canAffordPrice = profile.coins >= price;
    final rarityColor = cardRarityColor(card.rarity);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: card number + rarity pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  card.cardNumber,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                ),
                RarityPill(rarity: card.rarity),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Card art (or silhouette).
            AspectRatio(
              aspectRatio: 0.75,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                // cacheWidth caps the decoded resolution at ~2x of the
                // sheet's render width (~270 px on iPhone 11). Source
                // WebPs are 1086x1448 → ~18 MB RGBA per unique sheet
                // open; capping at 540 keeps it ~1.7 MB while leaving
                // headroom for high-DPI displays. Flutter's image cache
                // keys on (asset, cacheWidth), so this is sticky per
                // card without per-card tuning.
                child: unlocked
                    ? Image.asset(
                        card.assetPath,
                        fit: BoxFit.cover,
                        cacheWidth: 540,
                      )
                    : const _LockedSilhouette(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              unlocked ? card.name : '???',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              card.pack.displayLabel,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (unlocked)
              _UnlockedBadge(source: source, color: rarityColor)
            else ...[
              BurstProgressBar(bursts: bursts, required: required),
              const SizedBox(height: AppSpacing.md),
              _PurchaseButton(
                price: price,
                canAfford: canAffordPrice,
                inFlight: _purchaseInFlight,
                error: _purchaseError,
                onPressed: _purchaseInFlight ? null : _attemptPurchase,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _attemptPurchase() async {
    setState(() {
      _purchaseInFlight = true;
      _purchaseError = null;
    });
    final ok = await ServiceLocator.progression.tryPurchaseCardAtRarityPrice(
      widget.card,
    );
    if (ok) {
      GameEvents(ServiceLocator.analytics).spendVirtualCurrency(
        currencyName: 'coins',
        value: CardCoinPrice.coinsFor(
          widget.card.rarity,
          config: ServiceLocator.economy,
        ),
        itemName: widget.card.cardNumber,
      );
    }
    if (!mounted) return;
    setState(() {
      _purchaseInFlight = false;
      if (!ok) {
        _purchaseError = 'Not enough coins.';
      }
    });
  }
}

class _PurchaseButton extends StatelessWidget {
  const _PurchaseButton({
    required this.price,
    required this.canAfford,
    required this.inFlight,
    required this.error,
    required this.onPressed,
  });

  final int price;
  final bool canAfford;
  final bool inFlight;
  final String? error;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: canAfford ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.cream,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
          child: inFlight
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  canAfford
                      ? 'BUY FOR $price COINS'
                      : 'NEED $price COINS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: canAfford
                        ? Colors.black
                        : Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
        ),
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            error!,
            style: const TextStyle(
              fontSize: 12,
              color: Palette.pink,
            ),
          ),
        ],
      ],
    );
  }
}

class _UnlockedBadge extends StatelessWidget {
  const _UnlockedBadge({required this.source, required this.color});

  final CardUnlockSource source;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (source) {
      CardUnlockSource.burstThreshold => 'EARNED THROUGH PLAY',
      CardUnlockSource.purchased => 'UNLOCKED WITH COINS',
      CardUnlockSource.achievement => 'ACHIEVEMENT REWARD',
      CardUnlockSource.locked => 'LOCKED',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomFamilySection extends StatelessWidget {
  const _CustomFamilySection({required this.custom});

  final List<CustomCardEntry> custom;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEEPSAKES',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Palette.lavender,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Custom family cards. Not part of the 48-card set.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemCount: custom.length,
            itemBuilder: (_, i) {
              final c = custom[i];
              return ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.xs),
                child: Image.asset(
                  c.assetPath,
                  fit: BoxFit.cover,
                  // Same memory-cap reasoning as the main grid above.
                  cacheWidth: 320,
                  errorBuilder: (_, __, ___) => const _CardArtFallback(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Column(
        children: [
          Icon(
            Icons.filter_alt_off,
            size: 48,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No cards match those filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rendered above the card grid when the player hasn't unlocked any
/// cards yet — converts the wall-of-locks dead end into a funnel
/// straight to the gameplay route. GAME_POLISH_AUDIT.md UX-4.
class _EmptyAlbumBanner extends StatelessWidget {
  const _EmptyAlbumBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Palette.pink.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: Palette.pink.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tap PLAY to start smashing.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Cards unlock as you burst squishies. Three paths to '
            'every card — earn, achieve, or save.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          BigButton(
            label: 'PLAY',
            color: Palette.pink,
            onTap: () => Navigator.pushNamed(context, AppRoutes.play),
          ),
        ],
      ),
    );
  }
}


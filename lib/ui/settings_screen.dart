import 'package:flutter/material.dart';

import '../core/service_locator.dart';
import '../game/systems/arena_registry.dart';
import 'diagnostics_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _haptics = ServiceLocator.persistence.hapticsEnabled;
  late bool _muted = ServiceLocator.persistence.muted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Haptics'),
            value: _haptics,
            onChanged: (v) async {
              await ServiceLocator.persistence.setHapticsEnabled(v);
              setState(() => _haptics = v);
            },
          ),
          SwitchListTile(
            title: const Text('Mute Sound'),
            value: _muted,
            onChanged: (v) async {
              await ServiceLocator.persistence.setMuted(v);
              ServiceLocator.sounds.muted = v;
              setState(() => _muted = v);
            },
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Arena',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          _ArenaPicker(onSelected: () => setState(() {})),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined,
                color: Colors.white70),
            title: const Text('Diagnostics'),
            subtitle: Text(
              '${ServiceLocator.diagnostics.count} recent error'
              '${ServiceLocator.diagnostics.count == 1 ? '' : 's'} captured',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DiagnosticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Horizontally-scrolling row of all registered arenas. Tap an unlocked
/// one to make it the new active backdrop; locked ones show a hint to
/// buy in the shop.
class _ArenaPicker extends StatelessWidget {
  const _ArenaPicker({required this.onSelected});

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final progression = ServiceLocator.progression;
    final activeKey = progression.profile.activeArenaKey;
    final themes = ArenaRegistry.all.toList();

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: themes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final theme = themes[i];
          final unlocked = progression.isArenaUnlocked(theme.key);
          final isActive = unlocked && theme.key == activeKey;
          return _ArenaTile(
            theme: theme,
            unlocked: unlocked,
            isActive: isActive,
            onTap: () async {
              if (!unlocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Unlock ${theme.displayName} in the shop (${theme.cost} coins)',
                    ),
                  ),
                );
                return;
              }
              final ok = await progression.setActiveArena(theme.key);
              if (ok) onSelected();
            },
          );
        },
      ),
    );
  }
}

class _ArenaTile extends StatelessWidget {
  const _ArenaTile({
    required this.theme,
    required this.unlocked,
    required this.isActive,
    required this.onTap,
  });

  final ArenaTheme theme;
  final bool unlocked;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? const Color(0xFFFF8FB8)
        : Colors.white.withValues(alpha: 0.12);
    // Compose an assistive-tech-friendly label that includes the
    // arena name, ownership state, and active state. Without this,
    // VoiceOver reads only the visible text — which doesn't include
    // "locked" or "currently selected".
    final stateSuffix = !unlocked
        ? ', locked, tap to learn how to unlock'
        : isActive
            ? ', currently selected'
            : ', tap to select';
    return Semantics(
      button: true,
      enabled: true,
      selected: isActive,
      label: '${theme.displayName}$stateSuffix',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Container(
              width: 96,
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.calmColors,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: isActive ? 3 : 1.2,
                ),
              ),
              child: unlocked
                  ? null
                  : ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: const Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              theme.displayName,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: unlocked ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

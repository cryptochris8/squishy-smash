import 'package:flutter/material.dart';

import '../core/service_locator.dart';

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
        ],
      ),
    );
  }
}

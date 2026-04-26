import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/diagnostics.dart';
import '../core/service_locator.dart';
import '../core/constants.dart';

/// In-app log viewer for the global error buffer. Critical given the
/// no-Mac-access constraint — without Xcode, this is the only way to
/// see iOS crashes the app survived (or that happened during
/// bootstrap and silently degraded the UI).
///
/// The screen is intentionally plain and read-only. Each entry shows
/// timestamp, source, message, and stack trace. The "Copy" action
/// dumps the full buffer to the clipboard so a tester can paste it
/// into a bug report from a TestFlight device.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key, DiagnosticsService? service})
      : _injected = service;

  final DiagnosticsService? _injected;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  DiagnosticsService get _service =>
      widget._injected ?? ServiceLocator.diagnostics;

  @override
  Widget build(BuildContext context) {
    final entries = _service.entries.reversed.toList(); // newest first
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'DIAGNOSTICS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy buffer to clipboard',
            icon: const Icon(Icons.copy_all),
            onPressed: entries.isEmpty ? null : () => _copy(entries),
          ),
          IconButton(
            tooltip: 'Clear buffer',
            icon: const Icon(Icons.delete_sweep),
            onPressed: entries.isEmpty
                ? null
                : () {
                    _service.clear();
                    setState(() {});
                  },
          ),
        ],
      ),
      body: entries.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EntryTile(entry: entries[i]),
            ),
    );
  }

  Future<void> _copy(List<DiagnosticEntry> entries) async {
    final buf = StringBuffer();
    for (final e in entries) {
      buf
        ..writeln('[${e.timestamp.toIso8601String()}] ${e.source}')
        ..writeln(e.message);
      if (e.stack != null) {
        buf.writeln(e.stack);
      }
      buf.writeln();
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied diagnostics to clipboard')),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final DiagnosticEntry entry;

  Color get _sourceColor {
    switch (entry.source) {
      case 'flutter':
        return Palette.cream;
      case 'platform':
        return Palette.pink;
      case 'zone':
        return Palette.lavender;
      case 'bootstrap':
        return const Color(0xFFFF6B6B);
      default:
        return Palette.jellyBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _sourceColor.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _sourceColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.source.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _sourceColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.timestamp.toIso8601String(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.55),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
          if (entry.stack != null) ...[
            const SizedBox(height: 8),
            Text(
              entry.stack.toString(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.55),
                fontFamily: 'monospace',
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Palette.toxicLime.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            const Text(
              'No errors recorded.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The buffer captures the most recent 50 errors caught by '
              'Flutter, the platform dispatcher, the global zone, or '
              'bootstrap. An empty list means the app has been running '
              'cleanly since launch.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

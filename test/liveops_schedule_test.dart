import 'package:flutter_test/flutter_test.dart';
import 'package:squishy_smash/data/models/liveops_schedule.dart';

LiveOpsSchedule _schedule() => LiveOpsSchedule.fromJson(const {
      'featuredRotation': [
        {
          'weekOf': '2026-04-20',
          'featuredPack': 'launch_squishy_foods',
          'eventModifier': 'double_food_burst_coins',
          'promoLabel': 'Dumpling Squishy Week',
        },
        {
          'weekOf': '2026-04-27',
          'featuredPack': 'goo_fidgets_drop_01',
          'eventModifier': 'extra_goo_decals',
          'promoLabel': 'Maximum Goo Weekend',
        },
        {
          'weekOf': '2026-05-04',
          'featuredPack': 'creepy_cute_pack_01',
          'eventModifier': 'monster_combo_bonus',
          'promoLabel': 'Weird Cute Drop',
        },
      ],
    });

void main() {
  group('LiveOpsSchedule.fromJson', () {
    test('parses all three rotation entries', () {
      final s = _schedule();
      expect(s.featuredRotation, hasLength(3));
      expect(s.featuredRotation.first.featuredPack, 'launch_squishy_foods');
      expect(s.featuredRotation.last.promoLabel, 'Weird Cute Drop');
    });

    test('weekOf parses as a DateTime', () {
      final s = _schedule();
      expect(s.featuredRotation.first.weekOf, DateTime.parse('2026-04-20'));
    });
  });

  group('LiveOpsSchedule.currentWeek', () {
    test('returns null when now is before any scheduled week', () {
      final s = _schedule();
      expect(s.currentWeek(DateTime.parse('2026-04-01')), isNull);
    });

    test('returns exact-match week when now equals weekOf', () {
      final s = _schedule();
      final w = s.currentWeek(DateTime.parse('2026-04-27'));
      expect(w, isNotNull);
      expect(w!.featuredPack, 'goo_fidgets_drop_01');
    });

    test('returns the most recent past week mid-rotation', () {
      final s = _schedule();
      final w = s.currentWeek(DateTime.parse('2026-04-30'));
      expect(w, isNotNull);
      expect(w!.featuredPack, 'goo_fidgets_drop_01');
    });

    test('returns the last week when now is after all scheduled', () {
      final s = _schedule();
      final w = s.currentWeek(DateTime.parse('2027-01-01'));
      expect(w, isNotNull);
      expect(w!.featuredPack, 'creepy_cute_pack_01');
    });
  });
}

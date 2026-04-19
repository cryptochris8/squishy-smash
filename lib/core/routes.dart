import 'package:flutter/widgets.dart';

import '../ui/gameplay_screen.dart';
import '../ui/menu_screen.dart';
import '../ui/results_screen.dart';
import '../ui/settings_screen.dart';
import '../ui/shop_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String menu = '/';
  static const String play = '/play';
  static const String results = '/results';
  static const String shop = '/shop';
  static const String settings = '/settings';

  static final Map<String, WidgetBuilder> table = <String, WidgetBuilder>{
    menu: (_) => const MenuScreen(),
    play: (_) => const GameplayScreen(),
    results: (_) => const ResultsScreen(),
    shop: (_) => const ShopScreen(),
    settings: (_) => const SettingsScreen(),
  };
}

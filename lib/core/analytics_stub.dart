abstract class Analytics {
  void event(String name, [Map<String, Object?> params]);
}

class NoOpAnalytics implements Analytics {
  const NoOpAnalytics();

  @override
  void event(String name, [Map<String, Object?> params = const {}]) {}
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/fomo_summary.dart';

/// Immutable filter state shared by the home / tracker / explore feeds.
///
/// [showExpired] toggles whether dimmed expired lawsuits appear alongside the
/// always-visible active ones; [timeframe] drives the FOMO summary window.
class HomeFilter {
  const HomeFilter({
    this.showExpired = true,
    this.timeframe = FomoTimeframe.threeMonths,
  });

  final bool showExpired;
  final FomoTimeframe timeframe;

  HomeFilter copyWith({bool? showExpired, FomoTimeframe? timeframe}) {
    return HomeFilter(
      showExpired: showExpired ?? this.showExpired,
      timeframe: timeframe ?? this.timeframe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeFilter &&
          runtimeType == other.runtimeType &&
          showExpired == other.showExpired &&
          timeframe == other.timeframe;

  @override
  int get hashCode => Object.hash(showExpired, timeframe);
}

/// Holds the current [HomeFilter] and the methods that mutate it.
class HomeFilterNotifier extends Notifier<HomeFilter> {
  @override
  HomeFilter build() => const HomeFilter();

  /// Shows or hides expired lawsuits in the feed.
  void toggleShowExpired(bool value) {
    state = state.copyWith(showExpired: value);
  }

  /// Sets the FOMO summary timeframe.
  void setTimeframe(FomoTimeframe timeframe) {
    state = state.copyWith(timeframe: timeframe);
  }
}

/// The current home feed filter.
final homeFilterProvider = NotifierProvider<HomeFilterNotifier, HomeFilter>(
  HomeFilterNotifier.new,
);

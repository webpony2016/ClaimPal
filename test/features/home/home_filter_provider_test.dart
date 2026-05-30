import 'package:claimpal/data/models/fomo_summary.dart';
import 'package:claimpal/features/home/home_filter_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  HomeFilter read() => container.read(homeFilterProvider);
  HomeFilterNotifier notifier() => container.read(homeFilterProvider.notifier);

  test('default is showExpired false / threeMonths', () {
    final state = read();
    expect(state.showExpired, isFalse);
    expect(state.timeframe, FomoTimeframe.threeMonths);
  });

  test('toggleShowExpired(true) updates state', () {
    notifier().toggleShowExpired(true);
    expect(read().showExpired, isTrue);
    expect(read().timeframe, FomoTimeframe.threeMonths);
  });

  test('setTimeframe(sixMonths) updates state', () {
    notifier().setTimeframe(FomoTimeframe.sixMonths);
    expect(read().timeframe, FomoTimeframe.sixMonths);
    expect(read().showExpired, isFalse);
  });
}

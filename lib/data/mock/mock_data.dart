import '../models/fomo_summary.dart';
import '../models/lawsuit.dart';

/// When true, mock futures/streams emit an error instead of data. Used later
/// for building and testing error states. Keep `false` for normal operation.
const bool kMockSimulateFailure = false;

/// Simulated network latency applied to mock futures.
const Duration kMockLatency = Duration(milliseconds: 300);

/// Active (claimable) lawsuits seeded from real Stitch copy plus plausible
/// invented entries.
///
/// `final` (not `const`) because each entry carries a [DateTime] deadline, which
/// has no const constructor.
final List<Lawsuit> kMockActiveLawsuits = [
  Lawsuit(
    id: 'facebook-data-privacy',
    title: 'Facebook Data Privacy Settlement',
    brand: 'Facebook',
    category: LawsuitCategory.privacy,
    status: LawsuitStatus.active,
    payoutLabel: 'Up to',
    payoutValue: '\$350',
    deadline: DateTime(2026, 8, 15),
    expiredDaysAgo: null,
    eligibility:
        'You had an active Facebook account in the United States between 2007 and 2022.',
    requiredProof: [
      'Facebook account email or username',
      'Approximate years the account was active',
    ],
  ),
  Lawsuit(
    id: 'fitbit-heart-rate',
    title: 'Fitbit Heart Rate Accuracy',
    brand: 'Fitbit',
    category: LawsuitCategory.health,
    status: LawsuitStatus.active,
    payoutLabel: 'Up to',
    payoutValue: '\$150',
    deadline: DateTime(2026, 7, 20),
    expiredDaysAgo: null,
    eligibility:
        'You purchased a Fitbit device with heart-rate tracking and used it for fitness activities.',
    requiredProof: [
      'Proof of Fitbit device purchase',
      'Device model name',
      'Approximate purchase date',
    ],
  ),
  Lawsuit(
    id: 'tmobile-data-breach',
    title: 'T-Mobile Data Breach Settlement',
    brand: 'T-Mobile',
    category: LawsuitCategory.security,
    status: LawsuitStatus.active,
    payoutLabel: 'Up to',
    payoutValue: '\$250',
    deadline: DateTime(2026, 6, 30),
    expiredDaysAgo: null,
    eligibility:
        'You were a T-Mobile customer whose personal information was exposed in the 2021 data breach.',
    requiredProof: [
      'T-Mobile account phone number',
      'Breach notification letter (if received)',
    ],
  ),
  Lawsuit(
    id: 'google-plus-privacy',
    title: 'Google Plus Privacy Settlement',
    brand: 'Google',
    category: LawsuitCategory.privacy,
    status: LawsuitStatus.active,
    payoutLabel: 'Up to',
    payoutValue: '\$12',
    deadline: DateTime(2026, 9, 10),
    expiredDaysAgo: null,
    eligibility:
        'You had a consumer Google+ account between January 2015 and April 2019.',
    requiredProof: [
      'Google account email',
      'Approximate years the Google+ account was active',
    ],
  ),
  Lawsuit(
    id: 'apple-appstore',
    title: 'Apple App Store Pricing Settlement',
    brand: 'Apple',
    category: LawsuitCategory.finance,
    status: LawsuitStatus.active,
    payoutLabel: 'Up to',
    payoutValue: '\$30',
    deadline: DateTime(2026, 12, 1),
    expiredDaysAgo: null,
    eligibility:
        'You purchased apps or in-app content from the App Store as a US consumer.',
    requiredProof: [
      'Apple ID email',
      'Approximate total App Store spending',
    ],
  ),
  Lawsuit(
    id: 'plaid-data-sharing',
    title: 'Plaid Financial Data Sharing Settlement',
    brand: 'Plaid',
    category: LawsuitCategory.finance,
    status: LawsuitStatus.active,
    payoutLabel: 'Up to',
    payoutValue: '\$40',
    deadline: DateTime(2026, 10, 5),
    expiredDaysAgo: null,
    eligibility:
        'You connected a financial account through an app that used Plaid between 2013 and 2021.',
    requiredProof: [
      'Email used with the connected app',
      'Name of the app that used Plaid',
    ],
  ),
];

/// Expired (closed) lawsuits.
///
/// `final` (not `const`) because each entry carries a [DateTime] deadline.
final List<Lawsuit> kMockExpiredLawsuits = [
  Lawsuit(
    id: 'capital-one-breach',
    title: 'Capital One Data Breach',
    brand: 'Capital One',
    category: LawsuitCategory.finance,
    status: LawsuitStatus.expired,
    payoutLabel: 'Fixed',
    payoutValue: '\$25.00',
    deadline: DateTime(2026, 5, 19),
    expiredDaysAgo: 12,
    eligibility:
        'You were a Capital One customer affected by the 2019 data breach.',
    requiredProof: [
      'Capital One account number or email',
      'Breach notification letter',
    ],
  ),
  Lawsuit(
    id: 'equifax-data-settlement',
    title: 'Equifax Data Settlement',
    brand: 'Equifax',
    category: LawsuitCategory.security,
    status: LawsuitStatus.expired,
    payoutLabel: 'Up to',
    payoutValue: '\$125',
    deadline: DateTime(2026, 4, 16),
    expiredDaysAgo: 45,
    eligibility:
        'Your information was exposed in the 2017 Equifax data breach.',
    requiredProof: [
      'Full name as it appeared on credit reports',
      'Confirmation of impact from Equifax',
    ],
  ),
  Lawsuit(
    id: 'yahoo-data-breach',
    title: 'Yahoo Data Breach Settlement',
    brand: 'Yahoo',
    category: LawsuitCategory.security,
    status: LawsuitStatus.expired,
    payoutLabel: 'Up to',
    payoutValue: '\$100',
    deadline: DateTime(2026, 3, 2),
    expiredDaysAgo: 90,
    eligibility:
        'You had a Yahoo account between 2012 and 2016 when the breaches occurred.',
    requiredProof: [
      'Yahoo account email',
      'Approximate years the account was active',
    ],
  ),
];

/// FOMO summary for the home banner: missed and upcoming payouts.
const FomoSummary kMockFomoSummary = FomoSummary(
  missedAmount: 450,
  upcomingAmount: 1200,
  timeframe: FomoTimeframe.threeMonths,
);

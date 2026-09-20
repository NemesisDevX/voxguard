/// Subscription billing period selected on the paywall.
enum BillingCycle {
  monthly,
  annual;

  String get label => switch (this) {
        BillingCycle.monthly => 'Monthly',
        BillingCycle.annual => 'Annual',
      };

  /// Short suffix rendered next to a price ("$9.99/mo").
  String get priceSuffix => switch (this) {
        BillingCycle.monthly => '/mo',
        BillingCycle.annual => '/yr',
      };
}

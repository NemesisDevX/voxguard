import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/legal_links.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/models/entitlement_state.dart';
import '../../domain/models/subscription_tier.dart';
import '../bloc/paywall_bloc.dart';
import '../bloc/paywall_event.dart';
import '../bloc/paywall_state.dart';

/// Subscription paywall.
///
/// Push with `PaywallScreen.show(context, preselect: tierId)`; on a
/// verified entitlement the route pops itself after showing a
/// confirmation snackbar. Three truthful modes:
/// - real store: localized prices from the current offering;
/// - demo store: visibly simulated, "no real charge";
/// - unavailable: free plan only, no fake checkout.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, this.preselect});

  /// Tier to highlight on open (e.g. Sentinel from the Live Mic
  /// upsell, Family Vault from the Family Shield gate).
  final TierId? preselect;

  static void show(BuildContext context, {TierId? preselect}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaywallScreen(preselect: preselect),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          PaywallBloc()..add(LoadOfferingsEvent(preselect: preselect)),
      child: const _PaywallView(),
    );
  }
}

class _PaywallView extends StatelessWidget {
  const _PaywallView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaywallBloc, PaywallState>(
      listenWhen: (_, s) => s is PaywallPurchaseSuccess,
      listener: (context, state) {
        final success = state as PaywallPurchaseSuccess;
        final name = SubscriptionTiers.byId(success.tier)?.name ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success.demo
                  ? AppStrings.demoPlanActivated
                  : '$name activated — shield upgraded',
            ),
          ),
        );
        Navigator.of(context).maybePop();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bgBase,
          body: SafeArea(
            child: switch (state) {
              PaywallLoading() => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                  ),
                ),
              PaywallError() => _ErrorView(message: state.errorMessage),
              _ => _PaywallContent(state: state),
            },
          ),
        );
      },
    );
  }
}

// ── Loaded content ───────────────────────────────────────────────────

class _PaywallContent extends StatelessWidget {
  const _PaywallContent({required this.state});

  final PaywallState state;

  @override
  Widget build(BuildContext context) {
    final loaded = state is PaywallLoaded ? state as PaywallLoaded : null;
    if (loaded == null) return const SizedBox.shrink();
    final bloc = context.read<PaywallBloc>();
    final isDemo = loaded.backend == PurchaseBackendMode.demoStore;
    final isUnavailable =
        loaded.backend == PurchaseBackendMode.unavailable;

    return Column(
      children: [
        // ── Header: dismiss + billing truth badge ──
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              if (isDemo)
                const _DemoBadge()
              else if (!isUnavailable) ...[
                // No billing happens on the unavailable backend —
                // so the badge stays honest by staying absent.
                const Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: AppColors.statusSafe,
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    AppStrings.securityBadge,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              const Text(
                AppStrings.paywallTitle,
                style: AppTypography.displaySmall,
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.paywallSubtitle,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (isDemo) const _DemoNotice(),
              if (isUnavailable) const _UnavailableNotice(),
              if (loaded.notice != null && !isUnavailable)
                _InlineNotice(message: loaded.notice!),
              const SizedBox(height: 8),
              if (loaded.availableCycles.length > 1) ...[
                _BillingToggle(
                  cycle: loaded.cycle,
                  availableCycles: loaded.availableCycles,
                  onSelect: (c) => bloc.add(SelectBillingCycleEvent(c)),
                ),
                const SizedBox(height: 16),
              ],
              for (final tier in loaded.tiers) ...[
                _TierCard(
                  tier: tier,
                  package: loaded.selectedTier == tier
                      ? loaded.selectedPackage
                      : null,
                  priceLabel: _priceLabel(loaded, tier),
                  cycle: loaded.cycle,
                  selected: tier == loaded.selectedTier,
                  onTap: loaded.isPurchasing
                      ? null
                      : () => bloc.add(SelectTierEvent(tier)),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        _CtaBar(loaded: loaded),
      ],
    );
  }

  /// Price for the tier's offered cycle — the localized string the
  /// store returned, or 'Free' for the zero-price plan. Missing
  /// packages render as 'Not available' (card is hidden anyway).
  static String _priceLabel(PaywallLoaded loaded, SubscriptionTier t) {
    if (t.isFree) return 'Free';
    final offers = loaded.packages[t.tierId];
    if (offers == null || offers.isEmpty) return '—';
    final pkg = offers[loaded.cycle] ?? offers.values.first;
    return '${pkg.priceString}${pkg.cycle.priceSuffix}';
  }
}

// ── Truthfulness badges ──────────────────────────────────────────────

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.statusWarning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.statusWarning.withValues(alpha: 0.5),
        ),
      ),
      child: const Text(
        AppStrings.demoStoreBadge,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.statusWarning,
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return _NoticeShell(
      icon: Icons.science_outlined,
      color: AppColors.statusWarning,
      child: const Text(
        AppStrings.demoStoreNotice,
        style: AppTypography.bodyMedium,
      ),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice();

  @override
  Widget build(BuildContext context) {
    return const _NoticeShell(
      icon: Icons.info_outline,
      color: AppColors.textMuted,
      child: Text(
        AppStrings.storeUnavailableNotice,
        style: AppTypography.bodyMedium,
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _NoticeShell(
      icon: Icons.info_outline,
      color: AppColors.accent,
      child: Text(message, style: AppTypography.bodyMedium),
    );
  }
}

class _NoticeShell extends StatelessWidget {
  const _NoticeShell({
    required this.icon,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Billing cycle pill toggle ────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.cycle,
    required this.availableCycles,
    required this.onSelect,
  });

  final BillingCycle cycle;
  final List<BillingCycle> availableCycles;
  final ValueChanged<BillingCycle> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          for (final c in BillingCycle.values)
            _pill(c, c.label, enabled: availableCycles.contains(c)),
        ],
      ),
    );
  }

  Widget _pill(BillingCycle c, String label, {required bool enabled}) {
    final active = cycle == c;
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => onSelect(c) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.bgElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border:
                active ? Border.all(color: AppColors.borderSubtle) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: !enabled
                    ? AppColors.textMuted.withValues(alpha: 0.4)
                    : active
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tier card ────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.package,
    required this.priceLabel,
    required this.cycle,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionTier tier;

  /// The store package this card would buy — null for Free.
  final StorePackage? package;

  /// Precomputed localized price label ('Free' for the zero tier).
  final String priceLabel;
  final BillingCycle cycle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = selected || tier.isPopular;
    final borderColor = selected
        ? AppColors.accent
        : tier.isPopular
            ? AppColors.accentMuted
            : AppColors.borderSubtle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? AppColors.bgElevated : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tier.name,
                              style: AppTypography.titleMedium,
                            ),
                          ),
                          if (tier.isPopular) ...[
                            const SizedBox(width: 8),
                            const _PopularChip(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(tier.subtitle, style: AppTypography.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    priceLabel,
                    key: ValueKey('${tier.tierId}-${cycle.name}'),
                    style: AppTypography.statLarge.copyWith(
                      fontSize: 18,
                      color: selected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final f in tier.features)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 15,
                      color: AppColors.statusSafe,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PopularChip extends StatelessWidget {
  const _PopularChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: const Text(
        AppStrings.mostPopular,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

// ── CTA + footer ─────────────────────────────────────────────────────

class _CtaBar extends StatelessWidget {
  const _CtaBar({required this.loaded});

  final PaywallLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PaywallBloc>();
    final tier = loaded.selectedTier;
    final isDemo = loaded.backend == PurchaseBackendMode.demoStore;
    final isUnavailable =
        loaded.backend == PurchaseBackendMode.unavailable;

    final String ctaLabel;
    if (tier.isFree || isUnavailable) {
      ctaLabel = AppStrings.continueFree;
    } else if (isDemo) {
      ctaLabel = AppStrings.activateDemoPlan;
    } else {
      ctaLabel = AppStrings.subscribeNow;
    }

    // "Continue Free" just closes — it is never a store transaction.
    final VoidCallback? onCta = loaded.isPurchasing
        ? null
        : tier.isFree || isUnavailable
            ? () => Navigator.of(context).maybePop()
            : () => bloc.add(const PurchaseSelectedEvent());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onCta,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor:
                    AppColors.accent.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: loaded.isPurchasing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      ctaLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          _FooterRow(loaded: loaded),
        ],
      ),
    );
  }
}

class _FooterRow extends StatelessWidget {
  const _FooterRow({required this.loaded});

  final PaywallLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PaywallBloc>();
    final terms = LegalLinks.terms;
    final privacy = LegalLinks.privacyPolicy;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Legal links render ONLY when a valid https URL is configured —
        // never dead buttons.
        if (terms != null) _footerLink(AppStrings.terms, terms),
        if (privacy != null) _footerLink(AppStrings.privacy, privacy),
        // Restore only where a store exists to restore from.
        if (loaded.backend != PurchaseBackendMode.unavailable)
          TextButton(
            onPressed: loaded.isPurchasing
                ? null
                : () => bloc.add(const RestorePurchasesEvent()),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              AppStrings.restore,
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _footerLink(String label, Uri url) {
    return TextButton(
      onPressed: () =>
          launchUrl(url, mode: LaunchMode.externalApplication),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

// ── Error view ───────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.statusDanger,
            ),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context
                  .read<PaywallBloc>()
                  .add(const LoadOfferingsEvent()),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

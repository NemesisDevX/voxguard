import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/legal_links.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/models/entitlement_state.dart';
import '../../domain/models/subscription_tier.dart';
import '../bloc/paywall_bloc.dart';
import '../bloc/paywall_event.dart';
import '../bloc/paywall_state.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';

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
    final p = context.palette;
    return BlocConsumer<PaywallBloc, PaywallState>(
      listenWhen: (_, s) => s is PaywallPurchaseSuccess,
      listener: (context, state) {
        final success = state as PaywallPurchaseSuccess;
        final name = SubscriptionTiers.byId(success.tier)?.name ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success.demo
                  ? l10n.demoPlanActivated
                  : l10n.planActivated(name),
            ),
          ),
        );
        Navigator.of(context).maybePop();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: p.bgBase,
          body: SafeArea(
            child: switch (state) {
              PaywallLoading() => Center(
                  child: CircularProgressIndicator(
                    color: p.accent,
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
    final p = context.palette;
    final l10n = context.l10n;
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
                    Icon(Icons.close, color: p.textMuted),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              if (isDemo)
                const _DemoBadge()
              else if (!isUnavailable) ...[
                // No billing happens on the unavailable backend —
                // so the badge stays honest by staying absent.
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: p.statusSafe,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.securityBadge,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textMuted,
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
              Text(
                l10n.paywallTitle,
                style: AppTypography.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.paywallSubtitle,
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
                  priceLabel: _priceLabel(l10n, loaded, tier),
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
  /// store returned, or the localized Free label for the zero-price
  /// plan. Missing packages render as '—' (card is hidden anyway).
  static String _priceLabel(
      AppLocalizations l10n, PaywallLoaded loaded, SubscriptionTier t) {
    if (t.isFree) return l10n.planFreeLabel;
    final offers = loaded.packages[t.tierId];
    if (offers == null || offers.isEmpty) return '—';
    final pkg = offers[loaded.cycle] ?? offers.values.first;
    final suffix = switch (pkg.cycle) {
      BillingCycle.monthly => l10n.priceSuffixMonthly,
      BillingCycle.annual => l10n.priceSuffixAnnual,
    };
    return '${pkg.priceString}$suffix';
  }
}

// ── Truthfulness badges ──────────────────────────────────────────────

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.statusWarning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: p.statusWarning.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        l10n.demoStoreBadge,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: p.statusWarning,
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _NoticeShell(
      icon: Icons.science_outlined,
      color: p.statusWarning,
      child: Text(
        l10n.demoStoreNotice,
        style: AppTypography.bodyMedium,
      ),
    );
  }
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _NoticeShell(
      icon: Icons.info_outline,
      color: p.textMuted,
      child: Text(
        l10n.storeUnavailableNotice,
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
    final p = context.palette;
    return _NoticeShell(
      icon: Icons.info_outline,
      color: p.accent,
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

  /// Localized cycle label at the presentation boundary — the enum's
  /// `label` stays a stable domain value.
  String _cycleLabel(BuildContext context, BillingCycle c) =>
      switch (c) {
        BillingCycle.monthly => context.l10n.billingMonthly,
        BillingCycle.annual => context.l10n.billingAnnual,
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.borderSubtle),
      ),
      child: Row(
        children: [
          for (final c in BillingCycle.values)
            _pill(c, _cycleLabel(context, c),
                enabled: availableCycles.contains(c), p: p),
        ],
      ),
    );
  }

  Widget _pill(BillingCycle c, String label, {required bool enabled, required AppPalette p}) {
    final active = cycle == c;
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? () => onSelect(c) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? p.bgElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border:
                active ? Border.all(color: p.borderSubtle) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                color: !enabled
                    ? p.textMuted.withValues(alpha: 0.4)
                    : active
                        ? p.textPrimary
                        : p.textMuted,
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

  /// Catalog copy is localized at the presentation layer — the
  /// domain `SubscriptionTier` strings stay frozen English; an
  /// unrecognized tier falls back to its domain text.
  String _tierName(AppLocalizations l10n) => switch (tier.tierId) {
        TierId.free => l10n.tierQuickCheck,
        TierId.sentinel => l10n.tierSentinel,
        TierId.familyVault => l10n.tierFamily,
      };

  String _tierSubtitle(AppLocalizations l10n) => switch (tier.tierId) {
        TierId.free => l10n.tierQuickCheckTag,
        TierId.sentinel => l10n.tierSentinelTag,
        TierId.familyVault => l10n.tierFamilyTag,
      };

  List<String> _tierFeatures(AppLocalizations l10n) =>
      switch (tier.tierId) {
        TierId.free => [
            l10n.tierQuickCheckF1,
            l10n.tierQuickCheckF2,
            l10n.tierQuickCheckF3,
            l10n.tierQuickCheckF4,
            l10n.tierQuickCheckF5,
          ],
        TierId.sentinel => [
            l10n.tierSentinelF1,
            l10n.tierSentinelF2,
            l10n.tierSentinelF3,
            l10n.tierSentinelF4,
          ],
        TierId.familyVault => [
            l10n.tierFamilyF1,
            l10n.tierFamilyF2,
            l10n.tierFamilyF3,
            l10n.tierFamilyF4,
          ],
      };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = context.l10n;
    final highlight = selected || tier.isPopular;
    final borderColor = selected
        ? p.accent
        : tier.isPopular
            ? p.accentMuted
            : p.borderSubtle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: highlight ? p.bgElevated : p.surfaceCard,
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
                              _tierName(l10n),
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
                      Text(_tierSubtitle(l10n),
                          style: AppTypography.bodyMedium),
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
                          ? p.accent
                          : p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final f in _tierFeatures(l10n))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 15,
                      color: p.statusSafe,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTypography.bodyMedium.copyWith(
                          color: p.textPrimary,
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
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: p.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        l10n.mostPopular,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: p.accent,
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
    final p = context.palette;
    final bloc = context.read<PaywallBloc>();
    final tier = loaded.selectedTier;
    final isDemo = loaded.backend == PurchaseBackendMode.demoStore;
    final isUnavailable =
        loaded.backend == PurchaseBackendMode.unavailable;

    final String ctaLabel;
    if (tier.isFree || isUnavailable) {
      ctaLabel = l10n.continueFree;
    } else if (isDemo) {
      ctaLabel = l10n.activateDemoPlan;
    } else {
      ctaLabel = l10n.subscribeNow;
    }

    // "Continue Free" just closes — it is never a store transaction.
    final VoidCallback? onCta = loaded.isPurchasing
        ? null
        : tier.isFree || isUnavailable
            ? () => Navigator.of(context).maybePop()
            : () => bloc.add(const PurchaseSelectedEvent());

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border(top: BorderSide(color: p.borderSubtle)),
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
                backgroundColor: p.accent,
                disabledBackgroundColor:
                    p.accent.withValues(alpha: 0.45),
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
    final p = context.palette;
    final bloc = context.read<PaywallBloc>();
    final terms = LegalLinks.terms;
    final privacy = LegalLinks.privacyPolicy;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        // Legal links render ONLY when a valid https URL resolves —
        // never dead buttons.
        if (terms != null) _footerLink(l10n.terms, terms, p),
        if (privacy != null) _footerLink(l10n.privacy, privacy, p),
        // Restore only where a store exists to restore from.
        if (loaded.backend != PurchaseBackendMode.unavailable)
          TextButton(
            onPressed: loaded.isPurchasing
                ? null
                : () => bloc.add(const RestorePurchasesEvent()),
            style: TextButton.styleFrom(
              foregroundColor: p.textMuted,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.restore,
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _footerLink(String label, Uri url, AppPalette p) {
    return TextButton(
      onPressed: () =>
          launchUrl(url, mode: LaunchMode.externalApplication),
      style: TextButton.styleFrom(
        foregroundColor: p.textMuted,
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
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: p.statusDanger,
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
              child: Text(l10n.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}

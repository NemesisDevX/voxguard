import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/billing_cycle.dart';
import '../../domain/models/subscription_tier.dart';
import '../bloc/paywall_bloc.dart';
import '../bloc/paywall_event.dart';
import '../bloc/paywall_state.dart';

/// High-conversion subscription modal.
///
/// Push with `Navigator.push`; on success the route pops itself after
/// showing a confirmation snackbar.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaywallBloc()..add(const LoadOfferingsEvent()),
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
        final tier =
            (state as PaywallPurchaseSuccess).purchasedTier;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tier.isFree
                  ? 'Free plan active'
                  : '${tier.name} activated — shield upgraded',
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

  PaywallLoaded? get _loaded =>
      state is PaywallLoaded ? state as PaywallLoaded : null;

  @override
  Widget build(BuildContext context) {
    final loaded = _loaded;
    if (loaded == null) return const SizedBox.shrink();
    final bloc = context.read<PaywallBloc>();

    return Column(
      children: [
        // ── Header: dismiss + security badge ──
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              const Icon(
                Icons.lock_outline,
                size: 13,
                color: AppColors.statusSafe,
              ),
              const SizedBox(width: 6),
              const Text(
                AppStrings.securityBadge,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
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
              const SizedBox(height: 20),
              _BillingToggle(
                cycle: loaded.cycle,
                onSelect: (c) =>
                    bloc.add(SelectBillingCycleEvent(c)),
              ),
              const SizedBox(height: 16),
              for (final tier in loaded.tiers) ...[
                _TierCard(
                  tier: tier,
                  cycle: loaded.cycle,
                  selected: tier == loaded.selectedTier,
                  onTap: loaded.isPurchasing
                      ? null
                      : () => bloc.add(SelectTierEvent(tier)),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              const _TrialBanner(),
            ],
          ),
        ),
        _CtaBar(loaded: loaded),
      ],
    );
  }
}

// ── Billing cycle pill toggle ────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.cycle, required this.onSelect});

  final BillingCycle cycle;
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
          _pill(BillingCycle.monthly, AppStrings.monthly),
          _pill(BillingCycle.annual, AppStrings.annual,
              badge: AppStrings.saveBadge),
        ],
      ),
    );
  }

  Widget _pill(BillingCycle c, String label, {String? badge}) {
    final active = cycle == c;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.bgElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active
                ? Border.all(color: AppColors.borderSubtle)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: active
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusSafe.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.statusSafe,
                    ),
                  ),
                ),
              ],
            ],
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
    required this.cycle,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionTier tier;
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
          color: highlight
              ? AppColors.bgElevated
              : AppColors.surfaceCard,
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
                    tier.priceLabel(cycle),
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

// ── Trial guarantee banner ───────────────────────────────────────────

class _TrialBanner extends StatelessWidget {
  const _TrialBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.statusSafe.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusSafe.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: AppColors.statusSafe,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppStrings.trialBanner,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
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
              onPressed: loaded.isPurchasing
                  ? null
                  : () => bloc.add(
                        PurchaseTierEvent(tier, loaded.cycle),
                      ),
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
                      tier.isFree
                          ? AppStrings.continueFree
                          : AppStrings.startTrial,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _footerLink(AppStrings.terms),
              _footerLink(AppStrings.privacy),
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
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String label) {
    return TextButton(
      onPressed: () {},
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
            Text(message, textAlign: TextAlign.center,
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

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/models/payment_method.dart';
import 'package:uzme/core/services/payment_config_service.dart';

/// Adresse, stats (note/distance), services et politique d'annulation.
class StudioDetailInfo extends StatelessWidget {
  final DiscoveredStudio studio;
  final PaymentConfigService? paymentConfigService;

  const StudioDetailInfo({super.key, required this.studio, this.paymentConfigService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (studio.address != null) _buildAddress(theme),
        _buildStats(theme),
        if (studio.services.isNotEmpty) _buildServices(theme),
        if (studio.isPartner)
          _CancellationPolicySection(
            studioId: studio.id,
            paymentConfigService: paymentConfigService,
          ),
      ],
    );
  }

  Widget _buildAddress(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          FaIcon(FontAwesomeIcons.locationDot, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              studio.address!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (studio.rating != null) ...[
            _statChip(
              theme,
              icon: FontAwesomeIcons.solidStar,
              iconColor: Colors.amber,
              value: studio.rating!.toStringAsFixed(1),
              label: '(${studio.reviewCount ?? 0})',
            ),
            const SizedBox(width: 12),
          ],
          _statChip(
            theme,
            icon: FontAwesomeIcons.locationArrow,
            iconColor: theme.colorScheme.primary,
            value: studio.formattedDistance,
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _statChip(
    ThemeData theme, {
    required FaIconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ],
        ],
      ),
    );
  }

  Widget _buildServices(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: studio.services.take(5).map((service) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              service,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

}

/// Isolé en State pour que le `Future` ne soit créé qu'une fois (et pas à
/// chaque reconstruction du parent) — sinon chaque setState au-dessus
/// relance l'appel réseau et fait clignoter la ligne.
class _CancellationPolicySection extends StatefulWidget {
  final String studioId;
  final PaymentConfigService? paymentConfigService;

  const _CancellationPolicySection({required this.studioId, this.paymentConfigService});

  @override
  State<_CancellationPolicySection> createState() =>
      _CancellationPolicySectionState();
}

class _CancellationPolicySectionState extends State<_CancellationPolicySection> {
  late final Future<StudioPaymentConfig> _future =
      (widget.paymentConfigService ?? PaymentConfigService())
          .getPaymentConfig(widget.studioId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<StudioPaymentConfig>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final policy = snapshot.data!.cancellationPolicy;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              FaIcon(FontAwesomeIcons.scaleBalanced, size: 12, color: theme.colorScheme.outline),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${policy.label} — ${policy.description}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
